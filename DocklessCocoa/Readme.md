---
title: "Mac 平台上那些 Dockless 的 App 都是如何实现的？"
date: 2019-03-13T17:29:54+08:00
lastmod: 2019-03-15T11:01:23+08:00
categories: ["macOS"]
tags: ["Dock","Cocoa", "Dockless", "Menu", "Agent"]
---


在 Mac 平台你判断一个工具好用不好用，吸引不吸引你，其中 Menu Only 也是吸引你的一点，不需要常驻 Dock 栏，在多 workspace 的时候也不影响正常使用。尤其是针对一些需要便捷性要求比较高的 Application， menu bar 的功能必不可少。本文主要简单介绍关键的几个操作，做个记录。

<!-- more -->

# 介绍

以 [Shimo](https://www.shimovpn.com/) 这个 App 举例，

![Shimo](https://i.imgur.com/vT7EEVK.png)

在其设置选项卡中能看到 Show Shimo in 的选项菜单，其中有三项： 

1. Menubar only
2. Dock only
3. Menubar & Dock

![Shimo Menu](https://i.imgur.com/WywIVkV.png)

这也是常见的 Cocoa 应用的模式支持，很多常见的 App 都支持，比如 DayOne，Dash，Todoist 等。

![Dash](https://i.imgur.com/ioUvpNw.png)
![Todoist](https://i.imgur.com/ORYAEcZ.png)

其实核心功能有两点：
1. 可以显示或者隐藏 Dock 图标； 
2. 可以显示或者隐藏 Menu 菜单这两者的组合。

# 核心步骤

## Dock

普通的 Cocoa Application 创建之后，默认都是 Dock 上展示的，如果想隐藏 Dock 图标，首先它需要有这个能力，这个能力是通过 info.plist 文件中的 Key 来指定的，这个 Key 就是 `LSUIElement`，我们将其值设置为 true

``` plist
	<key>LSUIElement</key>
	<true/>
```

在可视化展示 plist 的时候能看到针对该 Key 的描述是标识 Application is agent(UIElement)

![plist](https://i.imgur.com/ef3w8TR.png)

之后，再次打开 App，会发现 Dock 上已经看不到该应用的图标了，这就是 UIElement 的作用，其实际上就是声明我们的 Cocoa App 是 UIElement（也即 agent） application，Dock 不显示，允许有一定的用户界面。在方法 `TransformProcessType` 的头文件中能看到 Cocoa Application 的几种常见类型：

``` Swift
/*
 *  TransformProcessType()
 *  
 *  Summary:
 *    Changes the 'type' of the process specified in the psn parameter.
 *     The type is specified in the transformState parameter.
 *  
 *  Discussion:
 *    Given a psn for an application, this call transforms that
 *    application into the given type.  Foreground applications have a
 *    menu bar and appear in the Dock.  Background applications do not
 *    appear in the Dock, do not have a menu bar ( and should not have
 *    windows or other user interface ).  UIElement applications do not
 *    have a menu bar, do not appear in the dock, but may in limited
 *    circumstances present windows and user interface. If a foreground
 *    application is frontmost when transformed into a background
 *    application, it is first hidden and another application is made
 *    frontmost.  A UIElement or background-only application which is
 *    transformed into a foreground application is not brought to the
 *    front (use SetFrontProcess() after the transform if this is
 *    required) nor will it be shown if it is hidden ( even if hidden
 *    automatically by being transformed into a background-only
 *    application ), so the caller should use ShowHideProcess() to show
 *    the application after it is transformed into a foreground
 *    application. Applications can only transform themselves; this
 *    call cannot change the type of another application.

extern OSStatus 
TransformProcessType(
  const ProcessSerialNumber *        psn,
  ProcessApplicationTransformState   transformState)          AVAILABLE_MAC_OS_X_VERSION_10_3_AND_LATER;  
```

上方的注释写的非常清楚，我们日常的 Cocoa Application 主要包含三种类型：

1. Foreground applications， 拥有一个 menu bar，并且会在 Dock 上出现；
2. Background applications，Dock 上不存在并且没有 menu bar，并且不应该存在任何 UI 交互界面（建议）
3. UIElement applications 有和 Background applications 相同的情况，但是允许在某些情况下展示用户界面。

那上方这个方法 `TransformProcessType` 就是进行这几种模式切换的。


``` Swift
func toggleDock(show: Bool) -> Bool {

    // ProcessApplicationTransformState
    let transformState = show ? 
    // show to foreground application 
    // or not show to background application
        ProcessApplicationTransformState(kProcessTransformToForegroundApplication) 
    : ProcessApplicationTransformState(kProcessTransformToUIElementApplication)

    // transform current application type.
    var psn = ProcessSerialNumber(highLongOfPSN: 0, lowLongOfPSN: UInt32(kCurrentProcess))
    return TransformProcessType(&psn, transformState) == 0
}
```

这里实际上还有一种方案也是很多开发者选用的方案，通过指定 App 的`ActivationPolicy`来实现的，核心的 API 是 `setActivationPolicy`:

``` Swift
    /* Attempts to modify the application's activation policy.  In OS X 10.9, any policy may be set; prior to 10.9, the activation policy may be changed to NSApplicationActivationPolicyProhibited or NSApplicationActivationPolicyRegular, but may not be changed to NSApplicationActivationPolicyAccessory.  This returns YES if setting the activation policy is successful, and NO if not.
     */
    @available(OSX 10.6, *)
    open func setActivationPolicy(_ activationPolicy: NSApplication.ActivationPolicy) -> Bool

```

而针对 ActivationPolicy 的详细解释也可以在其头文件注释中看到不同的 activation policy 意味着什么。

``` Swift
   /* The following activation policies control whether and how an application may be activated.  They are determined by the Info.plist. */
    public enum ActivationPolicy : Int {
        /* The application is an ordinary app that appears in the Dock and may have a user interface.  This is the default for bundled apps, unless overridden in the Info.plist. */
        case regular

        /* The application does not appear in the Dock and does not have a menu bar, but it may be activated programmatically or by clicking on one of its windows.  This corresponds to LSUIElement=1 in the Info.plist. */
        case accessory
        
        /* The application does not appear in the Dock and may not create windows or be activated.  This corresponds to LSBackgroundOnly=1 in the Info.plist.  This is also the default for unbundled executables that do not have Info.plists. */
        case prohibited
    }
```

实际上不同的 activation policy 和 Info.plist 文件中写入不同元素的效果是对等的。regular policy 的应用就是常规引用的形式，会出现在 Dock 上，accessory policy 的应用就是指定当前应用为 agent，不再 Dock 出现。

显示或者隐藏 Dock 的功能就可以通过切换当前的激活策略（activation policy来实现，如下代码所示：

``` Swift
func toggleDock2(show: Bool) -> Bool {
        return show ?
               NSApp.setActivationPolicy(.regular)
             : NSApp.setActivationPolicy(.accessory)
    }
```

## Menu bar

一旦我们可以通过以上形式隐藏 Dock 图标之后，我们还需要为应用加上菜单栏按钮，具体做法是通过 `NSStatusItem` 这个类，其代表一个系统菜单栏上的条目。具体操作如下：



``` Swift
let statusItem = NSStatusBar.system.statusItem(withLength:NSStatusItem.squareLength)
```

之后系统会在 Menu bar 上创建一个选项按钮，不过我们还需要设置该菜单选项的 UI，如下设置：

``` Swift
if let button = statusItem.button {
            button.image = NSImage(named:NSImage.Name("ic_dock"))
            button.action = #selector(doWhatYouWantToDo(_:))
        }
```

此时应用启动之后菜单栏就会有图标展示了，详细可以参考 Raywenderlich 家的教程，不再赘述。 [[Menus and Popovers in Menu Bar Apps for macOS](https://www.raywenderlich.com/450-menus-and-popovers-in-menu-bar-apps-for-macos)]


# 参考文献

1. [Show/Hide dock icon on macOS App](https://medium.com/@jackymelb/show-hide-dock-icon-on-macos-app-3a59f7df282d)
2. [NSStatusItem](https://developer.apple.com/documentation/appkit/nsstatusitem)
3. [Menus and Popovers in Menu Bar Apps for macOS](https://www.raywenderlich.com/450-menus-and-popovers-in-menu-bar-apps-for-macos)