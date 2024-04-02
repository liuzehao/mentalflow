+++
title = '[杂技浅尝]Gitlab CI'
date = 2024-03-13T20:27:11+08:00
draft = true
tags= ["git","CI","CICD"]
categories=["CI","GIT"]
+++

## 前言
就像在[https://mentalflowing.com/posts/goalngstack](golang技术栈)所说，我认为在多人开发中制定一个好的CI是非常重要的。本文的目标是看了本文对于gitlab ci的理解不止于仅仅会对着模版修改，而是有一个全面的了解，当然具体细节还是以官方文档为主。  

值得一提的是gitlab ci和github ci在概念上是差不多的，只是语法有些不同，因为公司里一般都是用的gitlab，还是以这个为例吧。根据我的理解我将分一下几个部分来介绍gitlab ci。
- 整体介绍
- stage和执行器
- 关键字
- 优化速度




