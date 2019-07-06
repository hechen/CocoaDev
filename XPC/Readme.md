---
title: "XPC Services"
date: 2019-07-04T1:01:10+08:00
categories: ["macOS"]
tags: ["XPC"]
---

## 关于 XPC

因为最近在做的工作涉及到这一块，就大致的记录一下，针对 XPC 技术也做个总结。

XPC 是 macOS 上一种进程间通信的技术统称，其使得我们可以将 Mac 应用的功能模块拆分成不同的多进程模式，关于进程之间的通信也被系统封装完整了，你只需要按照既定的模式做即可。其带来的最大的好处是

1. 提高 App 自身的稳定性
2. 进行权限隔离

拿我目前在做的工作来讲，确实有针对以上这两点的需求。上层业务通过执行脚本命令获取执行结果，执行脚本命令使用的就是 NSTask，大概结构如下：

![NSTask Layer](https://i.imgur.com/8glAV2u.png)

对于执行 NSTask 的这层命令行执行模块来讲，拆分到独立的进程中使得安全性得以提高，即使 XPC 进程挂掉，一般情况下再次向 XPC 通信，系统会自行恢复启用新的 XPC 进程，而主应用无感知。

## XPC 架构

在 Apple 官方文档中有如下图，很清楚的展示了整个 NSXPC 的架构。

主应用和 XPC Service 之间是通过 NSXPCConnection 对象保持通信的，其通信接口由 Protocol 定义，然后暴露给外界一个符合了该协议的对象。

所有的 XPC Service 本身是由系统级别程序 launchd 来管理和维护的。

![NSXPC_intro_2x-337fb6a3-4df5-47b3-a322-e52c48905753](https://i.imgur.com/OdvfZk4.png)

## 开发过程

整体上主应用和 XPC 通信是标准的 Client-Server 模式。客户端询问 Server 端数据，Server 端应答即可。这之间的数据序列化完全交由系统管理。

### 具体步骤

#### 新建 XPC Service 的 Target

![Add New XPC Service Target](https://i.imgur.com/BNFRaG7.png)

![Input Target Info](https://i.imgur.com/AyEq9Iv.png)


这里要说一点，Xcode 提供的 XPC Service 创建的时候是没有语言选项的，默认都是创建的 Objective-C 的样板文件，但是你是可以把所有的代码文件删除，然后建立 main.swift 来写的，一样能够开发。

#### 建立 Listener，监听连接

实际上，当你建立完毕 Targe 之后，系统默认生成的文件里已经将对应的代码大致过程已经通过注释和代码列出来了。我将这部分逻辑在 Swift 文件里也写了出来，如下：

![NSXCListener](https://i.imgur.com/o3gCND7.png)


每个 Service 会启动 NSConnectionListener，其代理方法是 NSXPCListenerDelegate，一旦主应用发起连接，该代理方法就会启动来做连接前的准备，而代理方法中的主要逻辑就三点：

1. 告诉 Connection 对象，Service 暴露的接口（协议）；
2. 传递给 Connection 对象一个符合了前面协议的对象；
3. 启动连接；
4. 返回是否允许本次连接建立；

其中 ServiceDemo 就是具体实现接口的对象。

#### 主应用发起连接

一般会在 App 启动之后启动连接，具体步骤如下，

1. 创建 NSXPCConnection 对象，指定连接哪个 Service 
2. 指定使用哪个协议接口（Protocol 的 Membership 需要主应用和 XPC Service 的Targe 共享）
3. resume

![Main Application](https://i.imgur.com/3UTQgK6.png)


但是此时 Service 里的监听实际上还未执行，直到你发起第一次 Request。向 XPC Service 发起动作的具体就是从刚刚创建的 NSXPCConnection 中获取对应的接口以及执行该接口来和 Service 交互。

![Request](https://i.imgur.com/9vACIeA.png)


整体过程如 Apple 文档里的图示过程，

![NSXPC_connection_2x-38a1e530-7c34-400b-a39b-eca9eaadbe22](https://i.imgur.com/BWf2G3l.png)



### 需要注意的几点

- NSXPCInterface 定义的方法回调只能有一个 Block，如果多于一个就会报异常。

```
XPCDemo[46250:3466789] NSXPCInterface: Only one reply block is allowed per selector (XPCDemo.DragonServiceProtocol / fireWithTimes:withSuccess:withFailure:)
```

- 关于一次 Request 通信多次 Response

类似于下载任务要获取下载进度的问题，在迁移 NSTask 执行层的过程中，面临的一个需求是针对 XPCService 端 NSTask 执行过程中的持续性的输出都要能够回调给 Client 端，而 Reply 回调只能响应一次。

我们在主应用端希望能够通过一个 Block 不断获取当前最新的数据，可是，不幸的是，XPC 并不支持如此。比如，我们希望能够通过回调实时获取状态。

![Run Command with multiple replies](https://i.imgur.com/x2qwpVP.png)

具体可以参考 [https://forums.developer.apple.com/thread/35731](https://forums.developer.apple.com/thread/35731) 论坛中 Apple 人员的回复，总结起来两点：

1. Client 以及 Service 自行维护状态，将一次请求多次回调，拆分为多次请求多次回调即可；
2. Client 转移要交付的第三方给 Service 直接交互（一般比如 API ）

### References

1. [Creating XPC Services](https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/CreatingXPCServices.html)
2. [XPC · objc.io](https://www.objc.io/issues/14-mac/xpc/)
3. [XPC...Can't call a reply block multiple times? |Apple Developer Forums](https://forums.developer.apple.com/thread/35731)