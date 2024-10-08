+++
title = '[手册]Linux实用命令(一)'
date = 2024-01-19T11:34:54+08:00
draft = false
tags= ["linux"]
categories= ["杂技浅尝"]
+++
## 前言
刚开始工作时，看到同事们娴熟地输入各种Linux命令，有些人一条命令可以轻松输入三四行，流畅自如，让我觉得非常神奇。可是当轮到我自己时，总是记不住这个命令、那个参数。向他人请教，他们总是说多敲几次就熟悉了，但我总是不知道何时才能有那个“多”的机会。因此，我翻阅了各种Linux书籍，甚至看了好几本，但似乎仍然无法掌握。于是，我开始反思，直到有一天豁然开朗，开始轻松驾驭各种命令。我认识到的核心关键是：不要将Linux命令看作系统化的知识，而是要像背单词一样学习。

为何这样说呢？我和许多初学者交流过，由于大家在学校主要学习编程语言，很容易将学习编程语言的思维方式带入到Linux命令学习中，努力理解各种语法糖，试图构建一个完整的编码体系。但实际上，编程语言对应的应该是Linux脚本编程，而对于Linux命令来说，我们无法像写代码那样进行调试。而且由于历史原因，许多Linux命令功能重叠，使得整个体系变得复杂而庞大。在这种情况下，我们应该找出其中最实用的命令，刻意背诵常用的，然后学会查阅Linux文档（特别是man文档的专用格式），遇到不常见的命令要有查阅的能力。因此，一份真正的一线实战Linux命令手册变得至关重要，我在这里进行了总结。

## 掌握灵活的Log提取技巧
由于现代监控系统和日志系统的存在，理论还是那个时候我们可以借由平台来查看日志和一些基本问题。但是日志平台通常不够灵活，所以常常需要我们手动提取一下日志来判断。那么问题来了日志格式有很多种，要怎么用一些常用的命令保证不论什么日志我们都可以快速提取我们想要的内容呢？  

我总结两大使用场景：
- 提取
- 查找

### 提取
根据我的经验，绝大多数的提取场景逃不过这7个命令的排列组合
1. wc
2. head
3. cut
4. grep
5. sort
6. uniq
7. awk
8. tr

- wc  
  >1. -l 是行数  
  >2. -d 是字数 

- head  
    >1. head -n 就是前几行  
    >2. tail -n 是最后几行，和head相对应的
- cut  
   >1. cut -d ':' -f 2-  
   -d就是以什么作为分割，-f就是field,要显示哪些分割后的部分, 2-就是第二个后面都显示  
   >2. 特殊情况，制表符分割要用$:  
   cut -d $'\t'
- grep  
  >1. grep 过滤出关键词   
  >2. grep -v 不要这个关键词

- sort 部分排序  
  > 1. sort -k5,5n  
   `-k 5,5`: 这部分指定了要排序的字段范围。在这个例子中，`2,2` 表示只考虑第二个字段，n代表看成数字  
  > 2. sort -S 500M --parallel=4 -T   
   --paraller是多线程，有时候文件太大了，可以用这个加速分割速度  
  >3. sort -t ',' -k2,2nr  
    -t的作用是分分隔符
- uniq 
  >1. sort| uniq -c
  统计相同行，通常用于查出ip之后统计高频的, 常常跟sort一起用

- awk  
  awk本来最复杂，但可以先学几个简单用法。  
  >1.  awk 提取列  
 awk '{print $1, $3}' logfile.log
  >2. 提取关键字error的行  
   awk '/error/ {print}' logfile.log
  >3. 分割符号提取: 这个分割比cut好用很多  
   awk -F ',' '{print $2, $4}' csvfile.csv 
  >4. 格式化输出  
    awk '{printf "Date: %s, Time: %s\n", $1, $2}' logfile.log   

- tr
  用于转换或删除文件中的字符。
  >1. 删除文件中的空格字符：  
  tr -d ' ' < input.txt > output.txt  
  >2. 删除文件中的重复字符：  
  tr -s 'a-z' < input.txt > output.txt  
  >3. 字符组  
  tr是支持字符组的，这个东西最早来源于ERE标准的正则表达式。  
  将文件中的所有非字母字符替换为空格:  
  tr -c '[:alpha:]' ' ' < input.txt > output.txt  
  将文件中的所有数字替换为 X：  
  tr '[:digit:]' 'X' < input.txt > output.txt  
  小写转大写:
  tr '[:lower:]' '[:upper:]'
  换行符替换所有的非字符(数字+单词)，方便后续处理
  tr -cs '[:alnum:]' '['\n*']'
### 查找
- grep 
  >grep -rni 关键字  
   这个最常用最简单, 功能就是在全文检索当前目录下面的所有包含这个关键字的文件
