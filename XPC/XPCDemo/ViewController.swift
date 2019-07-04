//
//  ViewController.swift
//  XPCDemo
//
//  Created by chen he on 2019/7/3.
//  Copyright © 2019 chen he. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    
    
    @IBOutlet weak var infoLabel: NSTextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    @IBAction func fly(_ sender: Any) {
        guard let appDelegate = NSApp.delegate as? AppDelegate,
            let dragonObject = appDelegate.dragonService?.remoteObjectProxy as? DragonServiceProtocol else { return }
        
        dragonObject.fly(to: 1000) { [weak self] success in
            // attention for UI thread. just an example
            self?.infoLabel.stringValue = "Fly \(success ? "Success" : "Fail")"
        }
    }
    
    @IBAction func fire(_ sender: Any) {
        guard let appDelegate = NSApp.delegate as? AppDelegate,
            let dragonObject = appDelegate.dragonService?.remoteObjectProxy as? DragonServiceProtocol else { return }
        
        dragonObject.fire(times: 10) {  success in
            DispatchQueue.main.async { [weak self]
                self?.infoLabel.stringValue = "Fire \(success ? "Success" : "Fail")"
            }
        }
    }
}

