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
1. click 命令封装
2. subprocess多线程
3. api发送和处理
4. git-ci的编写
5. poety打包

## click
[click](https://click.palletsprojects.com/en/8.1.x/)是一个命令行工具，可以用装饰器来创建命令行，并且可以很好的支持子命令的嵌套。
