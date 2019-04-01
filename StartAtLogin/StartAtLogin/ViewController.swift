//
//  ViewController.swift
//  StartAtLogin
//
//  Created by chen he on 2019/4/1.
//  Copyright © 2019 chen he. All rights reserved.
//

import Cocoa
import ServiceManagement

class ViewController: NSViewController {
    
    @IBOutlet weak var startAtLoginButton: NSButton!
        
    lazy var launchHelperIdentifier: String = {
        return "app.chen.osx.demo.StartAtLoginLauncher"
    }()
    
    var launchAtStartup: Bool {
        get {
            /// Use it as long as you can. Until there is a replacement.
            let jobs = SMCopyAllJobDictionaries(kSMDomainUserLaunchd).takeRetainedValue() as? [[String: AnyObject]]
            return jobs?.contains(where: { $0["Label"] as! String == launchHelperIdentifier }) ?? false
        }
        set {
            if !SMLoginItemSetEnabled(launchHelperIdentifier as CFString, newValue) {
                print("Set up login item failed.")
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        // check whether launch helper is in LoginItems list or not.
        // remember that the identifier is helper's
        startAtLoginButton.isOn = launchAtStartup
    }
    
    @IBAction func startAtLogin(_ sender: Any) {
        launchAtStartup = startAtLoginButton.isOn
    }
    
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
}

