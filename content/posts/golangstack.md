+++
title = '[总结]Golang技术栈'
date = 2024-03-20T18:38:13+08:00
draft = false
tags= ["golang"]
categories= ["打湿双手"]
+++
## 前言
目前我主攻golang。golang将作为主要的服务编写，所以会涵盖我所能接触的的绝大多数后端技术。另外，有两类问题我认为是超越语言的，不会在这里提及，一是关于代码设计模式和服务架构方面的问题，二是业务相关(包括通用的业务)，比如token登录这种问题。大类上分为以下类别：
1. 测试：单元测试，mock测试，request测试，性能测试
2. CI/CD: 主要是CI
3. 常用框架五件套：web，数据库连接，配置，log，监控
4. 文档编写工具

## 0. 从功能角度看需要什么工具
总结下来发现内容有点多，所以只做简单介绍。针对其中的某些简单叙述不够或者文档未说明的点，后面单开文章描述。

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
可以根据stage来编写流水线，当然，实际使用要复杂的多。多数情况会结合makefile来使用。
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
推荐一些比较好的库：
<details>
  <summary>点我展开看案例</summary>
  <pre><code>
  repos:
  <!-- 官方库,功能依次为: 
  大文件检测
  shell格式检测
  symlinks检测
  文件名冲突
  git merge冲突
  json,yaml,toml检查
  私钥检查
  文件结束符检查
  BOM检测
  禁止git submoudles
  禁止部分brach的上传
  文件行位空格检测 
  -->
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.4.0  # Use the ref you want to point at
    hooks:
      - id: check-added-large-files
      - id: check-executables-have-shebangs
        exclude: t/cmd/common.sh
      - id: check-shebang-scripts-are-executable
      - id: check-symlinks
      - id: destroyed-symlinks
      - id: check-case-conflict
      - id: check-merge-conflict
      - id: check-json
      - id: check-yaml
      - id: check-toml
      - id: detect-private-key
      - id: end-of-file-fixer
        exclude: docs/swagger.json
        exclude_types:
          - svg
      - id: fix-byte-order-marker
      - id: forbid-submodules
      - id: no-commit-to-branch
        args:
          - -b release
          - -b master
      - id: check-merge-conflict
      - id: trailing-whitespace
        args:
          - --markdown-linebreak-ext=md

<!-- 检查拼写错误 -->
  - repo: https://github.com/crate-ci/typos
    rev: typos-dict-v0.9.26
    hooks:
      - id: typos
        exclude: .*.http|.mod|.token
        exclude_types:
          - json

<!-- golang检查，功能依次为：
go-fmt - Runs gofmt, requires golang
go-vet - Runs go vet, requires golang
go-lint - Runs golint, requires https://github.com/golang/lint but is unmaintained & deprecated in favour of golangci-lint
go-imports - Runs goimports, requires golang.org/x/tools/cmd/goimports
go-cyclo - Runs gocyclo, require https://github.com/fzipp/gocyclo, args参数指定了复杂度的阈值（-over=16）
validate-toml - Runs tomlv, requires https://github.com/BurntSushi/toml/tree/master/cmd/tomlv
no-go-testing - Checks that no files are using testing.T, if you want developers to use a different testing framework
golangci-lint - run golangci-lint run ./..., requires golangci-lint
go-critic - run gocritic check ./..., requires go-critic
go-unit-tests - run go test -tags=unit -timeout 30s -short -v
go-build - run go build, requires golang
go-mod-tidy - run go mod tidy -v, requires golang
go-mod-vendor - run go mod vendor, requires golang
 -->
  - repo: https://github.com/dnephin/pre-commit-golang
    rev: v0.5.1
    hooks:
      - id: go-generate
      - id: go-fmt
      - id: go-imports
      - id: go-vet
      - id: go-mod-tidy
      - id: go-cyclo
        exclude: ^pkg/
        args: [ -over=16 ]
      - id: golangci-lint

<!-- 检查markdown语法 -->
  - repo: https://github.com/igorshubovych/markdownlint-cli
    rev: v0.34.0
    hooks:
      - id: markdownlint
        exclude: docs/swagger.md
      - id: markdownlint-fix
        exclude: docs/swagger.md

<!-- 这个很有意思，指定了commit messages的格式 -->
  - repo: https://github.com/compilerla/conventional-pre-commit
    rev: v2.2.0
    hooks:
      - id: conventional-pre-commit
        stages:
          - commit-msg
        args: # optional: list of Conventional Commits types to allow e.g. [feat, fix, ci, chore, test]
          - feat
          - fix
          - ci
          - chore
          - test
          - refactor
          - build
          - release
          - revert
          - perf
          - docs
          - typo
          - style
  
<!-- git commit 规范messages语法 -->
  - repo: https://github.com/jorisroovers/gitlint
    rev: v0.19.1
    hooks:
      - id: gitlint
        stages:
          - commit-msg

  </code></pre>
</details>

## 文档编写工具
