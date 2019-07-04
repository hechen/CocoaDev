---
title: "LetsMove 中的几个点"
date: 2019-07-04T1:19:10+08:00
categories: ["macOS"]
tags: ["SourceCode","LetsMove","LaunchdDaemon","Shell"]
---

当我们从网络上下载某个 mac app 之后，一般都会默认在 Downloads 目录里，但是某一些 App 是需要放置到 Application 目录才行，最常见的就是自更新功能是受到当前所处目录的限制的，这时候很多下载到本地的 .app 文件打开之后都会弹出提示框，让用户选择是否移动到 Applications 目录，LetsMove 就是大部分 mac app 参考或者集成的开源库，封装了这套逻辑。

![LetsMove](https://i.imgur.com/99z1BQf.png)

这个库已经好多年了，最近的一次 Commit 是 2017年，其中有几个点可以学习借鉴。

### 大致思路

虽然叫 Move，实际上是先行 Copy 一份当前的 App Bundle 到 Application 目录，然后杀掉自己并删除源目录的 App 文件。

1. Move to Applications Folder 确认之后
2. 复制当前 App 文件到 /Applications 目录中
3. 删除当前已经打开 App （Mac 上是可行的，不同于 Windows，不存在占用文件句柄的情况）
4. 执行子进程执行重启过程，具体后文会讲。

### 权限获取（提权）

检查文件路径是否可以写入的方法是 NSFileManager 的 isWritableFileAtPath ，如果返回 false，LetsMove 会主动进行权限获取。

获取权限所使用的接口是 AuthorizationExecuteWithPrivileges，该接口实际在 OSX 10.7 Lion 之后就已经标记废弃了，但是一直到目前的 macOS 10.14 还一直可以使用。

而作者为了避免苹果直接移除该代码导致提权接口不可用，使用了动态查找方法的形式，利用 dlsym 查找方法指针来获取，从而避免如果完全移除该方法导致功能不稳定的情况发生。

![Privileges Acquirement](https://i.imgur.com/LPQw1VR.png)


通过该方法获取了 rm 和 cp 命令在指定目录的权限，这个过程中用户会收到输入 Admin Password  的提示的。

当然现有的提权官方有建议使用一个 helper 程序来负责或者使用 Service Management framework 来做，这两者在做 App 自启动的时候已经了解过了，确实不如这一个方法来的简单。有兴趣可以去看下 LaunchdDaemon 这个东东。

> Use a launchd-launched helper tool and/or the Service Mangement framework
for this functionality.

### Relaunch

Relaunch 方法是将应用移动到 /Applications 目录后的后续动作。

![Relaunch Code](https://i.imgur.com/VnRvggh.png)



其中 NSTask 重启进程的 Shell 脚本如下：

![Relaunch Shell Script](https://i.imgur.com/hBftQB9.png)

  
该方法涉及两个主要职能：

1. 将拷贝到 /Applications 目录下的 App 文件增加扩展属性
2. 执行 Shell 脚本，杀掉当前父进程，并重启刚刚 Copy 到 /Applications 目录下的 App 文件

关于第一点，使用 kill 命令来杀掉当前主进程，但是使用的是 kill -0，不是任何有效的 signal，关于该命令只是查询当前你是否有权限来做 kill 这件事情，这一块也没看明白该方法的意义在哪里，知道的同学可以告知下；

关于第二点，用到了 xattr 命令，该命令是用来针对文件的扩展属性做操作的。上方的命令就是为当前已经移动到 /Applications 目录下的 App 文件去除 com.apple.quarantine 属性。不知道大家记得不，从某些网站下完 App 之后，比如 Github Desktop 客户端，打开会提示如下窗口：

![Download from Web](https://i.imgur.com/i9qfEtf.png)


这个是 macOS 自身的安全校验提示，当然一般从 web 下载的 App 本身都会被加上 com.apple.quarantine 的扩展属性，这里是移除了该属性，防止执行了 open 之后弹出该提示叨扰用户。

## References

1. [What does `kill -0` do?](https://unix.stackexchange.com/questions/169898/what-does-kill-0-do)
2. [Extended file attributes - Wikipedia](https://en.wikipedia.org/wiki/Extended_file_attributes)