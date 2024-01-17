+++
title =  "k8s client-go 系列(2): List&Watch"
date = 2024-01-17T23:19:43+08:00
draft = false
tags= ["k8s","operator","开发","informer","client-go"] 
categories= ["k8s-operator开发"]
+++
## 简介
![20240114015320](https://cdn.jsdelivr.net/gh/liuzehao/PictureManager/lib/20240114015320.png)  
[client-go 架构图](https://github.com/kubernetes/sample-controller/blob/master/docs/controller-client-go.md)

github client-go项目:  
https://github.com/kubernetes/client-go

上文谈到了DeltaFIFO，通过demo实现了基本功能和进行了源码分析。接下来我来分析一把DeltaFIFO的上游Reflector。从架构图上我们可以看到Reflector通过List&Watch 来和k8s API进行沟通，然后把得到的数据写入DeltaFIFO。

## 搭建实验环境
由于这次的需要和k8s api进行交流，我们首先要搭建一个简单的k8s master来进行实验测试。由于我是mac, 我只写mac命令，别的环境大同小异。
- 使用colima(docker-desktop也可以) 来搭建docker 

- 安装kind  
brew install kind

- 用kind搭一个k8s  
kind create cluster --name your-fav-name

- 安装kubectl  
brew install kubectl

## 构造demo
还是上一篇的思路，先把组件拆出来构造一个demo了解功能。[github 地址](https://github.com/liuzehao/opetatorDemo/tree/main/101)。
```python
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

	podLW := cache.NewListWatchFromClient(clientset.CoreV1().RESTClient(), "pods", "default", fields.Everything())
	//list function
	list, err := podLW.List(metav1.ListOptions{})
	if err != nil {
		log.Fatalln(err)
	}
	podList := list.(*v1.PodList)
	for _, pod := range podList.Items {
		fmt.Printf(pod.Name)
	}

	//	watch function
	watcher, err := podLW.Watch(metav1.ListOptions{})
	if err != nil {
		log.Fatalln(err)
	}
	for {
		select {
		case v, ok := <-watcher.ResultChan():
			if ok {
				fmt.Println(v.Type, ":", v.Object.(*v1.Pod).Name)
			}
		}
	}
}

```
## demo解释
- 创建 Kubernetes 配置：
```python
config, err := clientcmd.BuildConfigFromFlags("", clientcmd.RecommendedHomeFile)
```
这里使用 clientcmd 包的 BuildConfigFromFlags 函数来构建 Kubernetes 配置。它试图使用默认的 kubeconfig 文件路径（通常是 $HOME/.kube/config），如果找不到则使用集群内置的默认配置。

- 创建 Kubernetes 客户端：
```python
clientset, err := kubernetes.NewForConfig(config)
```
使用上一步得到的配置，创建一个 Kubernetes 客户端，该客户端可以用于与集群进行交互。

- 创建 Pod ListWatcher：
```python 
podLW := cache.NewListWatchFromClient(clientset.CoreV1().RESTClient(), "pods", "default", fields.Everything())
```
使用 cache 包的 NewListWatchFromClient 函数创建一个 ListWatcher（用于列出和监视资源变更）。在这里，它使用 clientset 中的 REST 客户端，监视 "pods" 资源，位于 "default" 命名空间中，对所有字段进行选择。

- 列出 Pod：
使用 List 函数从 ListWatcher 中列出当前 Pod 的列表。如果出现错误，程序将打印错误并终止。然后，通过类型断言将结果转换为 v1.PodList 类型，然后遍历列表并打印每个 Pod 的名称。

- 监视 Pod 变更：
使用 Watch 函数从 ListWatcher 中创建一个用于监视资源变更的 Watcher。如果出现错误，程序将打印错误并终止。

- 处理 Watcher 事件：
```python 
for {
    select {
    case v, ok := <-watcher.ResultChan():
        if ok {
            fmt.Println(v.Type, ":", v.Object.(*v1.Pod).Name)
        }
    }
}

```
通过在无限循环中监听 watcher.ResultChan()，程序会阻塞等待来自 Watcher 的事件。一旦有事件发生，程序会检查事件的类型（增加、修改、删除等）并打印相关的信息，比如 Pod 的名称。

## 功能测试
这个demo的功能非常简单, 就是先list k8s-api中的pod, 然后监听pod资源的变化。有哪些变化呢？注意跟上篇讲的五个是不同的，具体见下面的源码简析。  
为了进行测试，我们可以先在k8s中创建一个测试用的pod。
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: test-pod
spec:
  containers:
    - name: test-container
      image: nginx:latest
```
输入命令k8s会自动帮我们创建pod
```shell
kubectl apply -f 文件地址
kubectl get pods
```
这时候，跑程序可以看到输出:
```
test-podADDED : test-pod
```
然后程序会一直监听，如果此时再导入另一个pod, 可以看到输出：
```
ADDED : test-pod2
MODIFIED : test-pod2
MODIFIED : test-pod2
MODIFIED : test-pod2
```
可能你会觉得奇怪，为什么是三个modified, 一个added。 原因很简单，当我们刚刚创建一个pod的时候，还没有处于running状态，在这个过程中会不断的修改state, 直到state变成跟spec一样的running状态，所以就会输出modified。  
接下来我们删除pod test-pod2, 得到输出：
```
MODIFIED : test-pod2
MODIFIED : test-pod2
MODIFIED : test-pod2
MODIFIED : test-pod2
DELETED : test-pod2
```
## 源码简析
本篇核心代码就是cache.NewListWatchFromClient, 把这个看明白也就可以了
```golang 
podLW := cache.NewListWatchFromClient(clientset.CoreV1().RESTClient(), "pods", "default", fields.Everything())
```
- 接口
```golang 
type ListWatch struct {
	ListFunc  ListFunc
	WatchFunc WatchFunc
	// DisableChunking requests no chunking for this list watcher.
	DisableChunking bool
}
```
实现了ListerWatcher interface。在其中又包含了另外两个接口Watcher interface和Lister interface。也就是说只要实现了watcher和lister, 这个函数就可以用在任何的资源上。

- 五种类型
这个可能比较难找，在k8s.io/apimachinery/pkg/watch/watch.go里面. 调用的地方在reflector那里，下一篇讲reflector的时候再说。
```golang
const (
	Added    EventType = "ADDED"
	Modified EventType = "MODIFIED"
	Deleted  EventType = "DELETED"
	Bookmark EventType = "BOOKMARK"
	Error    EventType = "ERROR"
)
```
- list和watch的本质
其实就是两个url
```
curl --cacert /path/to/ca.crt https://127.0.0.1:6443/api/v1/namespaces/default/pods
curl --cacert /path/to/ca.crt https://127.0.0.1:6443/api/v1/namespaces/default/pods \?watch\=true
```
要运行上面的curl需要把ca证书从kubeconfig里复制出来，默认路径在$HOME/.kube/config，注意需要base64解码。
官方文档同样可以查看到：
https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/#list-list-or-watch-objects-of-kind-pod
