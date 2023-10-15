---
title: "资源：各种国内镜像源"
date: "2023-07-21"
notaxonomy: false
norobots: false
nodate: false
hidemeta: false
draft: false
type: "原"

author: "yongliang"
authorlink: "https://neeyongliang.github.io"
nofeed: true
math: true
commentable: true
tags: ["mirrors", "linux"]
categories: ["links"]
---

> 由于你懂的多原因，有时候下载资源速度会非常慢，所以常常要借助国内镜像镜像源。

# 镜像源
国内目前做镜像源比较好的网站，一般分为两类：高校和云服务商。高校中，比较有名的有中科大USTC，清华TUNA，上海交大SJTUG，还有云服务厂商的阿里云、华为云、腾讯云、字节火山云…他们处于自身需求，或者提升产品体验的目的，不断丰富自身开源镜像所囊括的种类，原本作为发行版镜像源网站后来逐渐发展成综合性的镜像源网站。

## 云厂商

- 阿里云：[https://developer.aliyun.com/mirror/](https://developer.aliyun.com/mirror/)
- 腾讯云：[https://mirrors.cloud.tencent.com/](https://mirrors.cloud.tencent.com/)
- 华为云：[https://mirrors.huaweicloud.com/](https://mirrors.huaweicloud.com/)
- 字节火山云：[https://developer.volcengine.com/mirror/](https://developer.volcengine.com/mirror/)

## 高校

- 中科大USTC：[https://mirrors.ustc.edu.cn/](https://mirrors.ustc.edu.cn/)
- 清华TUNA：[https://mirrors.tuna.tsinghua.edu.cn/](https://mirrors.tuna.tsinghua.edu.cn/)
- 上海交大SJTUG：[https://mirrors.tuna.tsinghua.edu.cn/](https://mirrors.tuna.tsinghua.edu.cn/)

其中，首推阿里云和中科大镜像源，下面的分类源均可以在上面的找到。

# cargo 源

## 字节 cargo 源
修改 .bashrc 或 .zshrc 文件，添加如下内容，再 source 更新这些配置：
```shell
export RUSTUP_DIST_SERVER="https://rsproxy.cn"
export RUSTUP_UPDATE_ROOT="https://rsproxy.cn/rustup"
```
安装 cargo：
```shell
curl --proto '=https' --tlsv1.2 -sSf https://rsproxy.cn/rustup-init.sh | sh
```
更新镜像，修改 ~/.cargo/config 文件：
```shell
[source.crates-io]
replace-with = 'rsproxy-sparse'
[source.rsproxy]
registry = "https://rsproxy.cn/crates.io-index"
[source.rsproxy-sparse]
registry = "sparse+https://rsproxy.cn/index/"
[registries.rsproxy]
index = "https://rsproxy.cn/crates.io-index"
[net]
git-fetch-with-cli = true
```
注：cargo 1.68 起，已支持 sparse，否则将上面 rsproxy-sparse 改为 rsproxy。

# go 源

## 七牛云 go 源
如果使用的是 bash，将下面代码中 .zshrc 改为 .bashrc。
```shell
$ echo "export GO111MODULE=on" >> ~/.zshrc
$ echo "export GOPROXY=https://goproxy.cn" >> ~/.zshrc
$ source ~/.zshrc
```

# pip 源

## 豆瓣 pip 源
编辑 ~/.pip/pip.conf 文件，添加内容如下：
```shell
[global]
index-url = https://pypi.doubanio.com/simple
trusted-host = pypi.doubanio.com
```

# gitee
使用 gitee 能快速的从 Github 上拉取源码。
