+++
title = "k8s client-go 系列(1): DeltaFIFO"
date = 2024-01-14T01:32:16+08:00
draft = false
tags= ["k8s","operator","开发","informer","client-go"] 
categories= ["k8s-operator开发"]
+++
## 写在前面
刚毕业我就觉得crud是一件很无聊的事情。作为sre可以摆脱crdu, 可是平时的工作无非是监控，告警，迁移，部署，排查问题。三年了，这些东西都搞腻味了，从技术品味上说，什么是有趣的？我感觉k8s开发算是少有的有点技术含量，且可以玩的深一点的东西了。通过operator的开发我们可以将部署从playbook，手工部署解放出来。其中积累的能力在自动化告警处理，运维操作自动化上更是大有可为。个人感觉是未来的大势所趋。  

我已经完全独立开发一个zookeeper operator系统，参与和研究过至少三个类似系统的开发。但是对于operator机制，我总是有种模模糊糊的感觉，网上的资料都被我翻遍了，要不太理论看不懂，要不太小白就一个入门。更有的是直接上源码，属于大牛懒得看，我这种菜鸡看了也白看的类型。基于此，我想还是要demo先行，通过构建demo慢慢攻破一个个小堡垒, 不能好高骛远。

## 简介
![20240114015320](https://cdn.jsdelivr.net/gh/liuzehao/PictureManager/lib/20240114015320.png)  
[client-go 架构图](https://github.com/kubernetes/sample-controller/blob/master/docs/controller-client-go.md)

github client-go项目:  
https://github.com/kubernetes/client-go

DeltaFIFO架构上在Reflector和informer之间的位置，和所有队列一样，作用的官方说法:
>
DeltaFIFO solves this use case:
  - You want to process every object change (delta) at most once.  
  您希望至多处理每个对象变更（delta）一次。
  - When you process an object, you want to see everything, that's happened to it since you last processed it.  
  在处理对象时，您希望看到自上次处理以来发生的一切。
  - You want to process the deletion of some of the objects.  
   您希望处理一些对象的删除。
  - You might want to periodically reprocess objects.  
  您可能希望定期重新处理对象。

顾名思义的来看可以分为FIFO部分和Delta部分：
- 1、FIFO：先入先出队列，拥有队列基本方法(ADD，UPDATE, DELETE, LIST,
POP, CLOSE 等）
- 2、 Delta： 存储对象的行为(变化)类型，Added, Updated, Deleted, Sync等

## 构造demo
在看源码之前可以通过构造一个demo来了解DeltaFIFO的基本功能, [github 地址](https://github.com/liuzehao/opetatorDemo/tree/main/100)：
```python
package main

import (
	"fmt"
	"k8s.io/client-go/tools/cache"
)

type pod struct {
	Name  string
	Value int
}

func newPod(name string, v int) pod {
	return pod{Name: name, Value: v}
}

func podKeyFunc(obj interface{}) (string, error) {
	return obj.(pod).Name, nil
}

// demo: DeltaFIFO queue
func main() {
	df := cache.NewDeltaFIFOWithOptions(cache.DeltaFIFOOptions{KeyFunction: podKeyFunc})

	pod1 := newPod("pod1", 1)
	pod2 := newPod("pod2", 2)
	pod3 := newPod("pod3", 3)

	df.Add(pod1)
	df.Add(pod2)
	df.Add(pod3)
	pod1.Value = 10
	df.Update(pod1)
	//fmt.Println(df.List())
	df.Delete(pod1)

	df.Pop(func(obj interface{}) error {
		//fmt.Printf("%T", obj)
		for _, delta := range obj.(cache.Deltas) {
			fmt.Println(delta.Type, ":", delta.Object.(pod).Name, delta.Object.(pod).Value)
		}
		return nil
	})
}

```
输出：  
Added : pod1 1  
Updated : pod1 10  
Deleted : pod1 10  
也就是说DeltaFIFO可以跟据delta.Object重排顺序，并在pop中输出。

## demo解释
- 创建 DeltaFIFO 实例：
```python
df := cache.NewDeltaFIFOWithOptions(cache.DeltaFIFOOptions{KeyFunction: podKeyFunc})
```
这一行代码创建了一个 DeltaFIFO 实例，并使用了 podKeyFunc 作为键生成函数。键生成函数的目的是为每个对象生成一个唯一的键，以便在队列中进行标识。

- 添加、更新和删除对象：
```python
pod1 := newPod("pod1", 1)
pod2 := newPod("pod2", 2)
pod3 := newPod("pod3", 3)

df.Add(pod1)
df.Add(pod2)
df.Add(pod3)
pod1.Value = 10
df.Update(pod1)
df.Delete(pod1)
  ```

- 弹出队列中的 Delta：
```python
df.Pop(func(obj interface{}) error {
    for _, delta := range obj.(cache.Deltas) {
        fmt.Println(delta.Type, ":", delta.Object.(pod).Name, delta.Object.(pod).Value)
    }
    return nil
})

```
这一组操作向 DeltaFIFO 中添加了三个初始 pod 对象（pod1、pod2、pod3），然后更新了 pod1 的值，最后删除了 pod1。每次这些操作发生时，DeltaFIFO 会生成对应的 Delta（变更对象） 并将其加入队列。

在整个过程中，DeltaFIFO 会追踪每个对象的变更历史，包括添加、更新和删除操作。Pop 方法用于从队列中弹出最早的 Delta，并通过回调函数处理这些 Delta。这使得你可以轻松地处理对象的变更历史，对 Delta 中的对象进行特定操作，从而实现一些高级的控制逻辑。

##  keyFunc 和 knownObjects
你可能注意到代码中有一个cache.DeltaFIFOOptions没有解释，这个函数的输入参数有两个：

NewDeltaFIFO 函数返回一个 DeltaFIFO 实例，用于处理对项的更改。keyFunc 用于确定对象的唯一键，而 knownObjects 可以影响删除、替换和重新同步的行为。这个 DeltaFIFO 实例是用于在 Kubernetes 集群中处理对象变更的一种机制，允许你对 DeltaFIFO 进行定制以适应特定的使用场景。
- keyFunc:
keyFunc 是一个用于确定对象应该具有什么键的函数。在 DeltaFIFO 中，键是用于标识和检索队列中对象的唯一标识符。这个函数可能是用户提供的自定义函数，它将一个对象作为参数，并返回一个唯一的键。这个键将用于标识队列中的对象，并与删除对象和队列状态相关的操作一起使用。通过 DeltaFIFO 的 KeyOf() 方法可以访问这个键。在client-go实现中有一个默认的keyFunc方法:
```python
func MetaNamespaceKeyFunc(obj interface{}) (string, error) {
	if key, ok := obj.(ExplicitKey); ok {
		return string(key), nil
	}
	meta, err := meta.Accessor(obj)
	if err != nil {
		return "", fmt.Errorf("object has no meta: %v", err)
	}
	if len(meta.GetNamespace()) > 0 {
		return meta.GetNamespace() + "/" + meta.GetName(), nil
	}
	return meta.GetName(), nil
}
```
可以看到如果资源有namespace的话就会获取到"namespace/资源名字"，如果没有的话就是"资源名"

- knownObjects:
knownObjects 是一个可选参数，用于修改 Delete、Replace 和 Resync 操作的行为。如果你不需要对这些操作进行修改，可以将其设为 nil。这个参数是一个用于定制 DeltaFIFO 行为的可选对象，包含一些已知的对象列表，以影响删除、替换和重新同步的操作行为。在真实场景中这个地方会存全量数据，会给到indexer中。

### keyFunc 例子
假设我们希望使用 Pod 的名称作为其唯一键。我们可以定义一个函数来提取 Pod 对象的名称，并将其用作 DeltaFIFO 中对象的唯一标识符。这个函数可能如下所示：
```python
func podKeyFunc(obj interface{}) (string, error) {
    pod, ok := obj.(*v1.Pod)
    if !ok {
        return "", fmt.Errorf("not a Pod object")
    }
    return pod.Name, nil
}
```
在创建 DeltaFIFO 时，我们将这个函数传递给 NewDeltaFIFO：
```python
deltaFIFO := NewDeltaFIFO(podKeyFunc, nil)
```
### knownObjects 例子：

假设我们希望在删除 Pod 对象时执行一些额外的逻辑。我们可以创建一个包含已知 Pod 对象的列表，并在 Delete 操作中检查该列表。如果对象存在于列表中，我们可以执行额外的清理步骤。这个逻辑可能如下所示：
```python
type PodLister struct {
    Pods map[string]*v1.Pod
}

func (lister *PodLister) Get(key string) (interface{}, error) {
    pod, ok := lister.Pods[key]
    if !ok {
        return nil, fmt.Errorf("Pod not found")
    }
    return pod, nil
}

func (lister *PodLister) List() ([]interface{}, error) {
    var pods []interface{}
    for _, pod := range lister.Pods {
        pods = append(pods, pod)
    }
    return pods, nil
}
```
然后，我们可以在创建 DeltaFIFO 时将这个 PodLister 传递给 knownObjects：
```python
podLister := &PodLister{
    Pods: make(map[string]*v1.Pod),
}

deltaFIFO := NewDeltaFIFO(podKeyFunc, podLister)

```
当执行 DeltaFIFO 的 Delete 操作时，它可以检查 knownObjects 中是否存在该 Pod，并执行相应的逻辑。

##  源码简析
源码贴在这里过于冗长，仅仅写一些关键点。从下面几个关键点来分析。
- DeltaFIFO分析
- 上游分析
- 下游分析
### DeltaFIFO分析 
- DeltaFIFO的接口和实现

    源码位置: k8s.io/client-go/tools/cache/delta_fifo.go  
    DeltaFIFO本身是对[store struct](k8s.io/client-go/tools/cache/store)接口的实现，与其实现同一个接口的struct有:  
    Cache, UnderltaStore, FIFO, Heap和ExpirationCache。
    除了实现Store所有的方法之外，还有两个自定义方法：populated，initialPopulationCount

- DeltaType 
从代码可以看到delta固定为一下5种类型
```python
  const (
	Added   DeltaType = "Added"
	Updated DeltaType = "Updated"
	Deleted DeltaType = "Deleted"
	// Replaced is emitted when we encountered watch errors and had to do a
	// relist. We don't know if the replaced object has changed.
	//
	// NOTE: Previous versions of DeltaFIFO would use Sync for Replace events
	// as well. Hence, Replaced is only emitted when the option
	// EmitDeltaTypeReplaced is true.
	Replaced DeltaType = "Replaced"
	// Sync is for synthetic events during a periodic resync.
	Sync DeltaType = "Sync"
)
```
- 生产者  
从架构图可以看到生产者只有一个reflector，具体是三种写入的情况:  
  1. list
  2. watch
  3. resync
塞数据的过程请看tools/cache/reflector.go中的 ListAndWatch方法。

- 消费者  
最终会有两个地方消费:  
  1. work queue 
  2. indexer: 这个是个缓存，后面讲


##  总结
DeltaFIFO在我们编写operator的过程中扮演一个根据keyFunc整合操作的角色。我们回头来看一下官方定义就很清楚了:
  - 您希望至多处理每个对象变更（delta）一次。  
  这个是FIFO队列的作用
  - 在处理对象时，您希望看到自上次处理以来发生的一切。  
  这个实现了keyFunc Pop函数带来的优势。可以根据keyFunc找到具体的资源，然后根据delta聚合返回处理。

  -  您希望处理一些对象的删除。  
  其实指的是knownObjects，后面再说

  -  您可能希望定期重新处理对象。  
  这个就是指的rsync函数