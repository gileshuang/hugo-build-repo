+++
Tags = ['Linux', 'route', 'policy']
Categories = ['运维向']
title = "Linux 上使用 systemd-networkd 服务配置策略路由"
date = "2017-12-23T15:04:05+08:00"
+++

这次就记录一下某个很常见却不常用的功能：Linux 上的策略路由。  
不同于使用 RHEL、ubuntu 等发行版专用配置文件，本文介绍的主要是使用
systemd-networkd 服务来配置路由。  
本文将介绍在同一台服务器上接入两块公网网卡，使这两块网卡分别同时工作的场景。  

******

> 免责说明：  
> 本文所使用 IP 地址并非我自己的实验环境的 IP，而是为了方便说明而杜撰的 IP。  
> 如果本文使用的 IP 实际上由某个人或者组织使用，则纯属巧合。  

### 前置环境

| component | version |
| :------ | :------ |
| os | ArchLinux 64bit |
| kernel | 4.14.8-1-ARCH |
| systemd | 236.0-2 |
|iproute2 | 4.14.1-2 |
|iptables | disabled |

| device | ip address | netmask | gateway |
| :------ | :------ | :------ | :------ |
| eth0 | 111.111.111.111 | 255.255.255.0 | 111.111.111.1 |
| eth1 | 222.222.222.222 | 255.255.255.0 | 222.222.222.1 |

在这个环境中，我们有了两张网卡，分别位于不同的网段。  
但是即使是有两张网卡，我们都需要将默认路由指定到其中一张网卡上。这里我们使用
eth0 的网关作为全局默认网关。  
策略路由的配置教程到处都有，本文的特别之处就在于使用了国内较少使用的网络管理器：
`systemd-networkd`。

### 不启用策略路由情况下的配置

首先，我们来了解一下单网卡情况下的 systemd-networkd 配置文件语法。  
现在先只配置 eth0，创建配置文件`/etc/systemd/network/10-eth0.network`：  
（配置文件名可自行指定，文件后缀需为 `.network`）

``` bash
# Match 字段匹配网卡设备名。
[Match]
Name=eth0

# Network 字段指定网络全局基本参数。
[Network]
# DHCP 值可设置为 yes、no、ipv4、ipv6。默认值为 no。
DHCP=no
# 下面几个字段。。。不用解释了吧。。。
# Address 和 DNS 字段可多次指定，且同时支持 ipv4 和 ipv6。
# 如需 ipv6，和 ipv4 一样，直接写上 ipv6 地址即可，无需特殊格式。
Address=111.111.111.111/24
Gateway=111.111.111.1
DNS=114.114.114.114
DNS=8.8.8.8
```

同理创建 eth1 的配置文件`/etc/systemd/network/10-eth1.network`，但是 eth1 上不指定 Gateway，否则两个默认网关会发生冲突：

``` bash
[Match]
Name=eth1

[Network]
DHCP=no
Address=222.222.222.222/24
DNS=114.114.114.114
DNS=8.8.8.8
```

使用命令`systemctl restart systemd-networkd.service`重启 systemd 网络管理器。  
重启完成后，我们可以发现 eth0、eth1 已经如期配置上 IP 地址了。  
此时我们可以查看路由表：

``` bash
[root@archlinux-conoha ~]
# ip route show
default via 111.111.111.1 dev eth0 proto static 
111.111.111.0/24 dev eth0 proto kernel scope link src 111.111.111.111 
222.222.222.0/24 dev eth1 proto kernel scope link src 222.222.222.222
```

于是我们已经成功为该服务器配置两个独立 IP 了。是这样吗？  
通过很简单的`ping`测试，你会发现只有 eth0 上的 IP 可以访问，eth1 上的 IP 总是 ping 不通。  
这就很尴尬了。。。  

### 几句话概括现状

当你使用 111.111.111.111 访问服务器的时候，发送包的目标 IP 和接受包的源 IP 一致。  
当你使用 222.222.222.222 访问服务器时，发送包的目标 IP 是 222.222.222.222，
而由于服务器的默认路由是指向 111.111.111.1，且无其它路由可以对从 eth1 过来的包再从 eth1 进行答复，
所以此时进行答复的包的源 IP 变为 111.111.111.111。发生包的目标 IP 和接受包的源 IP 不一致。  
为了让两个接口上的两个 IP 都你相当独立地工作，我们需要让它从 eth0 进来的包由 eth0
进行答复，从 eth1 进来的包由 eth1 进行答复。为达成此目的，我们就需要配置策略路由。  

### 配置 systemd-networkd