- tree 查看目录结构  
  >默认不装，需要安装一个
- find递归目录查文件  
  >  find /path/to/search -type f -name "filename"  
  这个还支持正则，很强大，可能有点难记
  
基本这三个就够了，当然还有别的，建议慢慢来。


## 快速排查硬件问题
### 磁盘
硬盘一般是两大场景
- 磁盘满了需要找大文件
> 1. df -h  
这个在/查一下哪个磁盘占用大
> 2. ncdu -x /path  
这个非常好用，扫描路径下的所有文件，统计出大小

- 磁盘找进程
> 1. iotop
  监控发现io读写很高，通过磁盘io查到是哪个进程
> 2. lsof
  知道了一个文件有问题，要看哪个进程在读写  
  lsof /usr/share/nginx 

磁盘相关的问题其实非常多，但是本文只讲常用的。不常用的也挺重要，可以形成系统化认知，我将在另一篇文章中写写。

### 内存
常见的就是内存爆了
> top  
可以看到是哪个进程干爆了内存  
还有dstat、 perf、 vmstat 和swapon  
>

### cpu 
cpu通常不太会出问题。现在的服务器都是多核，单核被打满不会影响别的。常用工具有：  
top、 dstat、 perf、 ps、 mpstat、 strace和ltrace  

> perf是值得提一下的，可以用这个生成cpu运行时火焰图，在排查问题的时候有很好的效果
```shell
#!/bin/bash

# param1 perf file name

PERF_DATA_PATH=/tmp/perf_data

PERF_FILE=$1
if [ -z "${PERF_FILE}" ]; then
    PERF_GZFILE=`cd ${PERF_DATA_PATH} && ls  | grep "perf.gz" | tail -n 1`
    PERF_FILE=`echo "${PERF_GZFILE}" | sed 's/\.gz//'`
else
    PERF_GZFILE=${PERF_FILE}.gz
fi

LANIP=`hostname -I | awk '{print $1}'`
PERF_SVG=${LANIP}-${PERF_FILE}.svg
echo "PERF FILE:${PERF_FILE}"

if [ -z "${PERF_FILE}" ]; then
    echo "invalid perf file"
    exit 1
fi

FG_PATH=/usr/local/FlameGraph
PERF_GZFILE_PATH=${PERF_DATA_PATH}/${PERF_GZFILE}
PERF_FILE_PATH=${PERF_DATA_PATH}/${PERF_FILE}

cd /tmp
if [ -f ${PERF_GZFILE_PATH} ]; then
    cp -av ${PERF_GZFILE_PATH} /tmp
    rm -f ${PERF_FILE}
    gunzip ${PERF_GZFILE}
    ls -l ${PERF_FILE}
else
    cp -av ${PERF_FILE_PATH} /tmp
fi

if [ ! -d ${FG_PATH} ]; then
    cd /usr/local
		git clone --depth 1 https://github.com/brendangregg/FlameGraph
fi

PERF_BIN=$(which perf)
if [ -z "$PERF_BIN" ]; then
  PERF_BIN=/usr/lib/linux-tools/"$(uname -r)"/perf
fi

cd ${FG_PATH}
${PERF_BIN} script -i /tmp/${PERF_FILE} | ./stackcollapse-perf.pl | ./flamegraph.pl > /tmp/${PERF_SVG}

ls -l /tmp/${PERF_SVG}

rm -f /tmp/${PERF_FILE} /tmp/${PERF_GZFILE}

echo "download cmd:"

echo "scp ${LANIP}:/tmp/${PERF_SVG} ."
```

### 系统日志
> dmesg -T  
这个日志是从内核环形缓冲区中获得的。硬件相关的问题很多会记录在这里，常见比如cpu温度过高，网卡flapping，外接设备插拔等。



### 网络和网卡
> ifconfig  
  查看网络信息
> telnet  
  telnet {ip} {port}, 检查端口连接
> mtr  
  mtr -u -P {ip} --report 检查网络是否通  
网络和网卡的问题其实不容易排查，尤其是企业中网络情况往往很复杂，结合linux在下面来单独的说说

## Linux知识相关命令
这部分是涉及到linux系统的问题，都是可能的情况。我知道有的比较小众，就算是偏操作的sre也不是每个都遇到过。但是相信我，如果不知道或者现场调试的时候忘了怎么写，场面会非常尴尬, 属于不一定会用到但是最好知道的。

