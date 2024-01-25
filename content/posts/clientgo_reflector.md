+++
title =  "k8s client-go 系列(3): Reflector"
date = 2024-01-18T20:33:39+08:00
draft = false
tags= ["k8s","operator","开发","informer","client-go"] 
categories= ["k8s-operator开发"]
+++

## 简介
![20240114015320](https://cdn.jsdelivr.net/gh/liuzehao/PictureManager/lib/20240114015320.png)  
[client-go 架构图](https://github.com/kubernetes/sample-controller/blob/master/docs/controller-client-go.md)
本章可以在listwatch的基础上加入reflector, 并且把得到的值写入到第一章的deltafifo中，从而研究一把reflector。

## demo
```golang 
func main() {

	//create config
	config, err := clientcmd.BuildConfigFromFlags("", clientcmd.RecommendedHomeFile)
	if err != nil {
		panic(err)
	}

	//create client
	clientset, err := kubernetes.NewForConfig(config)
	if err != nil {
		panic(err)
	}
	df := cache.NewDeltaFIFOWithOptions(cache.DeltaFIFOOptions{KeyFunction: cache.MetaNamespaceKeyFunc})
	podLW := cache.NewListWatchFromClient(clientset.CoreV1().RESTClient(), "pods", "default", fields.Everything())
	rf := cache.NewReflector(podLW, &v1.Pod{}, df, 0)
	ch := make(chan struct{})
	go func() {
		rf.Run(ch)
	}()

	for {
		df.Pop(func(obj interface{}) error {
			for _, delta := range obj.(cache.Deltas) {
				fmt.Println(delta.Type, ":", delta.Object.(*v1.Pod).Name, ":", delta.Object.(*v1.Pod).Status.Phase)
			}
			return nil
		})
	}
}
```

## demo 解释
这一章中的大部分代码和前两章是一样的，区别是
```golang
	rf := cache.NewReflector(podLW, &v1.Pod{}, df, 0)
	ch := make(chan struct{})
	go func() {
		rf.Run(ch)
	}()
```
rf := cache.NewReflector(podLW, &v1.Pod{}, df, 0)：

podLW 是一个 ListWatch 接口，用于指定要监听的 Kubernetes 资源的类型和条件。在这里，它监听的是 Pod 资源，通过 podLW 来指定 Pod 的列表和 Watch 的条件。
&v1.Pod{} 表示监听的资源对象的类型。在这里是 Pod 资源，&v1.Pod{} 是 Pod 资源对象的一个空实例，用于指定资源的类型和 API 版本。
df 是 DeltaFIFO 的实例，它是一个队列，用于存储资源对象的增、删、改的 Delta 操作。
0 表示 ResyncPeriod，即重新同步的时间间隔，这里设置为 0 表示不进行定期重新同步，完全依赖于监听到的资源变更事件。
rf 是创建的 Reflector 实例，它将监听 Kubernetes API Server 上的 Pod 资源变更，并将这些变更转换成 Delta 操作存储到 DeltaFIFO 中。
ch := make(chan struct{})：

ch 是一个空结构体类型的通道，用于通知 Reflector 停止运行。通常，通过向这个通道发送信号来触发 Reflector 的停止操作。
go func() { rf.Run(ch) }()：

启动了一个新的 goroutine，其中运行了 rf.Run(ch)。
rf.Run(ch) 是 Reflector 的方法，它会开始监听资源的变更，并将这些变更转换成 Delta 操作存储到 DeltaFIFO 中。通过传递 ch 这个通道，可以随时通知 Reflector 停止运行。
这样的设计是为了使 Reflector 在后台异步运行，不阻塞主程序的执行。

## 功能测试
把上一张中的yaml导入我们可以看到
```
Sync : test-pod2 : Running
Added : test-pod : Pending
Updated : test-pod : Pending
Updated : test-pod : Pending
Updated : test-pod : Pending
Updated : test-pod : Running
```
删除这个pod我们可以看到
```
Updated : test-pod : Succeeded
Updated : test-pod : Succeeded
Updated : test-pod : Succeeded
```
此处会有一个问题，就是为什么没有delete事件？

## delete事件的处理
原因是在架构图中的有一个index, 这个index就是在第一章deltafifo中曾经提到过的另一个参数KnownObjects。
修改后的代码如下：
```golang
func main() {

	//create config
	config, err := clientcmd.BuildConfigFromFlags("", clientcmd.RecommendedHomeFile)
	if err != nil {
		panic(err)
	}

	//create client
	clientset, err := kubernetes.NewForConfig(config)
	if err != nil {
		panic(err)
	}
	store := cache.NewStore(cache.MetaNamespaceKeyFunc)
	df := cache.NewDeltaFIFOWithOptions(cache.DeltaFIFOOptions{KeyFunction: cache.MetaNamespaceKeyFunc, KnownObjects: store})
	podLW := cache.NewListWatchFromClient(clientset.CoreV1().RESTClient(), "pods", "default", fields.Everything())
	rf := cache.NewReflector(podLW, &v1.Pod{}, df, 0)
	ch := make(chan struct{})
	go func() {
		rf.Run(ch)
	}()

	for {
		df.Pop(func(obj interface{}) error {

			for _, delta := range obj.(cache.Deltas) {
				fmt.Println(delta.Type, ":", delta.Object.(*v1.Pod).Name, ":", delta.Object.(*v1.Pod).Status.Phase)
				switch delta.Type {
				case cache.Sync, cache.Added:
					store.Add(delta.Object)
				case cache.Updated:
					store.Update(delta.Object)
				case cache.Deleted:
					store.Delete(delta.Object)
				}
			}
			return nil
		})
	}
} 
```

## delete事件消失的解释
根据源码注释中的解释，这个故事我猜想是这样的。
- 1. 如果在一开始我们设置了index, 那么Deltafifo就会自动实现读写分离，也就是说Deltafifo只会负责写，而index是给我们读的。
- 2. Deltafifo会在Replace和Resync的时候把自己的数据同步给index, 这两种情况的区别在与有没有错误事件的产生。没错就Resync,有错就replace。
- 3. 由于Deltafifo和index之间是同步的关系，那么我们就可以将一些操作合并。那么，最烧脑的问题来了，过一个对象的多个操作，什么操作可以合并？
- 4. 对于更新这种类型的操作在没有全量基础的情况下是没法合并的，同时我们还不知道具体是什么类型的对象，所以能合并的也就是添加/删除，并且，两个添加/删除操作其实可以视为一个
  
## 关于删除操作的源码解释
- 关于合并操作
```golang 
// 代码源自client-go/tools/cache/delta_fifo.go
func dedupDeltas(deltas Deltas) Deltas {
    // 小于2个delta，那就是1个呗，没啥好合并的
    n := len(deltas)
    if n < 2 {
        return deltas
    }
    // 取出最后两个
    a := &deltas[n-1]
    b := &deltas[n-2]
    // 判断如果是重复的，那就删除这两个delta把合并后的追加到Deltas数组尾部
    if out := isDup(a, b); out != nil {
        d := append(Deltas{}, deltas[:n-2]...)
        return append(d, *out)
    }
    return deltas
}
// 判断两个Delta是否是重复的
func isDup(a, b *Delta) *Delta {
    // 只有一个判断，只能判断是否为删除类操作，和我们上面的判断相同
    // 这个函数的本意应该还可以判断多种类型的重复，当前来看只能有删除这一种能够合并
    if out := isDeletionDup(a, b); out != nil {
        return out
    }
	
    return nil
}
// 判断是否为删除类的重复
func isDeletionDup(a, b *Delta) *Delta {
    // 二者都是删除那肯定有一个是重复的
    if b.Type != Deleted || a.Type != Deleted {
        return nil
    }
    // 理论上返回最后一个比较好，但是对象已经不再系统监控范围，前一个删除状态是好的
    if _, ok := b.Object.(DeletedFinalStateUnknown); ok {
        return a
    }
    return b
}
```
- 关于replace操作
```golang
// 代码源自client-go/tools/cache/delta_fifo.go
func (f *DeltaFIFO) Replace(list []interface{}, resourceVersion string) error {
    f.lock.Lock()
    defer f.lock.Unlock()
    keys := make(sets.String, len(list))
    // 遍历所有的输入目标
    for _, item := range list {
        // 计算目标键
        key, err := f.KeyOf(item)
        if err != nil {
            return KeyError{item, err}
        }
        // 记录处理过的目标键，采用set存储，是为了后续快速查找
        keys.Insert(key)
        // 因为输入是目标全量，所以每个目标相当于重新同步了一次
        if err := f.queueActionLocked(Sync, item); err != nil {
            return fmt.Errorf("couldn't enqueue object: %v", err)
        }
    }
    // 如果没有存储的话，自己存储的就是所有的老对象，目的要看看那些老对象不在全量集合中，那么就是删除的对象了
    if f.knownObjects == nil {
        // 遍历所有的元素
        for k, oldItem := range f.items {
            // 这个目标在输入的对象中存在就可以忽略
            if keys.Has(k) {
                continue
            }
            // 输入对象中没有，说明对象已经被删除了。
            var deletedObj interface{}
            if n := oldItem.Newest(); n != nil {
                deletedObj = n.Object
            }
            // 终于看到哪里用到DeletedFinalStateUnknown了，队列中存储对象的Deltas数组中
            // 可能已经存在Delete了，避免重复，采用DeletedFinalStateUnknown这种类型
            if err := f.queueActionLocked(Deleted, DeletedFinalStateUnknown{k, deletedObj}); err != nil {
                return err
            }
        }
        
        // 如果populated还没有设置，说明是第一次并且还没有任何修改操作执行过
        if !f.populated {
            f.populated = true
            f.initialPopulationCount = len(list)  // 记录第一次通过来的对象数量
        }
 
        return nil
    }
    // 下面处理的就是检测某些目标删除但是Delta没有在队列中
    // 从存储中获取所有对象键
    knownKeys := f.knownObjects.ListKeys()
    queuedDeletions := 0
    for _, k := range knownKeys {
        // 对象还存在那就忽略
        if keys.Has(k) {
            continue
        }
        // 获取对象
        deletedObj, exists, err := f.knownObjects.GetByKey(k)
        if err != nil {
            deletedObj = nil
            glog.Errorf("Unexpected error %v during lookup of key %v, placing DeleteFinalStateUnknown marker without object", err, k)
        } else if !exists {
            deletedObj = nil
            glog.Infof("Key %v does not exist in known objects store, placing DeleteFinalStateUnknown marker without object", k)
        }
        // 累积删除的对象数量
        queuedDeletions++
        // 把对象删除的Delta放入队列
        if err := f.queueActionLocked(Deleted, DeletedFinalStateUnknown{k, deletedObj}); err != nil {
            return err
        }    
    }
    // 和上面的代码差不多，只是计算initialPopulationCount值的时候增加了删除对象的数量
    if !f.populated {
        f.populated = true
        f.initialPopulationCount = len(list) + queuedDeletions
    }
 
    return nil
}
```
从Replace()的实现来看，主要用于实现对象的全量更新。这个可以理解为DeltaFIFO在必要的时刻做一次全量更新，这个时刻可以是定期的，也可以是事件触发的。由于DeltaFIFO对外输出的就是所有目标的增量变化，所以每次全量更新都要判断对象是否已经删除，因为在全量更新前可能没有收到目标删除的请求。这一点与cache不同，cache的Replace()相当于重建，因为cache就是对象全量的一种内存映射，所以Replace()就等于重建。

那我来问题一个非常有水平的问题，为什么knownObjects为nil时需要对比队列和对象全量来判断对象是否删除，而knownObjects不为空的时候就不需要了？

我们前面说过，knownObjects就是Indexer(具体实现是cache)，而开篇的那副图已经非常明确的描述了二者以及使用之间的关系。也就是说knownObjects有的对象就是使用者知道的所有对象，此时即便队列(DeltaFIFO)中有相应的对象，在更新的全量对象中又被删除了，那就没必要通知使用者对象删除了，这种情况可以假想为系统短时间添加并删除了对象，对使用者来说等同于没有这个对象。
