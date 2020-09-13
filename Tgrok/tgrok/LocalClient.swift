//
//  LocalClient.swift
//  Tgrok
//
//  Created by Yueyu Zhao on 2020/9/13.
//  Copyright © 2020 Yueyu Zhao. All rights reserved.
//

import Foundation

class LocalClient: BaseClient {
    
    override init(_ host: String, _ port: UInt16) {
        super.init(host, port)
        self.type = "prv"
    }
    
}
