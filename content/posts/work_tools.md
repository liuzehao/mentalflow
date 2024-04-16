+++
title = '[手册]效率工具'
date = 2024-04-16T15:14:36+08:00
draft = true
tags= ["效率","工具","popclip","油猴"]
categories= ["杂技浅尝"]
+++
## python制作命令行工具
最灵活的方式就是用python打包上传到pypi上，使用者通过pip安装后使用。整个过程推荐使用poetry来管理，非常方便。  
```shell
	bumpversion patch
	poetry build
	poetry publish -r {公司pypi}
```
具体使用可以参考[python技术栈](https://mentalflowing.com/posts/pythonstack/)

## shell脚本
python试一把利器，但有的简单的需求用python有小题大做的嫌疑。可以采用shell函数，然后把函数放置系统环境变量中,如果你会环境变量还不太清楚可以查看[[手册]Linux实用命令(一)](https://mentalflowing.com/posts/linuxcommond/)。这样我们就可以调用函数来处理一些问题了。比如：


## popclip
## 油猴
## 记忆复制
## 识别截图
## 网址快速跳转
## 快捷命令转换