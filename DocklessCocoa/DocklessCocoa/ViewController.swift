//
//  ViewController.swift
//  DocklessCocoa
//
//  Created by chen he on 2019/3/18.
//  Copyright © 2019 chen he. All rights reserved.
//

import Cocoa
import ApplicationServices

enum CocoaMode: Int {
    case MenuAndDock
    case Dockless  // menu only
    
    init(identifier: String) {
        if identifier == "Menu Only" {
            self = .Dockless
        }
            
        else if identifier == "Menu And Dock" {
            self = .MenuAndDock
        } else {
            
            self = .MenuAndDock
        }
    }
    
    var identifier: String {
        switch self {
        case .MenuAndDock: return "Menu And Dock"
        case .Dockless: return "Menu Only"
        }
    }
}


class ViewController: NSViewController {
    
    @IBOutlet weak var CocoaModeButton: NSPopUpButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        CocoaModeButton.selectItem(at: AppDefault.shared.mode.rawValue)
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    @IBAction func modeChanged(_ sender: Any) {
        if let menuItem = CocoaModeButton.selectedItem?.title {
            let mode = CocoaMode(identifier: menuItem)
            switch mode {
            case .MenuAndDock:
                AppMode.toggleDock(show: true)
            case .Dockless:
                AppMode.toggleDock(show: false)
            }
            AppDefault.shared.mode = mode
        }
    }
}


class AppMode {
    
    
    @discardableResult
    class func toggleDock(show: Bool) -> Bool {
        
        #if POLICY
        
        return toggleDock_2(show: show)
        
        #else
        
        return toggleDock_1(show: show)
        
        #endif
        
    }
    
    
    @discardableResult
    class func toggleDock_1(show: Bool) -> Bool {

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
    
    @discardableResult
    class func toggleDock_2(show: Bool) -> Bool {
        return show ?
            NSApp.setActivationPolicy(.regular)
            : NSApp.setActivationPolicy(.accessory)
    }
}

class AppDefault {
    static let shared = AppDefault()
    
    struct Keys {
        static let currentApplicationMode: String = "app.chen.osx.cocoaMode"
    }
    
    var mode: CocoaMode {
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: Keys.currentApplicationMode)
        }
        get {
            let value = UserDefaults.standard.integer(forKey: Keys.currentApplicationMode)
            return CocoaMode(rawValue: value) ?? .MenuAndDock
        }
    }
}