### linux文件类型
linux有以下的文件类型：  
普通文件 -  
符号链接 l  
目录    d  
字符设备 c  
块设备   b  
套接字   s  
FIFO    p  
### linxu文件权限
- 权限查看  
linux的文件权限按所有权分成三种, user/user group/others,根据权限类型大致有读/写/执行三种。
```shell
root@evm-1tjx7oledn8hjsc9k4v4hqft8:/tmp# ls -al
total 1260928
drwxrwxrwt 22 root root     12288 Apr  1 15:05 .
drwxr-xr-x 20 root root      4096 Feb 23 13:12 ..
drwx------  2 root root      4096 Mar 26 14:48 ansible-tmp
-rw-r--r--  1 root root        10 Jan 16 11:20 dctest
```
通过文件前面的10个字符来描述，第一个是文件类型。后面的代表了权限，也可以用数字来表述：  
r: 4  
w: 2  
x: 1  
还有两种特殊权限：  
粘滞位: 目录有一个叫作粘滞位（sticky bit）的特殊权限。如果目录设置了粘滞位，只有创建该目录
的用户才能删除目录中的文件，就算用户组和其他用户也有写权限，仍无能无力。粘滞位出现在
其他用户权限组中的执行权限（x）位置。它使用T或t来表示。如果没有设置执行权限，但设置
了粘滞位，就使用T；如果同时设置了执行权限和粘滞位，就使用t。  

setuid: setuid（Set User ID）是一种特殊的权限设置，它允许用户在执行某个二进制文件(必须是二进制，shell不行)时临时拥有该程序所有者的权限。它会取代user组中的x,比如:  
```shell
-rwsr-xr-x 1 root root 12345 Apr  1 10:00 /bin/my_special_program
```
- 权限设置  
1. 设置文件所有权：
```shell
chown user:group filename  
```

1. 设置文件权限
chmod a+t directory_name -R  
比如：  
```shell
chmod 777 . -R  
-R是递归修改  
```

- 文件拓展属性
在所有的Linux文件系统中都可以设置读、写、可执行以及setuia权限。除此之外，扩展文
件系统（例如ext2、ex13、ext4）还支持其他属性。以不可修改文件为例：
```shell
chattr +i file  
```
当想要修改的时候  
```shell
rm file
LM: cannot remove Ifile': Operation not permitted
```
如果要修改必须要先取消  
```shell
chattr -i file  
```
要查看是否设置了  
```shell
lsattr file
比如：
lsattr  zkkk.sh
----i---------e----- zkkk.sh
```
这个i就是不可修改

### linux文件软连接和硬连接
- 软连接
```shell
$ ln -s target symbolic_link_name
例如：
$ ln -1 -s /var/www/ ~/web
```
这个命令在当前用户的主目录中创建了一个名为Web的符号链接。该链接指向/var/www。
使用下面的命令来验证链接是否已建立：
```shell
$ 1s -l web
lrwxrwxrwx 1 root rrot 8 2024-01-25 21:34 web一>/var/www
web一>/var/www表明web指向 /var/www
```

- 硬链接
创建：  
```shell
ln /path/to/target /path/to/link
```
查看方式跟软连接是一样的：  
软链接以 l 字符开头，表示它是一个软链接。  
硬链接以 - 字符开头，表示它是一个普通的文件，也就是硬链接。  

软连接相对来说更加常用一点，有个八股题：软连接和硬链接有什么区别？  
单个人理解这个问题其实非常好，直至linux文件系统的设计方式，在这里说有点啰嗦了，放到本文的(二)中。千万别认为不理解这个不重要，本人遇到过事故，就是由于对文件系统理解有问题导致的。  

### linux环境变量
Shell在启动的时候会去读环境变量，环境变量一共分成两种: 全局系统变量和shell变量
全局：  
位于 /etc/environment 文件中，这些变量对系统中的所有用户和进程都是可见的。通常用于设置系统范围的默认环境变量，如全局 PATH、语言设置等。  
Shell变量：  
 - 1. 全局变量  
 /etc/profile 和 /etc/bash.bashrc：全局 shell 配置文件，用于设置全局环境变量。  
 - 2. 局部变量  
 ~/.bash_profile、~/.bashrc、~/.profile：用户的个人 shell 配置文件，用于设置用户特定的环境变量。bash这三个文件用于不同的场景，一般来说加到 ~/.bashrc。Zsh一般则需要添加到~/.zshrc  
 - 3. 导出变量  
export导出的临时变量。
#### 容易误解的点
1. zsh和bash的不同 
在默认情况下，Zsh 在启动时不会加载 ~/.bash_profile。Zsh 会加载自己的配置文件，主要是 ~/.zshrc。这意味着，如果你切换到 Zsh，并且依赖于 ~/.bash_profile 中的设置来配置环境变量，这些设置将不会自动加载。  
2. linux和mac的不同
在 Linux 中，默认 shell 通常是 Bash，而在 macOS 中，默认 shell 是 Zsh（从 macOS Catalina 开始）。  

