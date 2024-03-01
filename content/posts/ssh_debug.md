+++
title =  "记录一次ssh调试过程"
date = 2024-03-01T07:55:35+08:00
draft = false
tags=["linux","tcpdump","iptables","ssh","Jenkins"] 
categories=["杂技浅尝"]
+++
## 问题描述
我厂当前部分运维场景是Jenkins+ansible组合，由于ansible本身是以来ssh的，这就要求Jenkins主机可以ssh到server。由于Jenkins server最近迁移，导致出现了一系列的ssh失败的问题。今天来系统化的记录一下排查过程。

## 排查思路