前面说过了，本文重点不在于“怎么配置”策略路由，而在于“怎么用 systemd-networkd”配置策略路由。  
有关 Linux 上策略路由的介绍和传统式配置方法可以参考
[使用 rt_tables 巧妙配置 Linux 多网卡多路由实现策略路由](https://segmentfault.com/a/1190000004165066)。
这文章写得不错，挺简单易懂的。

我们这里就直接通过改好的 systemd-networkd 配置文件讲起。

首先将 eth0 的配置文件`/etc/systemd/network/10-eth0.network`修改如下：

``` bash
[Match]
Name=eth0

[Network]
DHCP=no
Address=111.111.111.111/24
Gateway=111.111.111.1
DNS=114.114.114.114
DNS=8.8.8.8

# 从这往上的配置和刚才的一样，只是去掉了注释。
# 下面多加了几个配置。

# 配置子路由表的默认网关，该小节等同于：
# ip route add default via 111.111.111.1 dev eth0 table 111
# Table 字段表示该子路由表的数字 ID。
[Route]
Table=111
Gateway=111.111.111.1

# 配置子路由表的本网段路由，该小节等同于：
# ip route add 111.111.111.0/24 dev eth0 src 111.111.111.111 table 111
[Route]
Table=111
Destination=111.111.111.0/24
Source=111.111.111.111

# 配置到该子路由表的策略，该小节等同于：
# ip rule add from 111.111.111.111 table 111
[RoutingPolicyRule]
Table=111
From=111.111.111.111
```

将 eth1 的配置文件`/etc/systemd/network/10-eth1.network`修改如下：

``` bash
[Match]
Name=eth1

[Network]
DHCP=no
Address=222.222.222.222/24
DNS=114.114.114.114
DNS=8.8.8.8

# 依然是在原 eth1 的配置下面多加了几个配置。

# 配置子路由表的默认网关，该小节等同于：
# ip route add default via 222.222.222.1 dev eth0 table 222
# Table 字段表示该子路由表的数字 ID。
[Route]
Table=222
Gateway=222.222.222.1

# 配置子路由表的本网段路由，该小节等同于：
# ip route add 222.222.222.0/24 dev eth0 src 222.222.222.222 table 222
[Route]
Table=222
Destination=222.222.222.0/24
Source=222.222.222.222

# 配置到该子路由表的策略，该小节等同于：
# ip rule add from 222.222.222.222 table 222
[RoutingPolicyRule]
Table=222
From=222.222.222.222
```

修改完这两个配置之后，执行`systemctl restart systemd-networkd.service`重启网络管理器。  
至此，应当能够分别通过两个 IP 访问该服务器了。  
由于全局 Gateway 配置为 111.111.111.1，所以由服务器主动发起的请求则会默认通过 eth0 发送出去。

此时，我们可以查看路由表和策略路由：

``` bash
[root@archlinux-conoha ~]
# ip route show
default via 111.111.111.1 dev eth0 proto static 
111.111.111.0/24 dev eth0 proto kernel scope link src 111.111.111.111 
222.222.222.0/24 dev eth1 proto kernel scope link src 222.222.222.222
[root@archlinux-conoha ~]
# ip route show table 111
default via 111.111.111.1 dev eth0 proto static
111.111.111.0/24 dev eth0 proto static
[root@archlinux-conoha ~]
# ip route show table 222
default via 222.222.222.1 dev eth1 proto static
222.222.222.0/24 dev eth1 proto static
[root@archlinux-conoha ~]
# ip rule show
0:	from all lookup local
0:	from 111.111.111.111 lookup 111
0:	from 222.222.222.222 lookup 222
32766:	from all lookup main
32767:	from all lookup default
[root@archlinux-conoha ~]
# ip rule show table 111
0:	from 111.111.111.111 lookup 111
[root@archlinux-conoha ~]
# ip rule show table 222
0:	from 222.222.222.222 lookup 222
```

PS1：传统的策略路由配置方法中，需要修改`/etc/iproute2/rt_tables`以添加子路由表。
但使用 systemd-networkd 的过程中，我发现似乎不需要修改该文件也能工作。  
PS2：在使用过程中，发现似乎是由于 systemd 的 bug，在已经配置好 ip rule 的情况下，
`systemctl restart systemd-networkd.service`会出现服务重启失败。需要手动删掉对应的 ip rule，
然后再重启该服务。

### 小节

本文使用新式的 systemd-networkd 配置了传统的双网卡策略路由，
全程只需修改`/etc/systemd/network`目录下的`.network`配置文件即可。
且 systemd-networkd 的配置文件语法简洁易懂，仅用多个 section 下的 key-value
即可配置网络的各项参数和路由规则。

对于`.network`的更多配置选项，可通过`man systemd.network`查看相关手册。
