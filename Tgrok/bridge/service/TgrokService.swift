//
//  TgrokService.swift
//  Tgrok
//
//  Created by Yueyu Zhao on 2020/9/13.
//  Copyright © 2020 Yueyu Zhao. All rights reserved.
//

import Foundation
import SwiftyJSON

class TgrokService: JsService {
    
    static let shared = TgrokService()
    
    private override init() {
        super.init()
    }

    @objc func reconnect(_ req: JsRequest) {
        req.callback(true)
    }
    
    @objc func open(_ req: JsRequest) {
        let id = req.strParam("id")
        let tunnels = Config.shared.get(key: "tunnels") as! JSON
        for tunnel in tunnels.arrayValue {
            if tunnel["id"].stringValue == id {
                tgrok.openTunnel(Tunnel(tunnel))
                req.callback(true)
                return
            }
        }
        req.callback(false)
    }
    
    @objc func close(_ req: JsRequest) {
        req.callback(tgrok.closeTunnel(req.strParam("id")))
    }
    
    @objc func remove(_ req: JsRequest) {
        req.callback(tgrok.removeTunnel(req.strParam("id")))
    }
    
    @objc func status(_ req: JsRequest) {
        req.callback(tgrok.status())
    }
    
}
