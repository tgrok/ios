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
    
    var controlClient: ControlClient
    
    private var timer: Timer?
    private var retryTimes = 0
    
    override init() {
        let server = Config.shared.get(key: "server") as! JSON
        self.controlClient = ControlClient(server["host"].stringValue, server["port"].uInt16Value)
        super.init()
        self.controlClient.delegate = self
    }
    
    func start(_ port: UInt16, _ host: String?) {
        controlClient.tunnels.append(Tunnel(JSON([
            "id": UUID().uuidString,
            "protocol": "http",
            "hostname": "",
            "subdomain": "test",
            "remotePort": 0,
            "localHost": host ?? "127.0.0.1",
            "localPort": port,
        ])))
        self.connect()
    }
    
    func start(_ tunnels: [Tunnel]) {
        controlClient.tunnels = tunnels
        self.connect()
    }

    func openTunnel(_ tunnel: Tunnel) {
        self.controlClient.openTunnel(tunnel)
    }
    
    func closeTunnel(_ id: String) -> Bool {
        return self.controlClient.closeTunnel(id)
    }
    
    func removeTunnel(_ id: String) -> Bool {
        return self.controlClient.removeTunnel(id)
    }
    
    func status() -> JSON {
        var tunnels: [JSON] = []
        for tunnel in self.controlClient.tunnels {
            tunnels.append(JSON([
                "id": tunnel.id,
                "status": tunnel.status,
            ]))
        }
        return JSON([
            "status": self.controlClient.status,
            "tunnels": tunnels,
        ])
    }
    
    private func connect() {
        self.controlClient.start()
    }
    
    func reconnect(_ clear: Bool) {
        if clear {
            timer?.invalidate()
            self.retryTimes = 0
            self.timer = nil
        }
        
        if self.timer != nil {
            return
        }
        
        let timeout = self.timeout()
        timer = Timer.scheduledTimer(withTimeInterval: timeout, repeats: false, block: { (_) in
            self.timer?.invalidate()
            self.timer = nil
            self.connect()
        })
        self.retryTimes += 1
    }
    
    func timeout() -> Double {
        let times = [1, 1, 2, 3, 5, 8, 13, 21]
        if self.retryTimes >= times.count {
            return Double(times.last!)
        }
        return Double(times[self.retryTimes])
    }
    
}

extension Tgrok : ControlClientDelegate {
    
    func onConnect() {
        self.retryTimes = 0
    }
    
    func onError() {
        let timeout = self.timeout()
        NotificationCenter.default.post(name: .tgrok, object: JSON([
            "evt": "master:error",
            "payload": "reconnect after \(timeout)s"
        ]))
        print("main socket error, reconnect after \(timeout)s")
        self.timer = nil
        self.reconnect(false)
    }
    
}
