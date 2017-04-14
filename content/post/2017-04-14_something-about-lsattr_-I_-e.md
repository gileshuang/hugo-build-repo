+++
Categories = ["运维向"]
Tags = ["Linux", "lsattr"]
date = "2017-04-14T11:42:04+08:00"
title = "[转载]由lsattr -I -e 文件扩展属性引发的一系列事情"

+++

今天同事问了我关于 lsattr 的问题，然后我表示并不清楚，翻看`man lsattr`收效甚微。  
后来次同事找到了下文，发给我看了，我权当记录，转载如下。至于个人的非转载部分的见解，
会在文章标出，并在文末补充。

******

问题起因很简单，今天有学员过来问了这样一个问题：

<!--more-->

![lsattr /usr/](/images/something-about-lsattr_-I_-e/01.jpg)

### 1. 如图`e`是什么?`I`又代表什么?

这个问题我觉得不是个难问题，简单man下就出来了，可问题来了，更多的系列问题更是随之而来…

> man lsattr

返回的全文如下：

``` man
LSATTR(1)                  General Commands Manual                 LSATTR(1)

NAME
       lsattr - list file attributes on a Linux second extended file system

SYNOPSIS
       lsattr [ -RVadv ] [ files...  ]

DESCRIPTION
       lsattr  lists  the  file attributes on a second extended file system.
       See chattr(1) for a description of the attributes and what they mean.

OPTIONS
       -R     Recursively list attributes of directories and their contents.

       -V     Display the program version.

       -a     List all files in directories, including files that start with
              `.'.

       -d     List  directories  like other files, rather than listing their
              contents.

       -v     List the file's version/generation number.

AUTHOR
       lsattr was written by Remy Card .   It  is  cur‐
       rently being maintained by Theodore Ts'o .

BUGS
       There are none :-).

AVAILABILITY
       lsattr  is  part  of  the  e2fsprogs  package  and  is available from
       http://e2fsprogs.sourceforge.net.

SEE ALSO
       chattr(1)

