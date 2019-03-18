//
//  MenuContentViewController.swift
//  DocklessCocoa
//
//  Created by chen he on 2019/3/18.
//  Copyright © 2019 chen he. All rights reserved.
//

import Cocoa

extension NSStoryboard.SceneIdentifier {
    
    static let menuContentViewController = "MenuContentViewController"
    
}

class MenuContentViewController: NSViewController {
    
    static let shared = NSStoryboard.main?.instantiateController(withIdentifier: .menuContentViewController) as? MenuContentViewController

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    @IBAction func backToDock(_ sender: Any) {
        AppMode.toggleDock(show: true)
    }
    @IBAction func showMainWindow(_ sender: Any) {
        MainWindowController.shared?.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
