//
//  AppDelegate.swift
//  DocklessCocoa
//
//  Created by chen he on 2019/3/18.
//  Copyright © 2019 chen he. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    // create status item on the menu bar
    let statusItem = NSStatusBar.system.statusItem(withLength:NSStatusItem.squareLength)
    
    let popover = NSPopover()
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        
        // adjust status item's UI
        if let button = statusItem.button {
            button.image = NSImage(named:NSImage.Name("ic_dock"))
            button.action = #selector(doWhatYouWantToDo(_:))
        }
        
        popover.contentViewController = MenuContentViewController.shared
        
        // recover from last cocoa mode.
        switch AppDefault.shared.mode {
        case .MenuAndDock:
            // need show main window.
            MainWindowController.shared?.window?.makeKeyAndOrderFront(nil)
            AppMode.toggleDock(show: true)
        case .Dockless:
            AppMode.toggleDock(show: false)
        }
    }
    
    @objc
    func doWhatYouWantToDo(_ sender: Any) {
        print("Menu Bar Button Clicked.")
        
        if popover.isShown {
            
            // hide
            popover.performClose(sender)
            
        } else {
            
            // show
            if let button = statusItem.button {
                popover.show(relativeTo: button.frame, of: button, preferredEdge: NSRectEdge.minY)
            }
        }
    }
}

