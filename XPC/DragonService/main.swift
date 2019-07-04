//
//  main.swift
//  DragonService
//
//  Created by chen he on 2019/7/3.
//  Copyright © 2019 chen he. All rights reserved.
//

import Foundation

/*
 ## What Service will do when launchd start it?
 
 1. Listener Object calls listener:shouldAcceptNewConnection
 2. Sets exportedObject
 3. Sets exportedInterface
 4. Calls resume
 5. return YES
 */
class ServiceDelegate : NSObject, NSXPCListenerDelegate {
    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        newConnection.exportedInterface = NSXPCInterface(with: DragonServiceProtocol.self)
        newConnection.exportedObject = DragonService()
        newConnection.resume()
        return true
    }
}

let delegate = ServiceDelegate()
let listener = NSXPCListener.service()
listener.delegate = delegate;
listener.resume()
