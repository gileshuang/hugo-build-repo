+++
Tags = ['Linux', 'socks5', 'ssh', 'git']
Categories = ['运维向']
title = "[整理]为 git 和 ssh 设置 socks5 协议的代理"
date = "2017-09-28T14:58:28+08:00"
+++

由于某魔法结界的存在，我们在从某全球最大同性社交网站下载项目源码或者提交代码到该罪恶的社交网站时，
经常会出现各种异常。那么，我们能不能施展魔法，让我们的 git/ssh 通过魔法上网呢？  
（本文的配置并不是给浏览器用的，不适合用来给浏览器魔法上网。本文重点在 git/ssh，需要魔法上网的请绕道。）

<!--more-->

******

> 本文假设你已经有了一个 socks5 协议的代理了。  
> 关于怎么设立 socks5 协议的代理，这里就不赘述了，到处都有介绍，这里说多了我怕我会被魔法封印。  
> 本文以 Linux 环境下为准（我使用的是 ArchLinux）。
Windows 下的 git-bash 同理，但未经验证。  

#### 1. 需要解决什么问题？

- 某全球最大同性社交网站的 git clone/pull/push 操作主要使用 ssh、https 协议。
- 因为某魔法结界的存在，上述网站经常各种抽风（无论啥协议都抽风）。
- 某些网站虽然没受结界影响，但因网站自身问题或者各种水土不服，git 操作的速度特别慢，
比如 [git.kernel.org](https://git.kernel.org)。
- 首先知道，git 支持这些协议：ssh、http/https、git。
- 你使用 ssh 直接登陆你自己的某台服务器会出现问题，但你理论上能通过你的 socks5 代理登陆你那台服务器，
只是你不知道应该如何配置 ssh。

#### 2. 前置环境

- 你熟悉基础的 ssh、git 操作。
- 你已经通过某些不可描述的方案，在本地建立好了 socks5 的代理了，这里以 `127.0.0.1:1081` 为例。
- 你的 socks5 能够访问你的目标服务，比如能够访问魔法结界外面的同性社交网站或其它类似网站。
- 已经安装了 ssh、git 客户端。
- 安装了 ncat 命令（ArchLinux 中，该命令来自 nmap 包）。

#### 3. 为 ssh 客户端或者使用 ssh 协议的 git 配置代理

在你用户目录下，建立 `.ssh/config`，在里面添加如下配置：

```
# 将这里的 User、Hostname、Port 替换成你需要用 ssh 登录的服务器的配置。
# Host 可以认为像是书签一样的东西，当你用 Host 指明的字符串代替你服务器的 IP/域名 时，
# 便会应用该节点下的配置。当然你也可以将 Host 和 Hostname 设置成一样。
Host yourserver.com
        User    someone
        Hostname        yourserver.com
        Port    22
        Proxycommand    /usr/bin/ncat --proxy 127.0.0.1:1081 --proxy-type socks5 %h %p

# 如果是给某同性社交网站用的（走 ssh 协议），可以直接使用该配置。
# 其它类似网站的话，替换掉域名（ Host/Hostname）即可。
# 可以看出，ssh 协议的 git 客户端，配置与 ssh 一模一样。
# 需要注意的是这里的 User 应该是 git，而不是你在该网站上注册的用户名。
# （虽然有些提供 git 仓库托管的网站会用其它用户名，这种情况根据网站配置。）
Host github.com
        User    git
        Hostname        github.com
        Port    22
        Proxycommand    /usr/bin/ncat --proxy 127.0.0.1:1081 --proxy-type socks5 %h %p
```

该方式的配置中，如果 Host 设置为 `*`，那么 `Host *` 对应的配置会被应用到所有没有独立配置
的 ssh 连接中，包括使用了 ssh 协议的 git 操作。

#### 4. 为使用 http/https 协议的 git 配置代理

针对 git 全局开启 http/https 协议代理：

```
git config --global http.proxy 'socks5://127.0.0.1:1081'
git config --global https.proxy 'socks5://127.0.0.1:1081'
```

这是针对全局开启，一般在 `git clone` 时用处较大。
针对单个仓库的话，在 clone 完成后，进入仓库目录下设置，去掉 `--global` 参数即可。

#### 5. 为使用 git 协议的 git 配置代理

建立 `/opt/bin/socks5proxywrapper` 文件，并将该文件设置为可执行权限，文件内容如下：

``` bash
#!/bin/sh
/usr/bin/ncat --proxy 127.0.0.1:1081 --proxy-type socks5 "$@"
```

配置 git，使其全局使用该代理：

```bash
git config --global core.gitProxy "/opt/bin/socks5proxywrapper"
```

也可针对特定域名启用代理，如：

```bash
git config --global core.gitProxy '"/opt/bin/socks5proxywrapper" for git.kernel.org'
```

临时启用代理而不想将配置保存下来的话，可以使用设置环境变量的方法：

```bash
export GIT_PROXY_COMMAND="/opt/bin/socks5proxywrapper"
```

#### 6. 参考链接

本文只是摘选了其中一部分配置。  
不管是哪一个协议，git 的代理都有非常多的方式可以配置，灵活性也很大。这里摘选的大部分是比较简单
粗暴的配置，而且响应主题：使用 socks5 协议。  
如果有兴趣，可以 `man git-config` 看看，或者 google 上找找别人的经验之谈。  
这里给出我写本文的几个参考链接：

<https://blog.fazero.me/2015/07/11/%e7%94%a8shadowsocks%e5%8a%a0%e9%80%9fgit-clone/>  
<https://segmentfault.com/q/1010000000118837>  

