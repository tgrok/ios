//
//  ConfigService.swift
//  Tgrok
//
//  Created by Yueyu Zhao on 2020/9/13.
//  Copyright © 2020 Yueyu Zhao. All rights reserved.
//

import Foundation

class ConfigService: JsService {
    
    static let shared = ConfigService()
    
    private override init() {
        super.init()
    }
    
    @objc func load(_ req: JsRequest) {
        req.callback(Config.shared.load())
    }
    
    @objc func get(_ req: JsRequest) {
        req.callback(Config.shared.get(key: req.strParam("key")))
    }
    
    @objc func set(_ req: JsRequest) {
        Config.shared.set(key: req.strParam("key"), value: req.params["value"])
    }
    
    @objc func flush(_ req: JsRequest) {
        Config.shared.flush()
    }
    
}
