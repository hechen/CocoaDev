//
//  DragonService.swift
//  DragonService
//
//  Created by chen he on 2019/7/3.
//  Copyright © 2019 chen he. All rights reserved.
//

import Foundation

class DragonService: DragonServiceProtocol {
    func fly(to height: Float, withReply reply: ((Bool) -> Void)?) {
        print("I fly. fly. to \(height) ")
        
        reply?(Bool.random())
    }
    
    func fire(times: Int, withReply reply: ((Bool) -> Void)?) {
        times.times {
            print("Fire...\n")
        }
        
        reply?(Bool.random())
    }

}


extension Int {
    func times (iterator: () -> Void) {
        for _ in 0...self {
            iterator()
        }
    }
}
