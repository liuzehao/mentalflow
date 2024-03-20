+++
title = 'Golang技术栈'
date = 2024-03-20T18:38:13+08:00
draft = false
tags= ["golang"]
categories= ["golang","golang技术栈"]
+++
## 前言
目前我主攻golang。golang将作为主要的服务编写，所以会涵盖我所能接触的的绝大多数后端技术。另外，有两类问题我认为是超越语言的，不会在这里提及，一是关于代码设计模式和服务架构方面的问题，二是业务相关(包括通用的业务)，比如token登录这种问题。大类上分为以下类别：
1. 测试：单元测试，mock测试，request测试，性能测试
2. CI/CD: 主要是CI
3. 常用框架五件套：web，数据库连接，配置，log，监控
4. 文档编写工具

## 0. 从功能角度看需要什么工具
总结下来发现内容有点多，所以只做简单介绍。针对其中的某些容易反直觉的点，后面单开文章描述。

- 测试： 单元测试，mock测试
- CI: 持续集成工具
- go-client: 适用于开发k8s operator的库
- viper: config配置
- gin: web框架
- go-svc: golang包装器
- gorm: mysql
- redis
- kafka
- etcd和zookeeper
- go routine和channel
- klog,glog: log库
- sentry: 在线debug工具
- swger,puml: 文档工具

## 测试
我觉得相比开发来说，测试是更加重要的。
- 单元测试: 在一个多人开发项目中，我们有时很难知道别人的改动是否对我们这块的功能有影响，所以对于关键节点编写单元测试，并且把自动运行单测写入到CI中是至关重要的。看似增加了工作量，可从长期来看，是可以减少大量的功能测试时间，减少潜在风险的。
- API测试：这个之前我用postman, 后来看到别的同事直接把测试案例用http里面，感觉是一种更好的办法。
```golang
### cluster sync
PUT {{host}} api/v1/cluster/sync/
Authorization: Bearer {{auth_token}}
```
- Mock测试: mock测试对于接口测试非常重要。设想一个场景：我需要获取一份数据，但是数据来源有多个，这种情况下我们可能会先编写一个接口用来隔离具体获取数据源的struct。我们如何在不编写实际数据源获取的struct的情况下测试方发是否有效呢，就可以用mock了。

## CI
CI太重要了，第一是跟上面说的一样，可以很好的实现自动测试。此外，还可以配置一系列静态代码检查，格式化，检查函数复杂度等等。可以让我们的代码质量提升一个数量级。在多人开发系统中是必不可少的。
- gitlab-ci
可以根据stage来编写流水线，当然，实际使用要复杂的多。多数情况会结合makefile来使用。这个值得单开一篇blog来总结一下。
```yml
build-job:
  stage: build
  script:
    - echo "Hello, $GITLAB_USER_LOGIN!"

test-job1:
  stage: test
  script:
    - echo "This job tests something"

test-job2:
  stage: test
  script:
    - echo "This job tests something, but takes more time than test-job1."
    - echo "After the echo commands complete, it runs the sleep command for 20 seconds"
    - echo "which simulates a test that runs 20 seconds longer than test-job1"
    - sleep 20

deploy-prod:
  stage: deploy
  script:
    - echo "This job deploys something from the $CI_COMMIT_BRANCH branch."
  environment: production
```

- golangci-lint
golang的静态代码分析工具 ，第三方开发了大量的工具，举一些常例子：

gocritic：gocritic 是一个 Go 代码静态分析工具，它提供了一系列检查，用于发现代码中的潜在问题和改进机会。
gocognit：gocognit 是一个用于检测代码复杂度的工具，它会根据代码中的复杂性来提供建议。
gomnd：gomnd 是一个用于检测魔法数字（magic number）的工具，它会发现代码中硬编码的数字，并提供建议将其提取为常量或者变量。
gosec：gosec 是一个用于检测 Go 代码中安全问题的工具，例如常见的安全漏洞和代码缺陷。

- [pre-commit](https://pre-commit.com/)
在项目开发中，我们都会使用到 git，我们可使用git hook实现在git commit的时候进行代码检查。直接编写git hooks脚本，时间久了之后会比较乱，推荐使用pre-commit框架来方便管理。
demo：请看官方案例，写的很不错

## 文档编写工具
