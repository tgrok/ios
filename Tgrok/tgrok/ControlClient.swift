//
//  ControlClient.swift
//  Tgrok
//
//  Created by Yueyu Zhao on 2020/9/13.
//  Copyright © 2020 Yueyu Zhao. All rights reserved.
//

import Foundation
import Network
import SwiftyJSON

class ControlClient: TgrokClient {
    
    var clientId = ""
    var _status = 0
    
    var tunnels: [Tunnel] = []
    
    var timer: Timer?
    let pingJson = JSON([
        "Type": "Ping",
        "Payload": NSDictionary(),
    ]).desc
    
    var status: Int {
        set (val) {
            self._status = val
            NotificationCenter.default.post(name: .tgrok, object: JSON([
                "evt": "control:status",
                "payload": val,
            ]))
        }
        
        get {
            return self._status
        }
    }
    
    override init(_ host: String, _ port: UInt16) {
        super.init(host, port)
        self.type = "ctl"
    }
    
    func start(tunnels: [Tunnel]) {
        self.tunnels = tunnels
        super.start()
    }
    
    override func onReady() {
        super.onReady()
        self.status = 2;
        self.send(self.auth())
    }
    
    override func onData(_ json: JSON) {
        let payload = json["Payload"].dictionaryValue
        switch json["Type"].stringValue {
        case "AuthResp":
            self.clientId = payload["ClientId"]!.stringValue
            self.startTimer()
            self.registerTunnels()
            break
        case "ReqProxy":
            self.regProxy()
            break
        case "NewTunnel":
            NotificationCenter.default.post(name: .tgrok, object: JSON([
                "evt": "tunnel:resp",
                "payload": payload["Error"]?.string
            ]))
            let error = payload["Error"]!.stringValue
            if "" != error {
                self.log("add tunnel failed : \(error)")
                return
            }
            _ = self.newTunnel(payload)
            break
        default:
            break
        }
    }
    
    func regProxy() {
        ProxyClient(self.host.debugDescription, self.port.rawValue, ctl: self).start()
    }
    
    override func onFailed(_ error: Error) {
        print("onFail", error)
        clearTimer()
    }
    
    func startTimer() {
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 20.0, repeats: true) { (_) in
            self.ping()
        }
    }
    
    func clearTimer() {
        guard timer != nil else { return }
        timer?.invalidate()
        timer = nil
    }
    
    func registerTunnels() {
        self.log("register tunnels")
        self.tunnels.forEach { (tunnel) in
            self.registerTunnel(tunnel)
        }
    }
    
    func registerTunnel(_ tunnel: Tunnel) {
        tunnel.status = 6
        self.send(tunnel.request())
    }
    
    func openTunnel(_ tunnel: Tunnel) {
        self.log("openning tunnel for \(tunnel.subdomain)")
        var oldTunnel: Tunnel?
        for i in 0..<self.tunnels.count {
            let t = self.tunnels[i]
            if (t.id == tunnel.id) {
                oldTunnel = t
                self.tunnels.remove(at: i)
            }
        }
        self.tunnels.append(tunnel)
        if oldTunnel != nil && oldTunnel?.subdomain == tunnel.subdomain && oldTunnel?.url != nil {
            tunnel.url = oldTunnel?.url
            tunnel.status = 10
            return
        }
        self.registerTunnel(tunnel)
    }
    
    func closeTunnel(_ id: String) -> Bool {
        self.log("closing tunnel for \(id)")
        for i in 0..<self.tunnels.count {
            let tunnel = self.tunnels[i]
            if (tunnel.id == id) {
                tunnel.status = 0
                return true
            }
        }
        return false
    }
    
    func removeTunnel(_ id: String) -> Bool {
        self.log("removing tunnel \(id)")
        for i in 0..<self.tunnels.count {
            let tunnel = self.tunnels[i]
            if (tunnel.id == id) {
                self.tunnels.remove(at: i)
                return true
            }
        }
        return false
    }
    
    func newTunnel(_ payload: [String: JSON]) -> Bool {
        let reqId = payload["ReqId"]!.stringValue
        for i in 0..<self.tunnels.count {
            let tunnel = self.tunnels[i]
            if tunnel.requestId == reqId {
                tunnel.url = payload["Url"]?.stringValue
                tunnel.status = 10
                self.log("add tunnel OK, type: \(tunnel.proto)")
                return true
            }
        }
        self.log("no tunnel found for \(reqId)")
        return false
    }
    
    private func ping() {
        self.send(pingJson)
    }
    
    private func auth() -> JSON {
        return JSON([
            "Type": "Auth",
            "Payload": [
                "Version": "2",
                "MmVersion": "1.7",
                "User": "",
                "Password": "",
                "OS": "darwin",
                "Arch": "amd64",
                "ClientId": clientId,
            ]
        ])
    }
    
}
