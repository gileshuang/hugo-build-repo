+++
Categories = ["运维向"]
Tags = ["docker"]
date = "2016-06-15T14:27:14+08:00"
title = "[转载]深入Docker存储驱动"

+++

本文主要介绍了Docker所使用到的几种存储驱动。
******

<!--more-->

<style type="text/css">
  .red-i { color: #fa0000; }
  .gray-i { color: #ccc; }
  .small { font-size: 70%; }
  .underline { text-decoration: underline; }
  .sidenote {
    float: right;
    width: 300px;
    padding: 5px;
    background-color: #eee;
    border: solid 1px gray;
    clear: right;
  }
  li p { line-height: 1.25em; }
</style>

<center>
#### 深入

#### Docker 存储驱动

##### *

##### Jérôme Petazzoni - @jpetazzo

##### Docker - @docker
</center>

---

#### 我是谁

<p class="sidenote"><span class="red-i">¹</span> 在的个人名片上至少标记着其中一项</p>

- [@jpetazzo](https://twitter.com/jpetazzo)

- Tamer of Unicorns and Tinkerer Extraordinaire<span class="red-i">¹</span>

- 脾气暴躁的法国DevOps人员 喜爱Shell scripts
  <br/> <span class="small">Go Away Or I Will Replace You Wiz Le Very Small Shell Script</span>

- 有一些容器技术的使用经验
  <br/> (负责 dotCloud PaaS 的构建和运维工作)

- 打算使用Markdown来制作ppt(这的确是个好主意)
  
  
---

#### 大纲

- Docker速览

- 简要介绍 copy-on-write

- Docker 存储驱动的发展历史

- AUFS, BTRFS, Device Mapper, Overlay<span class="gray-i">fs</span>, VFS

- 结论


---

<center>
#### Docker速览
</center>

---

#### Docker是什么?

- 一个由 *Docker Engine* 和 *Docker Hub* 组成的平台

- *Docker Engine*指的是容器的运行时环境

- Docker是开源的 由Go语言所开发 
  <br/> <span class="small"> <http://www.slideshare.net/jpetazzo/docker-and-go-why-did-we-decide-to-write-docker-in-go> </span>

- 它是一个守护进程, 被REST API控制

- 还是不清楚，它到底是什么!?
  <br/> 这周五 参与在线的 "Docker 101" 会议:
  <br/> <span class="small"> <http://www.meetup.com/Docker-Online-Meetup/events/219867087/> </span>

---

#### 如果你在实际工作中从未使用过Docker 以下内容可能会帮到你 ...

This will help!

```
jpetazzo@tarrasque:~$ docker run -ti python bash
root@75d4bf28c8a5:/# pip install IPython
Downloading/unpacking IPython
  Downloading ipython-2.3.1-py3-none-any.whl (2.8MB): 2.8MB downloaded
Installing collected packages: IPython
Successfully installed IPython
Cleaning up...
root@75d4bf28c8a5:/# ipython
Python 3.4.2 (default, Jan 22 2015, 07:33:45) 
Type "copyright", "credits" or "license" for more information.

IPython 2.3.1 -- An enhanced Interactive Python.
?         -> Introduction and overview of IPython's features.
%quickref -> Quick reference.
help      -> Python's own help system.
object?   -> Details about 'object', use 'object??' for extra details.

In [1]:
```

---

#### 这个过程中 发生了什么?

- 我们创建了一个 容器 (~相当于一个轻量级的虚拟机),
  <br/> 它拥有:

  - 文件系统 (基于一个 `python` 镜像)
  - 网络栈（network stack）
  - 进程空间

- 我们通过一个 `bash` 进程来启动
  <br/> (no `init`, no `systemd`, no problem)

- 我们通过pip安装了IPython, 并且将它运行起来

---

#### 在这个过程中哪些<span class="underline">没有</span>发生 ?

- 我们并没有完全地拷贝 `python` 镜像

安装过程在 容器 中完成, 而并非是在 镜像 中完成:

- 我们并没有修改 `python` 镜像本身

- 我们并没有影响其他容器的运行
  <br/> (当前使用的镜像或者其他的镜像)

---

#### 为什么这个问题很重要?

- 我们使用的是 *copy-on-write* 机制
  <br/> (Docker 帮助我们进行处理)

- 我们并没有对'python'镜像进行完整地拷贝，我们仅仅是跟踪容器相对于镜像所发生的变化

- 这个过程节省了大量的硬盘空间 (1 个容器 = 小于 1 MB 的存储空间)

- 节省了大量的时间 (1 个容器 = 小于 0.1s 的启动时间)

---

<center>
#### 对于 copy-on-write 的简要介绍
</center>

---

#### 历史背景

注意: 我并非是一个历史学家.

下面这些零散信息介绍的并不全面.

---

#### Copy-on-write  (RAM)

- `fork()` (linux中的进程创建函数)

  - 快速地创建一个新的进程

  - ... 即使是这个进程使用了许多 GBs 的 RAM

  - 在类似于 e.g. Redis `SAVE`的功能中被频繁地使用,
    <br/> 为了获得一致的镜像（consistent snapshots）

- `mmap()` (将文件映射到指定内存空间) 使用 `MAP_PRIVATE`参数

  - 使用MAP_PRIVATE参数之后 内存段变为私有 改变仅对本进程可见Changes are visible only to current process

  - 私有映射进行得很快 即使对大文件也是这样Private maps are fast, even on huge files

粒度: 1 次一个页面 (通常大小为 4 KB)

---

#### Copy-on-write 在内存服务中的应用 (RAM)

<p class="sidenote">
<span class="red-i">¹</span> 位置 = 地址 = 指针
<br/>
<span class="red-i">²</span> 操作 = 读、写或执行
</p>

它是如何工作的?

- 多亏了 MMU! (Memory Management Unit)

- 每次对内存的访问都需要通过MMU

- MMU可以把对于内存的访问请求 (虚拟的位置<span class="red-i">¹</span> + 操作<span class="red-i">²</span>) 转化为:

  - 实际的物理地址

  - 或者会返回一个页错误 (*page fault*)

---

#### 页错误（Page faults）

当页错误发生的时候,  MMU 就会通知 OS.

之后会发生什么?

- 要求访问不存在的内存空间 Access to non-existent memory area = `SIGSEGV`
  <br/><span class="small">(即 "段错误 Segmentation fault" 或是 "请继续学习指针的使用")</span>

- 访问已换出的内存空间 = 从硬盘中导入
  <br/><span class="small">(即 "我的程序怎么比以前满了1000倍")</span>

- 尝试向代码区写入内容 = seg fault (有时会发生)

- 尝试向拷贝区(copy area)写入内容 = 去重操作(deduplication operation)
  <br/><span class="small">之后如果什么也没有发生就恢复到初始化操作(initial operation)</span>

- 在非执行区域也可以捕获尝试执行的请求
  <br/><span class="small">(比如利用栈来避免某些漏洞(stack, to protect against some exploits))</span>

---

#### Copy-on-write 在存储服务中的应用 (disk)

- 最初的应用(个人看法)可能是 镜像服务

  (即是为更新频繁地数据库建立一致的备份 确保在开始备份到备份结束没有发生其他的操作)

- 在外接地存储设备上也可以使用(个人看法)Initially available  on external storage (NAS, SAN)

  (因为这个部分确实很复杂)

--

- 突然,
  <br/>疯狂的 云计算 出现了!

---

#### 简要地介绍一下虚拟机<span class="red-i">¹</span>

<p class="sidenote"><span class="small"><span class="red-i">¹</span> 不仅仅是虚拟机，还包括使用netboot的物理机 以及容器 也使用了类似地技术！</span></p>

- 基于Copy-on-write存储服务构建系统镜像Put system image on copy-on-write storage

- 为每一台虚拟机创建一个copy-on-write实例

- 如果系统镜像中包含了许多有用地软件 使用虚拟机的时候就不需要再安装额外的东西了

- 每一个额外生成地虚拟机仅仅需要硬盘空间来存储数据就行！

---

#### 可以用在笔记本电脑上的现代copy-on-write技术

(下面地排列并没有按照特定的顺序;列出的内容也并非详尽)

- LVM (Logical Volume Manager) on Linux

- ZFS on Solaris, then FreeBSD, Linux ...

- BTRFS on Linux

- AUFS, UnionMount, overlay<span class="gray-i">fs</span> ...

- Virtual disks in VM hypervisors

---

#### Copy-on-write 和 Docker 的结合: 一个美丽的爱情故事

- 如果没有 copy-on-write...

  - 一个容器永远无法启动起来 

  - 容器会占据很大的存储空间

- 如果你的笔记本电脑上没有...

  - 在你的Linux主机上 Docker将不再有用

---

<center>
#### 我们应该感谢下面这些人:

Junjiro R. Okajima (以及其他的AUFS贡献者)

Chris Mason (以及其他的BTRFS贡献者)

Jeff Bonwick, Matt Ahrens (以及其他的ZFS贡献者)

Miklos Szeredi (以及其他的overlay文件系统的贡献者)

Linux device mapper, thinp target, 等等服务的众多贡献者

<span class="small">... 以及该领域的先驱者们 站在他们的肩上 我们才能看得更远 </span>
</center>

---

<center>
####  Docker 存储驱动(storage drivers)的历史
</center>

---

#### 最初源于 AUFS

- Docker公司的前身是dotCloud
  <br/>(PaaS层产品, 类似 Heroku, Cloud Foundry, OpenShift...)

- dotCloud 从2008年开始使用AUFS技术
  <br/>(那时 vserver, then OpenVZ 都开始使用AUFS, 之后是LXC)

- 对于高密度的PaaS 应用 这是一个不错的选择
  <br/>(后面我们会有具体介绍!)

---

#### AUFS 并不完美

- 并没有被包括在Linux的主线内核中

- 使用补丁程序曾经是一件激动人心地事情

- ... 特别是与 GRSEC 相结合

- ... 并且加上其他定制的功能比如 `setns()`(将线程与namespace技术再结合)

---

#### 一些使用者一直信任AUFS!

- 特别是dotCloud

- Debian 以及 Ubuntu 在他们默认地内核中 使用了AUFS
  <br/>对于Live CD 以及类似的使用情况:

  - 你的根文件系统有 copy-on-write 的功能 并且介于以下两层之间：
    <br/>- 只读媒介 (CD, DVD...) 
    <br/>- 可读写媒介 (disk, USB stick...)

-  Docker 的第一个版本就是针对Ubuntu设计的 (以及 Debian)

---

#### 之后 一些人开始信赖 Docker

<p class="sidenote">注意:其他的贡献者在这个过程中也提供了很多支持!</p>

- Red Hat用户要求在他们最受欢迎的发行版中添加对Docker的支持

- Red Hat Inc. 也想让这一切发生

- ... 他们于是为Docker贡献代码 添加了对 Device Mapper driver的支持

- ... 之后是 BTRFS driver

- ... 接着是 overlay<span class="gray-i">fs</span> driver

---

<center>
#### 特别感谢:

Alexander Larsson

Vincent Batts

\+ 当然还有全部地贡献者和维护者

<span class="small">(上面两位贡献者在最初BTRFS、Device Mapper、以及overlay驱动的开发、支持和维护过程中扮演了极为重要的角色，再次感谢!)</span>
</center>

---

<center>
#### 让我们实际来看看

#### 每一种存储驱动

#### 是如何发挥作用的
</center>

---

<center>
#### AUFS
</center>

---

#### 原理

- 按照特定的顺序将多个分支结合在一起 

- 每一个分支都是一个标准的的目录 

- 通常会包括:

  - 至少一个只读分支 (在最低层)

  - 恰好一个读写分支 (再最顶层)

  (也可能有其它的组合方式!)

---

#### 当打开一个文件的时候 When opening a file...

- 通过 `O_RDONLY` - 只读的方式来进行访问:

  - 在每一个分支中进行查找 ，从最顶层的分支开始

  - 打开找到的第一个文件

- 通过 `O_WRONLY` 或 `O_RDWR` - 可写入的方式进行访问:

  - 首先在顶层分支中进行查找
    <br/>如果在顶层分支中找到，就打开文件

  - 如果没有找到, 就在其他分支中进行查找;
    <br/>如果在其他分支中找到文件，就把它拷贝到读写分支中(顶层) 之后打开拷贝过去的文件

    如果所打开的文件本身比较大 则向上拷贝的操作可能要多花一些时间

---

#### 当删除一个文件的时候...

- 此时会创建一个 *whiteout* 文件
  <br/>(这个与 "tombstones"的概念很类似)

```
#### docker run ubuntu rm /etc/shadow

#### ls -la /var/lib/docker/aufs/diff/$(docker ps --no-trunc -lq)/etc
total 8
drwxr-xr-x 2 root root 4096 Jan 27 15:36 .
drwxr-xr-x 5 root root 4096 Jan 27 15:36 ..
-r--r--r-- 2 root root    0 Jan 27 15:36 .wh.shadow
```

---

#### 在实际操作中

- 容器中AUFS的挂载点是
  <br/>`/var/lib/docker/aufs/mnt/$CONTAINER_ID/`

- 只有在容器运行地时候 文件系统才会被挂载

- AUFS的分支(只读分支和读写分支)的位置在
  <br/>`/var/lib/docker/aufs/diff/$CONTAINER_OR_IMAGE_ID/`

- 所有写入的内容都存在 `/var/lib/docker`目录下

```
dockerhost# df -h /var/lib/docker
Filesystem      Size  Used Avail Use% Mounted on
/dev/xvdb        15G  4.8G  9.5G  34% /mnt
```

---

#### 高级选项(Under the hood)

- 查看 AUFS 挂载的相关细节:

  - 在 `/proc/mounts`文件夹下 查看 内部ID

  - 查找`/sys/fs/aufs/si_.../br*`目录

  - 可以把每一个分支 (除去顶层的两个分支)
  <br/>理解成一个镜像

---

#### 实际例子(可以看到 除了最上面的两个分支之外 其他的分支都以镜像的形式体现出来)

```
dockerhost# grep c7af /proc/mounts
none /mnt/.../c7af...a63d aufs rw,relatime,si=2344a8ac4c6c6e55 0 0

dockerhost# grep . /sys/fs/aufs/si_2344a8ac4c6c6e55/br[0-9]*
/sys/fs/aufs/si_2344a8ac4c6c6e55/br0:/mnt/c7af...a63d=rw
/sys/fs/aufs/si_2344a8ac4c6c6e55/br1:/mnt/c7af...a63d-init=ro+wh
/sys/fs/aufs/si_2344a8ac4c6c6e55/br2:/mnt/b39b...a462=ro+wh
/sys/fs/aufs/si_2344a8ac4c6c6e55/br3:/mnt/615c...520e=ro+wh
/sys/fs/aufs/si_2344a8ac4c6c6e55/br4:/mnt/8373...cea2=ro+wh
/sys/fs/aufs/si_2344a8ac4c6c6e55/br5:/mnt/53f8...076f=ro+wh
/sys/fs/aufs/si_2344a8ac4c6c6e55/br6:/mnt/5111...c158=ro+wh

dockerhost# docker inspect --format {{.Image}} c7af
b39b81afc8cae27d6fc7ea89584bad5e0ba792127597d02425eaee9f3aaaa462

dockerhost# docker history -q b39b 
b39b81afc8ca
615c102e2290
837339b91538
53f858aaaf03
511136ea3c5a
```

---

#### 性能以及调优(Performance, tuning)

- AUFS `mount()` 速度很快 因此创建容器的过程也很快

- 对内存进行读/写操作的速度与原先区别不大

- 但是最初的 `open()` 操作 在写大文件的时候 比较费时

- 在以下方面仍有问题:日志文件(log files),数据库(databases) ...

- 并没有许多需要可以调优的地方(Not much to tune)

- 使用技巧: 当我们构建dotCloud的时候，我们最后把所有重要的数据都放在存储卷上 (putting all important data on *volumes*)

- 当多次启动一个容器的时候，数据只被从硬盘中导入了一次，并且只需要在内存中缓存一次(cached only once in memory)
  (but `dentries` will be duplicated)

---

<center>
#### Device Mapper
</center>

---

#### 序

- Device Mapper 是一个复杂的子系统; 它可以完成以下工作:

  - 磁盘阵列(RAID)

  - 设备编码(encrypted devices)

  - 镜像 (即使用 copy-on-write 机制)

  - 以及其它地一些零碎地功能

- 在Docker的环境下, "Device Mapper" 指的是
  <br/>"the Device Mapper system + its thin provisioning 存储"
  <br/>(有些时候标记为 "thinp")

---

#### 原理

- Copy-on-write 机制发生在存储块级别
  <br/>(而不是文件级别)

- 每一个容器额每个镜像都有它们自己的块设备

- 在任何给定地时间，都可能对以下内容进行快照：

  - 已经存在的容器 (创建一个静态的镜像(frozen image))

  - 已经存在的镜像 (从镜像中创建一个文件)

- 如果块设备一直没有被写入:

  - 就认为对应的空间没有内容(it's assumed to be all zeros)

  - 不会在硬盘上被分配空间
  <br/>(所谓的 "thin" provisioning)

---

#### 在实际操作中

- 容器挂载点的目录是在
  <br/>`/var/lib/docker/devicemapper/mnt/$CONTAINER_ID/`

- 只有在容器运行的时候 才会被挂载

- 数据存在两个文件中，一个是"data"文件 一个是"metadata" 文件
  <br/>(这个稍后会进行具体介绍)

- 因为我们实际的工作在block的层面上进行，所以对于镜像和容器之间的差别，我们并不全部可见

---

#### 高级选项(Under the hood)

- `docker info` 命令会告诉你当前资源池的状态
  <br/>(已用空间/可用空间)

- 使用 `dmsetup ls`列出全部可用设备

- 设备名称以"docker-MAJ:MIN-INO"为前缀

  <span class="small">MAJ, MIN, and INO 这几个简称来源于存储Docker数据的主块设备(block major) 从块设备(block minor) 以及索引结点号(inode number) (为了避免运行多个Docker实例的时候发生冲突 即在Docker中运行Docker)</span>

- 通过 `dmsetup info`, `dmsetup status`命令可以查看更多的信息

- 镜像有一个内部的数值形式的ID

- `/var/lib/docker/devicemapper/metadata/$CONTAINER_OR_IMAGE_ID`
  <br/>是一个小的JSON文件 用于跟踪记录镜像的ID以及它的大小

---

<!-- # Example -->

#### 额外的细节

- 需要两个存储区:
  <br/>一个用于存储数据(data), 另一个用于存储元信息(metadata)

- "data" 也可以理解成 "pool"; 它是一个存储块构成的巨大的资源池
  <br/>(Docker使用尽可能小的存储块，64KB)

- "元信息(metadata)"包含了虚拟地址偏移(在镜像中)到实际物理偏移 (在资源池中)的映射

- 每一次一个新的存储块(或者一个copy-on-write块被写入)
  一个存储块就从资源池中被分配出来

- 当资源池中没有新地存储块时，尝试进行写入的操作就会停止，直到资源池中资源的数量增加(或者写操作被终止)

---

#### 性能Performance

- 默认情况下 Docker将数据和元信息都存储在一个由稀疏文件(sparse file)做支撑的loop device上

- 从可用性的角度来看 这一点比较方便
  <br/>(基本上不需要进行配置)

- 从性能的角度来看 可能比较糟糕

  - 每一次 一个容器都向一个新的存储块中写入内
  - 存储块由资源池所分配
  - 并且在向存储块中写入内容时
  - 存储块必须从稀疏文件中分配而来
  - 而稀疏文件系统的性能并不怎么好

---

#### 优化Tuning

- 帮自己一个忙：如果你想使用 Device Mapper
  <br/>就把数据(以及元信息)存在实际的设备上(real devices)!

  - 终止Docker进程

  - 修改参数

  - 删除 `/var/lib/docker` (这一点很重要!)

  - 重启Docker进程

```
docker -d --storage-opt dm.datadev=/dev/sdb1 --storage-opt dm.metadatadev=/dev/sdc1
```

---

#### 进一步优化More tuning

- 让每一个容器都有它自己的块存储设备

  - 上面有一个真实的文件系统

- 所以你也可以调整 (通过`--storage-opt`参数):

  - 文件系统的类别

  - 文件系统的大小

  - `discard` (这个后面有更多介绍)

- 警告: 当你1000次启动容器的时候,
  <br/>文件会从硬盘中被导入1000次!

---

#### 可以参考以下资料

<span class="small">

- https://www.kernel.org/doc/Documentation/device-mapper/thin-provisioning.txt

- https://github.com/docker/docker/tree/master/daemon/graphdriver/devmapper

- http://en.wikipedia.org/wiki/Sparse_file

- http://en.wikipedia.org/wiki/Trim_%28computing%29

</span>

---

<center>
#### BTRFS
</center>

---

#### 原理

<p class="sidenote"><span class="red-i">¹</span> 这个操作可以通过`btrfs` 工具来完成.</p>

- 在文件系统的级别上完成全部的"copy-on-write"的工作

- 创建<span class="red-i">¹</span> 一个 "subvolume" (设想 `mkdir` 操作有极大的权限)

- 对任何的 subvolume 在任何时候生成镜像<span class="red-i">¹</span>

- BTRFS 从文件系统的级别而非是存储块设备的级别 将镜像和资源管理池的特性结合在一起

---

#### 在实际操作中

<p class="sidenote"><span class="red-i">¹</span> 即有连续地写入流的情况下.
<br/>性能可能是原先的性能(native performance)的一半</p>

- `/var/lib/docker`必须要是一个BTRFS文件系统

- 对于一个容器或者一个镜像 BTRFS 的挂载点位于
  <br/>`/var/lib/docker/btrfs/subvolumes/$CONTAINER_OR_IMAGE_ID/`

- 即使容器没有在运行BTRFS也会被使用

- 数据并没有直接被写入而是先是被写入到日志(it goes to the journal first)
  <br/>(在某些情况下<span class="red-i">¹</span>, 这可能会影响性能)

---

#### 高级选项(Under the hood)

- BTRFS 通过把存储设备分成不同的数据块(chunks)来发挥作用

- 一个数据块包含着元标签或者元信息(meta or metadata)

- 你可以用完全部的数据块 (会得到 `No space left on device`的消息)
  <br/>即便如此通过 `df` 命令还是会显示出有可用空间
  <br/>(因为存储块并没有占满所有空间(because the chunks are not full))

- 快速修复:

```
#### btrfs filesys balance start -dusage=1 /var/lib/docker
```

---

<!-- # Example -->

#### 性能以及调优

- 没有太多可以优化的地方

- 注意 `btrfs filesys show` 命令的输出!

表明文件系统正在正常运行:

```
#### btrfs filesys show
Label: none  uuid: 80b37641-4f4a-4694-968b-39b85c67b934
        Total devices 1 FS bytes used 4.20GiB
        devid    1 size 15.25GiB used 6.04GiB path /dev/xvdc
```

下面这种情况是文件块全部占满的情况(没有空闲的文件块) 即使上面没有太多的数据信息：

```
#### btrfs filesys show
Label: none  uuid: de060d4c-99b6-4da0-90fa-fb47166db38b
        Total devices 1 FS bytes used 2.51GiB
        devid    1 size 87.50GiB used 87.50GiB path /dev/xvdc
```

---

<center>
#### Overlay<span class="gray-i">fs</span>
</center>

---

#### 序

为何将<span class="gray-i">fs</span>标记为灰色?

- 它曾经被称为 `overlayfs`

- 当并入到 3.18 版本之后, 名称就变为了 `overlay`

---

#### 原理

- 这个文件系统与AUFS很类似，只有很少的地方有差别:

  - 只有两个分支only two branches (被称为文件层("layers"))

  - 但是分支只能进行自我覆盖

---

#### 在实际操作中

<p class="sidenote"><span class="red-i">¹</span>
对于其他发行版的适配工作就交给读者来完成
</p>

- 你需要内核版本为 3.18

- 在Ubuntu<span class="red-i">¹</span>上:

  - go to http://kernel.ubuntu.com/~kernel-ppa/mainline/

  - locate the most recent directory, e.g. `v3.18.4-vidi`

  - download the `linux-image-..._amd64.deb` file

  - `dpkg -i` that file, reboot, enjoy

---

#### 高级选项(Under the hood)

- 镜像以及容器在以下目录下被具体化
  <br/>`/var/lib/docker/overlay/$ID_OF_CONTAINER_OR_IMAGE`

- 镜像只有一个'root'子目录
  <br/>(包含了root FS)

- 容器含有:

  - `lower-id` → 文件包含镜像的ID 

  - `merged/` → 容器的挂载点(需要在运行的时候)

  - `upper/` → 容器的读写层

  - `work/` → 用于原子拷贝操作的临时的空间

---

<!-- # Example -->

#### 性能以及调优Performance, tuning

- 目前阶段没有什么需要调优的地方

- 性能方面应该与AUFS比较类似:

  * 向上拷贝速度较慢

  * 对内存资源的利用较好

- 具体实现细节:
  <br/>同样的文件在不同镜像之间通过硬链接的方式连在一起
  <br/>(这样可以避免进行复杂的覆盖( avoids doing composed overlays))

---

<center>
#### VFS
</center>

---

#### 原理

- 没有 copy on write 机制 Docker每次都要进行全部的拷贝!

- 并没有依赖于这些及为花哨的内核机

- 当将Docker移植到一个新的平台上的时候 这是一个不错的选择
  <br/>(think FreeBSD, Solaris...)

- 空间利用率低 速度慢 

---

#### 在实际操作中

- 在产品安装的时候可能比较有用 

  (如果你不想/不能 使用 存储卷，并且不想/不能使用任何 copy-on-write机制)

---

<center>
#### 结论
</center>

---

<center>
关于Docker存储驱动，最棒的就是，用户可以有如此多的选择。
</center>

---

#### 哪种情况应该选择哪种文件系统？(What do, what do?)

- 如果你做的是PaaS或使用其他的密集环境(high-density environment):

  - AUFS (要求内核提供对应的支持)

  - overlayfs (在其他的情况下)

- 如果你把一个大的可写的文件放在CoW文件系统:

  - BTRFS or Device Mapper (选择一个你最了解的)


---

<center>
#### 总而言之
</center>

---

<center>
在你的产品上
<br/>最好的存储驱动 
<br/>是你的团队有最多的实际操作经验的那一种
</center>

---

<center>
#### 特别内容(Bonus track)

##### `discard` and `TRIM`
</center>

---

#### `TRIM`

- 发送给SSD硬盘的内容 告诉SSD硬盘Command sent to a SSD disk, to tell it:
  <br/>"这个存储块已经不在被使用了"

- 这个功能很有用 因为对于SSD来说 *erase*的代价非常高 (速度很慢)

- 允许SSD 来提前预先擦除cells
   <br/>(并不是即时的 而是在 写操作之前)

- 这也对支持 copy-on-write 机制的存储有意义
  <br/>(如果/当 所有的镜像都作为一个trimmed block 那么它就可以被释放)

---

#### `discard`

- 文件系统选择的含义:
  <br/>*"can I has `TRIM` on this pls"*

- Can be enabled/disabled at any time

- 文件系统也可以使用`fstrim`通过手工地方式被修剪(be trimmed)
  <br/>(即使对于已经挂载了的文件系统)

---

####  `discard` 的困惑

- `discard` 在 Device Mapper + loopback devices 上工作

- ... 但是在 loopback devices 上速度特别慢
  <br/>(在容器或者镜像删除之后 loopback文件需要被"re-sparsified" 这是一个特别慢的操作)
- 你可以根据自己的偏好将其打开或者关闭

---

<center>
#### 以上就是全部的内容!
</center>

---

#### Questions?

- To get those slides, follow me on twitter: [@jpetazzo](https://twitter.com/jpetazzo)
  <br/><span class="small">Yes, this is a particularly evil scheme to increase my follower count</span>

- Also <span class="red-i">WE ARE HIRING!</span>

  - infrastructure (servers, metal, and stuff)

  - QA (get paid to break things!)

  - Python (Docker Hub and more)

  - Go (Docker Engine and more)

- Send your resume to jobs@docker.com 
  <br/><span class="gray-i">Do it do it do it NOW NOW!</span>

******

原文地址：<http://static.dockerone.com/ppt/filedriver.html>

*注：原文是一个用Markdown写的PPT，非常有趣，建议可以看看。