E2fsprogs version 1.42.9        December 2013                      LSATTR(1)
```

没有任何关于`-I -e`属性的介绍，好在

> lsattr  lists  the  file  attributes  on  a second extended file system.  See
> chattr(1) for a description of the attributes and what they mean.

有明确说明到`chattr`查找属性介绍。同样执行命令

> man chattr

因为内容较多，这里不一一列出，只列出最关键的部分。

- chattr的功能介绍是这样的

> chattr - change file attributes on a Linux file system（在Linux文件系统中改变文件属性）

- 用法是这样的

> chattr [ -RVf ] [ -v version ] [ mode ] files…

- 各选项功能介绍下：

![chattr](/images/something-about-lsattr_-I_-e/02.jpg)

如上图是从[wiki百科]()抓出来的，man文档中介绍的并没有如此详细，期间有一段曲折过程去理解，试验和找文档如何正确这些英文。
问题来了，

```
> -e 的解释是`The e attribute indicates that the file is using extents for mapping the blocks on disk.`
> -I 的解释是`The I attribute is used by the htree program code to indicate that a directory is being indexed using hashed trees.`
```

不知道各位有看懂的嘛，我是没看懂，字面意思相信都不难理解，4级不过懂英文的都不成问题，
关键的问题这里的专业术语太多，涉及的其它知识点太多，请雅思6级的帮忙也是捉瞎。
我们一条一条来分拆这里面的问题点：

> 问题1： the file is using extents …， 但为什么lsattr中目录为什么也有-e选项？  
> 问题2：什么是extents，扩展在这里是不好理解的？  
> 问题3：The I attribute is used by the htree program code, htree是什么？  
> 问题4：indicate that a directory is being indexed using hashed trees。indexed 
> using hashed trees被引用？  

关于这些问题，第一思路还是google，但随着工作时间的积累，从中文网站能获取的知识是越来越少了，
这次也再次验证了这样的问题。不谈创新，国内文档的依然只有一个字：*抄*~~，
几番折腾下来除了浪费时间没有其它再大收获。如下是国内文档获取的lsattr和chattr的相关信息：

#### 1.1 有用的文档1

##### 关于chattr和lsattr的解释说明

lsattr：查看特殊权限
chattr：在EXT2文件系统上改变文件属性

##### 用法

```
chattr  [+-=]  [ASacdistu]  [文件或目录名称]
```

chattr 改变EXT2文件系统上的一个文件的属性
参数符号格式是 `+-=[acdeijstuADST]`
操作符  `'+'`  表示将选中的属性增加到指定的文件上; `'-'` 则表示删除该属性;`'='` 表示文件仅仅设置指定的属性

##### 参数说明： 

```
    +-=：分别是”+”(增加)、”-“(减少)、”=”(设定)属性
    A：当设定了属性A，这个文件（或目录）的存取时间atime(access)将不可被修改，可避免诸如手提电脑容易产生磁盘I/* O错误的情况；
    S：这个功能有点类似sync，是将数据同步写入磁盘中，可以有效避免数据流失；
    a：设定a后，这个文件将只能增加数据而不能删除，只有root才能设定这个属性；
    c：设定这个属性后，将会自动将此文件压缩，在读取时自动解压缩。但是在存储的时候，会现进行压缩在存储（对于大* 文件很有用）；
    d：当dump（备份）程序执行时，设定d属性将可使该文件（或目录）具有dump功效；
    i：这个参数可以让一个文件”不能被删除、更名、设定链接，也无法写入数据，对于系统安全有很大的助益
    j：当使用ext3文件系统格式时，设定j属性将使文件在写入时先记录在日志中，但是当filesystem设定参数为data=jour* nalled时，由于已经设定了日志，所以这个属性无效
    s：当文件设定了s参数时，它会被完全移出这个硬盘空间
    u：与s相反，当使用u配置文件时，数据内容其实还可以存在于磁盘中，可以用来取消删除
    大文件(h),
    压缩错误(E),
    索引目录(I),
    压缩的原始访问?(X),
    和压缩的零碎文件(Z).
```

#### 1.2 有用的文档2

<http://serverfault.com/questions/400026/linux-ext4-extents-attribute>
serverfault上部分关于这个问题的解答算是较为详细清晰的解释，但离真相还是差的太远

##### 问题描述

> I noticed the `e` attribute on several files/directories on Linux machines installed on ext4 filesystems.
> 
>     [kelly@p2820887.pubip.serverbeach.com ~]$ lsattr -d /bin
>     -------------e- /bin
> 
> According to `chattr(1)`:
> 
> > The ’e’ attribute indicates that the file is using extents for mapping the 
> > blocks on disk. It may not be removed using chattr(1).
> 
> In what way is this different, and more importantly, in what way is this 
> detail significant — specifically why is this detail important enough to be 
> reported as a file attribute? Under what circumstances should I ever change 
> my behavior based on the knowledge that this file “is using extents for 
> mapping the blocks on disk”? Presumably this is something I need to know, 
> otherwise it wouldn’t be made so obvious, right?

##### 回复如下

> I think the extent flag is exposed as an attribute mainly so that you can _set_ 
> it with `chattr`, which will cause the ext4 driver to reallocate the file using 
> extents instead of block lists. If you've converted an existing ext3 filesystem 
> to ext4 (by using `tune2fs` to enable the new feature flags), you'll probably 
> want to convert the existing files to use extents, and this is the way to do it.
> 
> Newly-created files on an ext4 filesystem always use extents (as far as I know), 
> so if your filesystem was created as ext4 (as opposed to converted from ext3), 
> everything should have the extent attribute already so you don't need to worry 
> about it.
> 
> See [this article](http://www.debian-administration.org/articles/643) for 
more information.

网上关于该类问题的所有资料基于上停止于此。但其实问题连说明白都没有谈上。
对于如下解释，普通使用者随性讲讲有就好，但对于培训机构来讲，问题这样说就结束了，
个人希望能严谨做学问的态度吧，国内技术的整体门槛提升的责任在作学问人的身上~~

lsattr虽然用过很多次，但从来没有关注过这个e选项，因为它默认就有，
而且也不能用`chattr`去掉。 用`man chattr`，这个e是这样解释的：  
The ‘e’ attribute indicates that the file is using extents for 
mapping the blocks on disk.  It may not be removed using `chattr`.  
大概的意思是：这个‘e’属性表示，该文件在磁盘块映射上使用了extents。
这里的extents我们可以理解成是一个连续的范围。这个属性是不能通过chattr去除的。

到目前为止，几乎得不到任何其它有用的信息，在群里也没有得到相应的回复，
当时个人也陷入思维绝路。幸运的是，在整个排查问题查找答案的过程中，
我不停的看到关于文件系统的关键字样，也幸亏当时没有放弃忽略这样的关键字。
顺着`linux filesystem`同时扩展到`ext2 ext3 ntfs xfs jfs`等关键字搜索，
终于离真相一步上近了。先来看下如下几段文字 ：

### 2. 柳暗花明
#### 2.1 systems support extents（文件系统对extents的支持度）

```
ASM - Automatic Storage Management - Oracle's database-oriented filesystem.
BFS - BeOS, Zeta and Haiku operating systems.
Btrfs - GPL'd extent based file storage (16PiB/264 max file size).
Ext4 - Linux filesystem (when the configuration enables extents — the default in Linux since version 2.6.23).
Files-11 - Digital Equipment Corporation (subsequently Hewlett-Packard) OpenVMS filesystem.
HFS and HFS Plus - Hierarchical File System - Apple Macintosh filesystems.
HPFS - High Performance File Syzstem - OS/2 and eComStation.
JFS - Journaled File System - Used by AIX, OS/2/eComStation and Linux operating systems.
Microsoft SQL Server - Versions 2000-2008 supports extents of up to 64KB [1].
Multi-Programming Executive - Filesystem by Hewlett-Packard.
NTFS - Microsoft's latest-generation file system [1]
Reiser4 - Linux filesystem (in "extents" mode).
SINTRAN III - File system used by early computer company Norsk Data.
UDF - Universal Disk Format - Standard for optical media.
VERITAS File System - Enabled via the pre-allocation API and CLI.
XFS - SGI's second generation file system.[2]
```

#### 2.2 顺藤摸瓜再搜索文件系统的相关信息

除ext2外其它常见的文件系统，如ext3 ext4 NTFS 等都是日志型文件系统，
所谓日志型文件系统即所有有行为会记录在磁盘，系统默认会预留一些空间来记录的操作行为，
当系统不正常关机再开机时，不需要全盘扫描来恢复至系统正常状态。

Linux kernel 自 2.6.28 开始正式支持新的文件系统 Ext4。 Ext4 是 Ext3 的改进版，
修改了 Ext3 中部分重要的数据结构，而不仅仅像 Ext3 对 Ext2 那样，只是增加了一个日志功能而已。
Ext4 可以提供更佳的性能和可靠性，还有更为丰富的功能：

1. 与 Ext3 兼容。
 执行若干条命令，就能从 Ext3 在线迁移到 Ext4，而无须重新格式化磁盘或重新安装系统。原有 Ext3 数据结构照样保留，Ext4 作用于新数据，当然，整个文件系统因此也就获得了 Ext4 所支持的更大容量。

2. 更大的文件系统和更大的文件。
 较之 Ext3 目前所支持的最大 16TB 文件系统和最大 2TB 文件，Ext4 分别支持 1EB（1,048,576TB， 1EB=1024PB， 1PB=1024TB）的文件系统，以及 16TB 的文件。

3. 无限数量的子目录。
 Ext3 目前只支持 32,000 个子目录，而 Ext4 支持无限数量的子目录。

4. Extents。
 Ext3 采用间接块映射，当操作大文件时，效率极其低下。比如一个 100MB 大小的文件，在 Ext3 中要建立 25,600 个数据块（每个数据块大小为 4KB）的映射表。而 Ext4 引入了现代文件系统中流行的 extents 概念，每个 extent 为一组连续的数据块，上述文件则表示为“该文件数据保存在接下来的 25,600 个数据块中”，提高了不少效率。

5. 多块分配。
 当写入数据到 Ext3 文件系统中时，Ext3 的数据块分配器每次只能分配一个 4KB 的块，写一个 100MB 文件就要调用 25,600 次数据块分配器，而 Ext4 的多块分配器“multiblock allocator”（mballoc） 支持一次调用分配多个数据块。

6. 延迟分配。
 Ext3 的数据块分配策略是尽快分配，而 Ext4 和其它现代文件操作系统的策略是尽可能地延迟分配，直到文件在 cache 中写完才开始分配数据块并写入磁盘，这样就能优化整个文件的数据块分配，与前两种特性搭配起来可以显著提升性能。

7. 快速 fsck。
 以前执行 fsck 第一步就会很慢，因为它要检查所有的 inode，现在 Ext4 给每个组的 inode 表中都添加了一份未使用 inode 的列表，今后 fsck Ext4 文件系统就可以跳过它们而只去检查那些在用的 inode 了。

8. 日志校验。
 日志是最常用的部分，也极易导致磁盘硬件故障，而从损坏的日志中恢复数据会导致更多的数据损坏。Ext4 的日志校验功能可以很方便地判断日志数据是否损坏，而且它将 Ext3 的两阶段日志机制合并成一个阶段，在增加安全性的同时提高了性能。

9. “无日志”（No Journaling）模式。
 日志总归有一些开销，Ext4 允许关闭日志，以便某些有特殊需求的用户可以借此提升性能。

10. 在线碎片整理。
 尽管延迟分配、多块分配和 extents 能有效减少文件系统碎片，但碎片还是不可避免会产生。Ext4 支持在线碎片整理，并将提供 e4defrag 工具进行个别文件或整个文件系统的碎片整理。

11. inode 相关特性。
 Ext4 支持更大的 inode，较之 Ext3 默认的 inode 大小 128 字节，Ext4 为了在 inode 中容纳更多的扩展属性（如纳秒时间戳或 inode 版本），默认 inode 大小为 256 字节。Ext4 还支持快速扩展属性（fast extended attributes）和 inode 保留（inodes reservation）。

12. 持久预分配（Persistent preallocation）。
 P2P 软件为了保证下载文件有足够的空间存放，常常会预先创建一个与所下载文件大小相同的空文件，以免未来的数小时或数天之内磁盘空间不足导致下载失败。Ext4 在文件系统层面实现了持久预分配并提供相应的 API（libc 中的 posix_fallocate()），比应用软件自己实现更有效率。

13. 默认启用 barrier。
 磁盘上配有内部缓存，以便重新调整批量数据的写操作顺序，优化写入性能，因此文件系统必须在日志数据写入磁盘之后才能写 commit 记录，若 commit 记录写入在先，而日志有可能损坏，那么就会影响数据完整性。Ext4 默认启用 barrier，只有当 barrier 之前的数据全部写入磁盘，才能写 barrier 之后的数据。（可通过 “mount -o barrier=0” 命令禁用该特性。）
 
-o options 主要用来描述设备或档案的挂接方式。常用的参数有：
- loop：用来把一个文件当成硬盘分区挂接上系统
- ro：采用只读方式挂接设备
- rw：采用读写方式挂接设备
- iocharset：指定访问文件系统所用字符集

在Microsoft Winsows的世界，硬盘可以格式化成NTFS、FAT32、FATl6等等不同的格式。
同樣地，在GNU/Linux底下也是有很多不同的文件系统格 式可供选择。当前在GNU/Linux底下，
比较常用的有这几种格式：Ext2／Ext3、ReiserFS、XFS和JFS等数种。
    　
除了Ext2以外，其它几种都是日誌型文件系统。那什麼是日誌型文件系统呢？
就是系统会多用一些额外的空间纪錄硬盘的数据状态，因而在不正常开关机后，
不需整个硬盘重新扫描来恢复正常的系统状态。

- Ext2：此为一非常老旧且不支持日誌系统的文件系统格式，早期的Linux玩家应该还记得吧，
在每次不正常关机后，重新开机时错误检查会需要很久，而且在不正常关机下，
常常会让你一次不见很多文件，现在已经很少人使用这类文件系统了。
- Ext3：为Ext2个改良版，所以Ext2可以直接升级成为Ext3而不必重新格式化，
这也可以让旧的Ext2系统更加稳定。而主要和Ext2的差別是 增加了日誌系统(metadata)，
所以在不正常开关机后，可以迅速使系统恢复。而因为它与旧有的文件系统兼容，
因此很多发行版都缺省使用Ext3。但 是在实际测试上，它的硬盘使用率其实不佳，
大概只有真正空间的93％会被使用到，至於其它性能测试表现则为中等。
在格式化与创建文件系统的时间也是其它文 件系统的数十倍。
- ReiserFS：：採用日誌型的文件系统，为Hans Reiser所创，因此以他的名字来命名。
技术上使用的是B*-tree为基础的文件系统，其特色为从处理大型文件到眾多小文件都可以用很高的效率处理。
实务上ReiserFS 在处理文件小於1k的小文件时，效率甚至可以比Ext3快約10倍，
所以ReiserFS专长是在处理很多小文件。而在一般操作上，它的性能表现也有中上的程度。
- XFS： />不错的表现。
- JFS：：为全球最大计算机供应商IBM为AIX系列设计的日誌型文件系统，
技术上使用的是B+-tree为基础的文件系统和ReiserFS使用 B*-tree不同。
IBM AIX服务器在很多金融机构上使用，所以稳定性是沒话說的。
而它最重要的特色是在处理文件I/O的时候是所有文件系统里面最不佔CPU资源的，也就是CPU使用率最低。
而且在这樣节省使用CPU的情況下，它的效率表现还有中上以上的程度。

#### 2.3 ext3的性能这么低为什么当时绝大多数系统默认使用ext3

虽然Ext3性能不好(在日誌型文件系统中效率上算是最糟糕的) ，那为何还有那麼多人使用？
那是因为当时Ext3可以直接从Ext2升级，而不需要先备份数据，然后格式化后再把文件复制回去，
所以使用人数最多。但这也不能全然怪它，因为它为了和Ext2兼容，所以背负了很多的历史包袱。
若是以性能为考虑，则可以选择ReiserFS或XFS。若是系统资源不多，要使用最低的CPU使用率，
那麼可以选择JFS，因为它有著最好的性能资源比。

#### 2.4 各类文件系统性能大比拼

- SQL2005：
 相当于EXT3，对于一个写调用，文件系统代码立刻分配数据块的存放位置（先分配并立刻格式化），
 甚至是数据还会在cache中（内存中）存放一段时间才写回磁盘的情况，格式化分配的空间失败，
 写调用也会失败，分配空间 立刻格式化 数据缓存在内存中

- SQL2005以后：
 相当于EXT4，延迟分配，在调用写操作时，如果数据仅仅写到cache中（内存中），并不会立即分配块
 （先分配好空间但不会立即格式化，因为要预估磁盘是否有足够空间保存写入数据），
 而是等到真正向磁盘写入的时候才进行分配。这就使得块分配器有机会优化，组合这些分配的块（合并写入），
 分配空间 延迟格式化 数据缓存在内存中

- EXT3：
 立刻分配

- EXT4：
 延迟分配

##### 问题所在：
如果SQL Server运行在EXT4文件系统就有问题了，由于是延迟分配，
数据库不知道文件系统是否还有足够的磁盘空间装载写入的数据。  
一旦等到刷盘的时候才一次性分配，那么有可能造成数据丢失，数据库不能保存写入的数据，
而前端又已经通知数据已经写入的回复，数据库不可能等到刷盘的时候才通知前端数据是否能够写入成功。

- ext4：
 向前兼容ext3，但有可靠的checksumming in journal 功能。  
 在个人测试中，速度逼近ext2  
 和ext3类似，会浪费很多磁盘空间  
 加快了 fsck 的速度。  
 可在线调整，在线升级，在线碎片整理  

- reiserfs：
 速度快  
 和 ext3 一样，也支持 data journaling 功能。不過效率大幅下降。  
 有些目录是非同步的，不太适合于某些系统（像 postfix）上。  
 会占用较多CPU和内存  
 恢复能力较差，断电会找不回数据  
 挂载和卸载速度很慢，严重影响开机速度，开机挂载的时候会影响开机速度  
 偶尔出现Disk I/O 100% 超过 30 秒的事  
 主要开发者已经入狱，开发工作几乎停顿。  

- reiser4：
 改进了 reiserfs 的很多缺点，且速度比 reiserfs 更快！  
 主要开发者已经入狱，开发工作几乎停顿，不可能进入kernel了  

- xfs：
 在操作一些小文件的目录或者大量新增或删除文件或目录时，速度很快，
 不建议使用在/上在操作 > 200MB 的文件时有优势。  
 可在线重组碎片  
 时间使用长了，效率会下降得很严重  
 沒有 undelete 功能 。  
 有报告说明在强制关机甚至强制umount，文件可能因为损坏而难以恢复  
 所有文件系统中的 CPU Loading最小。  
 挂载和卸载速度极快  
 依然在开发维护中  

- jfs：
 CPU Loading较低  
 综合比较会比ext3快一些  
 修复能力跟ext3差不多  
 不太容易有碎片问题  
 挂载和卸载速度极快  
 可将journal放到另一个分区，不过操作有点麻烦  
 在删除大文件时速度很慢  
 IBM开发这个文件系统超过10年，但在Linux真正普及之前就已经停止开发，用的人不多  
 Debian Installer 默认就有 fsck.jfs  功能  

- zfs：
 号称终极文件系统，但因为授权问题而无法进入kernel中，因而经由fuse来支持zfs，
 所以速度很慢，在Linux上没有竞争力（转载者注：目前已经有原生的zfs for linux内核模块，
 但是由于授权原因没有进入主线内核，可由用户自行编译加载模块。ubuntu声称已经绕过授权问题，
 并在 ubuntu 16.04 开始内置支持了原生zfs for linux）。

- btrfs：
 基本上为了比美（转载者注：应该是“媲美”）zfs而开发出来的Linux终极文件系统
 支持一些先进的磁盘功能，例如磁盘快照，磁盘阵列，动态挂载等
 更可靠的 checksumming in journal 功能。
 对 SSD 做了最优化。
 可在线重组碎片

截止到这里，终于看到找到什么是Extends了，这对上面4个问题的处理跨越了很大一步。

截止到目前为止，我们对于上面遗留的4个问题也有了大概的了解和想法，再回头来看下上面的问题。

### 3. 问题1： the file is using extents …， 但为什么lsattr中目录为什么也有`-e`选项？

为什么目录也会显示-e -I问题，这个问题我觉得是man文档的准确性问题，
众所周知：Linux下一切皆文件。这里其想表述的是文件，即所有的文件都支持，
但为什么链接文件不支持，这里我们有留意到图中的软链是链接的目录，
我们再来看下是软链的文件是否能正常显示

```
# lsattr /etc/system-release
lsattr: Operation not supported While reading flags on /etc/system-release
```

发现软链的文件也是不行的，man文档及wiki也没有其任何介绍，有了解的朋友可以交流。  
（转载者注：个人理解，目录和文件均属于这里所说的file指的是文件系统上的文件，lsattr和chattr
用来列出和修改文件系统中存储的扩展属性，在这个意义上来说regular file和dir是具有一样意义的，
毕竟不管在哪个系统中，目录都是一种特殊类型的文件。但是软链接并没有自己的扩展属性，所以lsattr
和chattr是无效的，因为这些扩展属性对软链接压根没有意义，只需要知道软链接所指向文件的扩展属性即可。）  
（转载者再注：经过实验，不仅仅软链接，设备文件、命名管道文件、unix socket文件等等类型文件都
不支持lsattr/chattr，而不是像上一段原作者说的“即所有的文件都支持”，实际上仅仅只有
regular file和dir两种类型的文件支持而已。）

### 4. 问题2：什么是extents，扩展在这里是不好理解的？

`lsattr`中`-e` 是指`extents`，是指ext（2，3，4）系列文件系统中支持的`Extents`属性，
经常（转载者注：应该是“经过”）大量的搜索查找后，发现该属性有专门的介绍

> Ext3等文件系统采用间接块映射，主要针对大文件操作，现今科技的发展和技术的普及，
> 硬件的容量规模提升的非常快，当操作大文件时，大数据时， 效率极其低下。
> 比如一个 100MB 大小的文件，在 Ext文件系统中要建立 25,600 个数据块（每个数据块大小为 4KB）
> 的映射表。  
> 为解决该问题，Ext4 引入了现代文件系统中流行的 extents 概念，每个extent为一组连续的数据块，
> 上述文件则表示为“ 该文件数据保存在接下来的 25,600 个数据块中”，提高了不少效率。

所以`-e`是指文件系统中的文件或目录是否支持该特性，
该特性在现代操作系统中起到非常重要的作用。（转载者注：这个表述不是很准确，文末我另行总结）

### 5. 问题3：The I attribute is used by the htree program code, `htree`是什么？

因为man文档是介绍的是htree programe（转载者吐槽：人家说的是“htree program code”好不好，
能不能随便就把 “program code”短语拆开。。。），所以起初的我理所应当的理解为系统命令，
但经过验证后发现不是一个系统命令。

> yum whatprovides htree

问题到这里为止，我觉得该单词不够成我对该句的理解，所以当时对其也没有放太多心思，
不过后来发现这个想法是错误的！！

```
Btrfs: B-tree file system
```

其实是一个文件系统，大家可以在[btrfs文件系统wiki](https://btrfs.wiki.kernel.org/index.php/Main_Page)，
还有这里的[这里还有介绍](https://www.ibm.com/developerworks/cn/linux/l-cn-btrfs/index.html).

（转载者注：此处的两个链接在我转载的时候已经丢失。真正的带链接的原文似乎是在微信公众号上的，
但我没找到原文。于是我找了我认为适合这两个位置的链接擅自填上了。由于我对btrfs比较感兴趣，
也查过不少btrfs相关资料，因此我擅自认为我填的这两个链接并不会影响您阅读本文）

（转载者再注：此处关于`htree`，原文作者应该完全理解错了。这个`htree`指的是一种数据结构
“hashed tree”，是B-tree中的一种，在下面的问题4中有提及，但似乎没有引起原文作者注意。
因此由htree联想到B-tree再联想到btrfs这一文件系统，这一逻辑应该是错的，
`B-tree`和`htree`一样，只是一种数据结构，而btrfs中广泛应用了B-tree。
所以可以由btrfs联想到B-tree，但反过来由B-tree联想到btrfs从而引申出“htree其实是一个文件系统”
是行不通的。）

### 6. 问题4：indicate that a directory is being indexed using hashed trees。`indexed using hashed trees`被引用？

![lsattr /usr/; ll /usr/](/images/something-about-lsattr_-I_-e/03.jpg)

最初的理解是被软链索引过的目录会有`-I`的选项，我们来验证下，
从上面的这幅图执行`ll`命令返回结果的第二列数字看，所有目录都有被链接，
但`lsattr`命令返回的结果却并非所有的目录均有属性I。所以该选项只能猜测并验证了。
进一步查看`chattr`命令后发现，该属性`It may not be set or reset using chattr(1)`。
该选项的概念也只能猜测：

>系统对特有的常被引用或其它程序调用的目录添加该属性，以提升速度和提高效率。

做一个简单的验证。

1. 自己创建的目录默认没有I属性

2. 这些常见的lib库及经常会被调用的系统文件会被添加`I`属性。
```
----------I--e- /lib64
----------I--e- /etc
-------------e- /home
-------------e- /lib
----------I--e- /lib64
----------I--e- /sbin
```

### 7. 附录

#### 什么是第二代扩展文件系统

第二代扩展文件系统（英语：second extended filesystem，缩写为ext2）

#### 7.1 FUSE文件系统是什么

FUSE文件系统：用户空间文件系统（Filesystem in Userspace，简称FUSE）是操作系统中的概念，
指完全在用户态实现的文件系统。目前Linux通过内核模块对此进行支持。一些文件系统如ZFS，
glusterfs和lustre使用FUSE实现。windows下的NTFS也是（转载者注：指的是NTFS在Linux下的
ntfs-3g实现）。

#### 7.2 fuse文件 工作原理

![fuse文件系统工作时需要调用到的模块](/images/something-about-lsattr_-I_-e/04.jpg)
fuse文件系统工作时需要调用到的模块

因为是用户层发起的请求，所以kernel层面 需要为用户提供api接口，
所以在整个过程会有大量的kernel态到user态的上下文切换，整个过程可想而知，整体效率也可想面知。

```
struct fuse_operations {
    int (*getattr) (const char *, struct stat *);
    int (*readlink) (const char *, char *, size_t);
    int (*getdir) (const char *, fuse_dirh_t, fuse_dirfil_t);
    int (*mknod) (const char *, mode_t, dev_t);
    int (*mkdir) (const char *, mode_t);
    int (*unlink) (const char *);
    int (*rmdir) (const char *);
    int (*symlink) (const char *, const char *);
    int (*rename) (const char *, const char *);
    int (*link) (const char *, const char *);
    int (*chmod) (const char *, mode_t);
    int (*chown) (const char *, uid_t, gid_t);
    int (*truncate) (const char *, off_t);
    int (*utime) (const char *, struct utimbuf *);
    int (*open) (const char *, struct fuse_file_info *);
    int (*read) (const char *, char *, size_t, off_t, struct fuse_file_info *);
    int (*write) (const char *, const char *, size_t, off_t,struct fuse_file_info *);
    int (*statfs) (const char *, struct statfs *);
    int (*flush) (const char *, struct fuse_file_info *);
    int (*release) (const char *, struct fuse_file_info *);
    int (*fsync) (const char *, int, struct fuse_file_info *);
    int (*setxattr) (const char *, const char *, const char *, size_t, int);
    int (*getxattr) (const char *, const char *, char *, size_t);
    int (*listxattr) (const char *, char *, size_t);
    int (*removexattr) (const char *, const char *);
};
```

### 8. 扩展阅读

<https://en.wikipedia.org/wiki/Chattr#lsattr_description>  
<https://zh.wikipedia.org/wiki/FUSE>  
<https://en.wikipedia.org/wiki/B-tree#cite_note-1>  
<https://en.wikipedia.org/wiki/Btrfs>  
<http://tetralet.luna.com.tw/index.php?op=ViewArticle&articleId;=214&blogId;=1>  
EXT4介绍：<http://baike.baidu.com/view/2220807.htm>  
XFS介绍：<http://baike.baidu.com/view/1222157.htm>  
JFS介绍：<http://baike.baidu.com/view/1494218.htm>  

### 9. 结束语

到这里，遇到的问题在我看来算已经解决了，精力和工作方向性原因，个人无法再投入过多精力在该问题上，
如有错误或其它见解的朋友请一定留言联系我，在问题解决的过程中有那么一点点的想法，简单分享一二：

1. 国内多数blog依旧停留在抄袭的层面，多数精华blog依赖是老一辈经10年左右或更前的blog有自己的研究成果，
此后少有blog是自己的研究成果
2. ext2和第二代扩展文件系统的关系
3. 这个问题体现的不仅仅是一个知识点，其涉及到文件系统发展史。因为该命令日常企业应用较少，
所以这是鲜有技术人去研究的原因。
但还是呼吁国内作学问的人和机构用更多专业的精神和负责任的心态去面对每个提问。

******

原文地址：<http://chuansong.me/n/481566151558>  
原文貌似是发布在微信公众号“运维部落”的文章，因为我懒，没找更原始的原文。。。所以：
更原始的原文地址：[暂缺](暂缺)

******

文中原作者在第5、6节标题中对HTree的理解稍有偏差。

参见：<https://en.wikipedia.org/wiki/Ext4> 中，对ext4的特性之一
“Unlimited number of subdirectories”的说明：

> To allow for larger directories and continued performance, ext4 turns on HTree indexes (a specialized version of a B-tree) by default.

我大致翻译如下（英语渣）：

> 为了支持超大目录（包含超多文件的目录），并且维持性能，ext4 默认启用了 HTree 索引。
> HTree 是一个特殊版本的 B-Tree。 

我们要在文件系统中找到一个文件或者目录，首先需要找到这个文件或者目录对应的 `inode`。  
而当目录较大时，文件系统要定位一个文件所在的 inode 就比较辛苦了。因此为了加快访问文件或者目录的速度，
ext4 默认对目录启用了索引，
而这个索引就存放在由[HTree](https://en.wikipedia.org/wiki/Htree)（hashed tree）
这一数据结构所建立的索引中。  
学过C语言的大多知道两个名词，多叉树和hash。HTree 就包含了对它们的应用。  
有了 HTree 做的索引后，对部分文件的访问就能加快。但是我们都知道，多叉树的体积增长之后，
势必就会降低索引效率，因此 ext4 不可能对所有文件都进行索引。

看到这里，你肯定就明白了。`lsattr`显示的结果中，
**出现`I`其实就是表示这个文件被文件系统内的 HTree 索引了。**  
原文作者其实已经找到答案了：

> indicate that a directory is being indexed using hashed trees

没错，答案就在原文第6节的标题中。原文作者似乎是把“index”理解为了“引用”，因此就纠结于“软链接”。  
而“index”实际上是“索引”的意思，也就是文件系统对文件的索引，和软链接几乎没有关系。
（为啥说是“几乎”呢？因为你访问一个软链接的时候，软链接想要找到其对应的实际文件，
还是有可能去访问 HTree 索引，所以是“几乎”）。

因此，关于 Linux 文件的 attr 中，`I` 和 `e` 的总结如下：

1. `e`属性：原文作者讲述得比较清楚了，但`e`并不是表示“文件系统中的文件或目录是否**支持**该特性”，
而是“文件系统中的文件或目录是否**启用了**该特性”
2. `I`属性：标记了`I`属性的文件或者目录被文件系统中的 HTree 索引给收录了，可通过该索引加速访问。
另外，根据维基百科中`Htree`词条的介绍，如果一个文件需要在inode中存储超过4个“extents”的话，
HTree index 也会被启用。

到这里，这个问题应该算是真正结束了。如果错误，请在下方的多说评论区补充，反正我也不会看的。

