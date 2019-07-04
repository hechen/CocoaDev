//
//  AppDelegate.swift
//  XPCDemo
//
//  Created by chen he on 2019/7/3.
//  Copyright © 2019 chen he. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {



    var dragonService: NSXPCConnection?
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        dragonService = NSXPCConnection(serviceName: "app.chen.maxos.DragonService")
        dragonService?.remoteObjectInterface = NSXPCInterface(with: DragonServiceProtocol.self)
        dragonService?.invalidationHandler = {
            print("Dragon XPC Service Invalidated.")
        }
        dragonService?.interruptionHandler = {
            print("Dragon XPC Service Interrubpted.")
        }
        dragonService?.resume()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}

