+++
title =  "python技术栈"
date = 2024-03-02T08:26:55+08:00
draft = false
tags= ["python","技术栈","sre"]
categories= ["技术总结"]
+++

## 前言
在我的整体技术栈里面，python主要扮演三种角色：
- 增强shell脚本的功能: 比如如果需要在机器上跑定时任务，这个任务是需要处理api调用的，python就比shell要好写
- 命令胶水: 简化手动操作命令。公司里面的系统通常会有很多协同问题，手动操作很繁琐，把命令打包可以缩短事故响应时间
- 算法题: python写算法题很方便，尤其是涉及到stack和queue，如果你对这个话题有兴趣可以看我的[算法gitbook](https://liuzehao139.gitbook.io/main/)

本文将主讲第一和第二点，分解一下的话，主要有以下几个主题：
1. poetry构建
2. click 命令封装
3. subprocess多线程
4. requst api发送和处理
5. 单元测试
6. git-ci的编写
   
## poetry
极力推荐用[poetry](https://python-poetry.org/)来构建项目，poetry并没有搞出新的概念，但是很好了集成了过去的功能。主要是三个功能：
- 虚拟环境
python各种不兼容的情况太多，是离不开虚拟环境的。poetry有类似于conda的功能, 可以隔离不同的开发环境，好处是不用额外安装别的虚拟环境工具。
```shell
poetry shell
```
- 依赖管理
相比requirements.txt。更加的规范，并且可以通过lock来锁定配置。
```shell
poetry add 包名称
poetry remove
poetry update
```

- 打包发布
```shell
poetry build
poetry publish
```

工作流：  
创建新的项目：  
poetry创建虚拟环境---> poetry init初始化--->通过poetry管理依赖，导入包--->通过poetry build---->通过poetry上传到pypi  
引入旧项目：  
通过poetry install安装依赖--->poetry shell进入虚拟环境--->开发  

Demo:  
[官方文档案例](https://python-poetry.org/docs/basic-usage/)  




## click
[click](https://click.palletsprojects.com/en/8.1.x/)是一个命令行工具，可以用装饰器来创建命令行，并且可以很好的支持子命令的嵌套。
Demo:
[官方文档案例](https://click.palletsprojects.com/en/8.1.x/)

## subprocess
