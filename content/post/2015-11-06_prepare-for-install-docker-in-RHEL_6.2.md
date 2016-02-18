+++
Categories = ["码农向"]
Tags = ["linux", "docker", "kernel"]
date = "2015-11-06T19:01:12+08:00"
title = "在RHEL6.2上安装docker的准备工作"

+++

最近在尝试 docker，据说很高端大气上档次，于是就在空闲的时候开始鼓捣整。  
壮哉我大 Arch，内核版本都已经是 4.x 了（截至写本文），完全满足 docker 对内核版本的要求
（推荐 3.16，最低 3.10，据说红帽的 2.6.32-358 以上由于被打了补丁，也能支持 docker）。  
<!--more-->

然而事情总不会一帆风顺，比如某些线上环境，可能还在用很古老的发行版。  
现在，我就很奇葩地想要在 RHEL 6.2 上安装 docker。然而 RHEL 6.2 默认使用的内核是
2.6.32-220，并不满足 docker 的要求，于是就需要稍微升级一下内核。
俗话说，步子跨得大了，容易扯到蛋。所以我们选择版本号变化不那么大的 RHEL 6.6 版本自带
的 2.6.32-504 内核。  

#### 更新内核版本
首先系统的更新内核版本：

```
rpm -ivh --force http://yum.pplive.com/rhel_6.6_repo/Packages/kernel-2.6.32-504.el6.x86_64.rpm \
	http://yum.pplive.com/rhel_6.6_repo/Packages/kernel-firmware-2.6.32-504.el6.noarch.rpm \
	http://yum.pplive.com/rhel_6.6_repo/Packages/bfa-firmware-3.2.23.0-2.el6.noarch.rpm
```

对于部分设备，可能会出现依赖不满足。比如我遇到`bfa-firmware`包的依赖出现问题，这时，卸载掉旧版本的，
再尝试安装内核，即可解决。可以这样卸载（我不说你也懂）：

```
yum remove bfa-firmware
```

#### 更新device-mapper包

更新内核后，如果你直接安装运行 docker，会发现启动不了 docker 的服务。不管你有没有这个问题，
反正我是遇到了。这时检查是哪个组件不符合要求，比如我的环境下，是 device-mapper 包版本太低，
更新一下即可：

```
rpm -ivh --force http://yum.pplive.com/rhel_6.6_repo/Packages/device-mapper-libs-1.02.90-2.el6.x86_64.rpm \
	http://yum.pplive.com/rhel_6.6_repo/Packages/device-mapper-1.02.90-2.el6.x86_64.rpm \
	http://yum.pplive.com/rhel_6.6_repo/Packages/util-linux-ng-2.17.2-12.18.el6.x86_64.rpm \
	http://yum.pplive.com/rhel_6.6_repo/Packages/libblkid-2.17.2-12.18.el6.x86_64.rpm \
	http://yum.pplive.com/rhel_6.6_repo/Packages/libuuid-2.17.2-12.18.el6.x86_64.rpm
```

#### 安装docker

话说，标题我不是说了吗，这是准备工作。。。  
接下来，就可以像 RHEL/CentOS 6.5 以上的系统一样，添加`epel`源，然后直接安装`docker-io`包了。  
神马？怎么添加`epel`？怎么安装`docker-io`？bing/Google 一下一大堆，这都不会的话还是先回去
补基础吧，别急着用 docker 了。。。

