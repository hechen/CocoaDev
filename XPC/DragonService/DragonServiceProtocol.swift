//
//  DragonServiceProtocol.swift
//  DragonService
//
//  Created by chen he on 2019/7/3.
//  Copyright © 2019 chen he. All rights reserved.
//

import Foundation

@objc
protocol DragonServiceProtocol {    
    func fly(to height: Float, withReply reply: ((Bool)->Void)?)
    func fire(times: Int, withReply reply: ((Bool)->Void)?)
    
    // for multiple replies
    // func fire(times: Int, withSuccess success: (()->Void)?, withFailure failure: (()->Void)?)
}
