+++
title =  '[总结]非对称加密和自签名'
date = 2024-02-09T16:14:06+08:00
draft = false
tags= ["加密","self-signed","CA"]
categories=["打湿双手"]
+++

## 简介
非对称加密不是一个单点问题，是一个体系。它在当前的应用是方方面面的，网上资料虽然多，但是能真正说清楚的不多。要么就是只有理论，跟实际情况脱节，要么只有命令，讲不清楚背后发生了什么。可一旦遇到问题，如果缺乏一个好的知识体系，想要临时抱佛脚很难。而非对称加密相关的问题多不多呢？真的很多，只是平时不显露出来。按照本博客传统，demo优先，本文会从三个案例出发，深入浅出的描述证书的原理和应用。  
- 自签名证书: 自建CA, 自签名下级证书(sub-cert)完成server,client证书的生成。通过本案例可以打通理论和openssl在实际应用中的壁垒。对于内部服务自签名证书也是十分有用，我会用etcd的配置为例。  
- nginx配置域名证书: 跟第一个案例相比，可以学习使用第三方CA的流程，和实际生产中nginx的配置。  
- AnyConnect 扣证书: VPN也是可以配置证书的，通过配置证书来防止非目标电脑连接。而我们可以把证书扣出来，通过这种方式实现别电脑连vpn（这个操作十分tricky, 本人并不推荐大家去做）。说这个案例是会因为，可以更好的理解根证书在操作系统中的情况。  

## 理论
理论就是密码学课程上学的那一些。以网站使用https为例，简单总结就是:  

- 客户端： 拥有证书，证书中包含公钥和证书信息  
- 服务端： 由于私钥  
- CA: 发行证书  

客户端访问服务器: 客户端在访问服务端的时候，首先拿到服务端给的证书。怎么确定证书是对的呢？跟自己机器上默认的根证书做校验，校验通过就是正确的证书，浏览器上就会出现一把绿色的小锁。  

服务端工作：首先，服务端需要生成一个私钥和一个证书请求，将这两个东西上传到CA机构，让CA的根证书生成sub-cert。服务端将sub-cert和私钥存储在服务器上，当用户访问过来的时候，先把sub-cert传给对方。等对方用其中的公钥对传输信息进行加密之后，用自己的私钥解密，tls/ssl握手建立连接。  

CA的工作：上面也包含了，一个是要保证出厂的硬件系统都有自家的根证书。另一个是要帮助服务端生成sub-cert。当然，最重要的是保护好自己根证书的private key。  

如果你对上面的过程还不是特别清楚，推荐我同事的[这篇文章](https://www.kawabangga.com/posts/5330), 只需要看上半部分，下半部分证书签发过程不是本文的重点。  


## 自签名证书
### openssl
目前在TL协议上openssl可以说是事实上的标准，Slinux和mac是自带的。可以用下面的命令检查
```
$ openssl version -a
OpenSSL 1.1.1l  24 Aug 2021
built on: Thu Sep  2 14:16:35 2021 UTC
platform: darwin64-x86_64-cc
options:  bn(64,64) rc4(16x,int) des(int) idea(int) blowfish(ptr)
compiler: x86_64-apple-darwin13.4.0-clang -D_FORTIFY_SOURCE=2 -mmacosx-version-min=10.9 -isystem /Users/zehao.liu/opt/anaconda3/include -march=core2 -mtune=haswell -mssse3 -ftree-vectorize -fPIC -fPIE -fstack-protector-strong -O2 -pipe -isystem /Users/zehao.liu/opt/anaconda3/include -fdebug-prefix-map=/opt/concourse/worker/volumes/live/93a5a64e-7e23-405e-5b62-382c5f42022f/volume/openssl_1630592156441/work=/usr/local/src/conda/openssl-1.1.1l -fdebug-prefix-map=/Users/zehao.liu/opt/anaconda3=/usr/local/src/conda-prefix -fPIC -arch x86_64 -march=core2 -mtune=haswell -mssse3 -ftree-vectorize -fPIC -fPIE -fstack-protector-strong -O2 -pipe -isystem /Users/zehao.liu/opt/anaconda3/include -fdebug-prefix-map=/opt/concourse/worker/volumes/live/93a5a64e-7e23-405e-5b62-382c5f42022f/volume/openssl_1630592156441/work=/usr/local/src/conda/openssl-1.1.1l -fdebug-prefix-map=/Users/zehao.liu/opt/anaconda3=/usr/local/src/conda-prefix -DL_ENDIAN -DOPENSSL_PIC -DOPENSSL_CPUID_OBJ -DOPENSSL_IA32_SSE2 -DOPENSSL_BN_ASM_MONT -DOPENSSL_BN_ASM_MONT5 -DOPENSSL_BN_ASM_GF2m -DSHA1_ASM -DSHA256_ASM -DSHA512_ASM -DKECCAK1600_ASM -DRC4_ASM -DMD5_ASM -DAESNI_ASM -DVPAES_ASM -DGHASH_ASM -DECP_NISTZ256_ASM -DX25519_ASM -DPOLY1305_ASM -D_REENTRANT -DNDEBUG -D_FORTIFY_SOURCE=2 -mmacosx-version-min=10.9 -isystem /Users/zehao.liu/opt/anaconda3/include
OPENSSLDIR: "/usr/lib/opt/anaconda3/ssl"
ENGINESDIR: "/usr/lib/opt/anaconda3/lib/engines-1.1"
Seeding source: os-specific
```
OPENSSLDIR指向了默认配置和根证书

### 生成根证书
总共就三步，第一步创建出一个private key(里面也有public key), 第二步创建root csr, 第三步根据root csr和private key创建出root CA

- 创建private key

-  


## 参考
- [OpenSSL Cookbook  3rd Edition](https://www.feistyduck.com/library/openssl-cookbook/online/openssl-command-line/creating-certificate-signing-requests.html)
- [有关 TLS/SSL 证书的一切](https://www.kawabangga.com/posts/5330)