### linux网络基本
我相信任何一个刚刚摸到线上环境的人都会为了网络问题头大一阵子，因为市面上常见的书对于网络命令的知识是远远不够的。比如常见问题网卡bond怎么做？光模块损毁怎么办？什么是IPLC？为什么要使用dpdk? 还有调查手段，网络不通怎么检查？防火墙问题还是网络问题，又或者是出口网关问题？  
这些问题其实不仅仅涉及到linux, 更是涉及到IDC中网络硬件设备，整体网络链路。后续我会把这些都讲一讲，在这一章我只谈谈linux相关的基本的网络命令。  
- 网络接口: ifconfig和ip
1. ifconfig这个显示的是所有网络接口的PLC地址,MAC地址和分配的ip。当然，作为新手可能搞不清楚什么是接口，什么是PLC，什么是虚拟接口，什么又是物理接口。不要着急，后面会讲的。  
这个命令还常用配置静态网络ip和mac：  
ifconfig wlan0 192.168.0.80  netmask 255.255.252.0  
ifconfig eth0 hw ether 00:1c:bf:87:25:d5  
有人可能奇怪mac地址不是网卡自带的嘛？为什么可以修改，其实不论是网卡地址还是ip都是记录在内核的一个表中，这使得mac地址修改是可能的。  
2. ip 这个命令在端口操作上和ifconfig其实差不多。  
添加和删除端口ip是这样的:
ip add add 192.168.1.10/24 dev eth0
ip add del 192.168.1.10/24 dev eth0

- 路由: route和ip  
route -n用来查看路由表，也可以添加路由  
route add default gw 192.168.0.1 wlan0  
ip route也可以

- arp表：ip
ip neighbor命令  

- 端口: lsof和netstat
lsof(list open files)看上去是个文件相关的命令，但是linux“一切皆文件”(逻辑怪表示很舒服)。每个网络连接都会生成一个文件描述符，所以这个命令选项-i可以支持查看端口。  
netstat -tnp, 相对而言用netstat看上去就更符合它的名字。  


### linux网络检查
- 网络: ping  
  
- 网络质量: traceroute和mtr  
这两个差不多，但是mtr默认能把loss显示出来，我用mtr比较多。  

- 测网速iperf  
有时候怀疑网络质量有问题，干脆测一下两台机器之间的网速.  
iperf -s 运行在服务器  
iperf -mc 服务器ip  

- 端口: nc, telnet  
有时候连不上对方机器的端口。  
telnet: 是一个用于远程登录的协议和客户端软件，它可以在命令行中连接到远程主机的 Telnet 服务器。  
telnet 主机名 端口号  

nc 是一个多功能网络工具，可以用于创建 TCP 或 UDP 连接、传输文件、进行端口扫描等。  
在检查端口连接性时，可以使用 nc 命令来尝试与目标主机的特定端口建立 TCP 或 UDP 连接。  
nc -vz 主机名 端口号  
nc这个命令还有一个有意思的功能，可以用来传文件:  
(1) 在侦听端执行下列命令:  
nc -l 1234 > destination_filename  
(2) 在发送端执行下列命令:  
nc HOST 1234 < source_filename  

当然一般服务器互相传文件不会这样搞，除了公司内部的软件之外，一般还有三种方式:  
   - ftp
   - sync
   - scp

- 套接字数据分析
显示tcp套接字状态 每一次HTTP访问、每一个SSH会话都会打开一个tcp套接字连接。选项-t可以输出TCP连接的状态:  
```shell
     $ ss -t
     ESTAB       0    0    192.168.1.44:740      192.168.1.2:nfs
     ESTAB       0    0    192.168.1.44:35484    192.168.1.4:ssh
     CLOSE-WAIT  0    0    192.168.1.44:47135     23.217.139.9:http
```
- tcpdump  
抓包最好用的工具了，必备利器。  
 tcpdump -enni any port 2181   
 转化成wireshark的格式，方便本地分析  
 tcpdump -enni any port 53 -w /tmp/dumptemp.pcap



## iptables的问题

## 练习方法
总结了这一堆之后，剩下的就是练习了。我的理念是学、练分离，学要多花时间理解背后的含义，不要尝试任何记忆。练分成两部分，一是把这个当个重要的事情狠狠背一把，然后就是想办法关联到实际场景。可以借用chatgpt,比如：
```
我在linu命令，请利用wc、head、cut、grep、sort、uniq、awk、tr出一些尽可能复杂的题目，并给我答案
```
建议每个月都抽一天，先找找博客有没有什么新鲜的不知道的新技巧补充到这个知识体系里，然后跟chatgpt对干几题，确保不会遗忘。