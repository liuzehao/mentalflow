+++
title =  "python技术栈"
date = 2024-03-02T08:26:55+08:00
draft = false
tags= ["python","python技术栈"]
categories= ["python"]
+++

## 前言
在我的工作语言场景里，python主要扮演三种角色：
- 增强shell脚本的功能: 比如如果需要在机器上跑定时任务，这个任务是需要处理api调用的，python就比shell要好写
- 胶水命令工具: 简化手动操作命令。公司里面的系统通常会有很多协同问题，手动操作很繁琐，把命令打包可以缩短事故响应时间
- 算法题: python写算法题很方便，尤其是涉及到stack和queue，如果你对这个话题有兴趣可以看我的[算法gitbook](https://liuzehao139.gitbook.io/main/)

本文将主讲第一和第二点，分解一下的话，主要有以下几个主题：
1. poetry构建
2. click 命令封装
3. subprocess多线程
4. requst api发送和处理
5. 单元测试
6. git-ci的编写
   
## poetry
极力推荐用[poetry](https://python-poetry.org/)来构建项目，poetry并没有搞出新的概念，但是很好的集成了过去的功能。主要是三个功能：
- 虚拟环境
python各种不兼容的情况太多，是离不开虚拟环境的。poetry有类似于conda的功能, 可以隔离不同的开发环境，好处是不用额外安装别的虚拟环境工具。
```shell
poetry env use python
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

- 工作流：  
创建新的项目：  
poetry创建虚拟环境---> poetry init初始化--->通过poetry管理依赖，导入包--->通过poetry build---->通过poetry上传到pypi  
引入旧项目：  
通过poetry install安装依赖--->poetry shell进入虚拟环境--->开发  

- 和vscode整合
1. 安装对应的插件: Python Poetry, Poetry Monorepo
2. 在inerpreter中选中虚拟环境下的python

- Demo:  
[官方文档案例](https://python-poetry.org/docs/basic-usage/)  




## click
[click](https://click.palletsprojects.com/en/8.1.x/)是一个命令行工具，可以用装饰器来创建命令行，并且可以很好的支持子命令的嵌套。
Demo:
[官方文档案例](https://click.palletsprojects.com/en/8.1.x/)

如果你懒得看官方文档， 我总结了几个常用的装饰器，我一般就用这几个也够了。  
- 子命令: group和command
group使用来定义第一个命令的，command用来定义第一个命令的子命令，如果只有一个group，第一个命令可以省略。比如下面的demo用法就是:
python demo.py cli
```python
import click

@click.group()
def cli():
    pass

@cli.command()
def init():
    click.echo('Initialized the database')

@cli.command()
def reset():
    click.echo('Reset the database')

if __name__ == '__main__':
    cli()
```
- option选项和argument参数
可能有的人会对这个有点困惑，看看下面的demo就明白了。
```python
import click

@click.command()
@click.argument('operand1', type=int)
@click.argument('operand2', type=int)
def add(operand1, operand2):
    result = operand1 + operand2
    click.echo(f'{operand1} + {operand2} = {result}')

@click.command()
@click.argument('operand1', type=int)
@click.argument('operand2', type=int)
def subtract(operand1, operand2):
    result = operand1 - operand2
    click.echo(f'{operand1} - {operand2} = {result}')

@click.command()
@click.argument('operand1', type=int)
@click.argument('operand2', type=int)
def multiply(operand1, operand2):
    result = operand1 * operand2
    click.echo(f'{operand1} * {operand2} = {result}')

@click.command()
@click.argument('operand1', type=int)
@click.argument('operand2', type=int)
def divide(operand1, operand2):
    if operand2 != 0:
        result = operand1 / operand2
        click.echo(f'{operand1} / {operand2} = {result}')
    else:
        click.echo("Error: Division by zero.")

if __name__ == '__main__':
    add()
    subtract()
    multiply()
    divide()


python calculator.py add 5 3
```

```python
import click
import shutil

@click.command()
@click.option('--source', '-s', help='Source file path.')
@click.option('--destination', '-d', help='Destination file path.')
def copy(source, destination):
    shutil.copy(source, destination)
    click.echo(f'File copied from {source} to {destination}.')

@click.command()
@click.option('--source', '-s', help='Source file path.')
@click.option('--destination', '-d', help='Destination file path.')
def move(source, destination):
    shutil.move(source, destination)
    click.echo(f'File moved from {source} to {destination}.')

if __name__ == '__main__':
    copy()
    move()

python file_tool.py copy --source source.txt --destination destination.txt
```

- vscode添加命令参数
用了clik之后需要在vscode配置文件添加启动参数，不然debug会有点麻烦。添加方法也很简单, 把参数写args里面就行。  
```json
    "configurations": [
        {
            "name": "Python Debugger: Current File",
            "type": "debugpy",
            "request": "launch",
            "program": "${file}",
            "console": "integratedTerminal",
            "args": [
                "ip","127.0.0.1"
                ]
        }
    ]
```

## subprocess
