//
//  ProxyClient.swift
//  Tgrok
//
//  Created by Yueyu Zhao on 2020/9/13.
//  Copyright © 2020 Yueyu Zhao. All rights reserved.
//

import Foundation
import Network

class ProxyClient: TgrokClient {
    
    init(_ host: String, _ port: UInt16, ctl: ControlClient) {
        super.init(host, port)
        type = "pxy"
    }
    
}
