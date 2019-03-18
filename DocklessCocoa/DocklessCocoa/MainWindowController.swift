//
//  MainWindowController.swift
//  DocklessCocoa
//
//  Created by chen he on 2019/3/18.
//  Copyright © 2019 chen he. All rights reserved.
//

import Cocoa

class MainWindowController: NSWindowController {
    
    static let shared = NSStoryboard.main?.instantiateController(withIdentifier: "MainWindowController") as? MainWindowController

    override func windowDidLoad() {
        super.windowDidLoad()
    
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }

}
