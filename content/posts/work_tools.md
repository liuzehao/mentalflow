+++
title = '[手册]效率工具'
date = 2024-04-16T15:14:36+08:00
draft = false
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
```shell
smc-auto () {
	processed_server=$(echo $1 | sed 's/-/./g')
	toc_cluster=$({{your_api}})
	if [[ $toc_cluster == "null" ]]
	then
		echo "Server not found: $processed_server"
		return 1
	fi
	if [[ $toc_cluster == "{{something}}" ]]
	then
		{{commond1}}
	else
		{{commond2}}
	fi
}
```

## [popclip](https://www.popclip.app/)
真的超级推荐popclip，这个工具可以让我们编写脚本，在选中的时候自动执行某些命令。比如选中一个ip, 然后自动登录，很方便。
![popclip](https://cdn.jsdelivr.net/gh/liuzehao/PictureManager/lib/popclip.png)
```javascript
# PopClip Terminal
name: Terminal
icon: iconify:logos:terminal
regex: '(\w+-(\w+-){2,}\w+)|\b((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(\.|$)){4}\b'
applescript: |
  tell application "System Events"
    -- some versions might identify as "iTerm2" instead of "iTerm"
    set isRunning to (exists (processes where name is "iTerm")) or (exists (processes where name is "iTerm2"))
  end tell
  tell application "iTerm"
    activate
    set hasNoWindows to ((count of windows) is 0)
    if isRunning and hasNoWindows then
      create window with default profile
    end if
    select first window
    tell the first window
      if isRunning and hasNoWindows is false then
        create tab with default profile
      end if
      tell current session to write text "smc-auto {popclip text}"
    end tell
  end tell
```
## [油猴](https://chrome.google.com/webstore/detail/tampermonkey/dhdgffkkebhmkfjojejmpbldmpobfkfo)
可以编写一些有趣的脚本，在匹配对应的domain的时候运行。帮助我们完成一些诸如登录的每天的重复性工作。

## 记忆复制[clipy](https://github.com/Clipy/Clipy)
默认的剪切板一次只能记录一个内容到缓存区。这个app可以帮助我们记录多个，方便我们复制粘贴。
![copy](https://cdn.jsdelivr.net/gh/liuzehao/PictureManager/lib/copy.png)

## 识别截图[Shottr](https://shottr.cc/)
在截图的时候，可以ocr识别出所有的文字内容。

## 网址快速跳转[Alfred](https://www.alfredapp.com/)
快速网址记录跳转工具，相对于收藏夹每次都要找半天来说好用很多。更有杀手级功能，自动定义参数，这意味着可以用这个工具快速调用一些api, 并将诸如ip之类的参数传递进去。比如下面我将1.1.1.1传递到一个叫node的api接口中，它实际上是node的监控调用接口，通过这个我可以快速跳转到node的监控。
![alfred](https://cdn.jsdelivr.net/gh/liuzehao/PictureManager/lib/alfred.png)

## 快捷命令转换 [aText](https://www.trankynam.com/atext/)
一款可以将一大串命令重命名为命令的软件。有一个bug就是软件容易卡死，此时只需要将屏幕重新解锁就行。
