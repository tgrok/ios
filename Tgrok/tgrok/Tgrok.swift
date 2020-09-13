//
//  Tgrok.swift
//  Tgrok
//
//  Created by Yueyu Zhao on 2020/9/13.
//  Copyright © 2020 Yueyu Zhao. All rights reserved.
//

import Foundation
import SwiftyJSON

class Tgrok: NSObject {
    
    override init() {
        super.init()
    }
    
    func start(_ host: String, _ port: UInt16) {
        let client = ControlClient("t.drmer.net", 4443)
        client.tunnels.append(Tunnel(JSON([
            "id": UUID().uuidString,
            "protocol": "http",
            "hostname": "",
            "subdomain": "",
            "rport": 0,
            "lhost": host,
            "lport": port,
        ])))
        client.start()
    }
    
}
