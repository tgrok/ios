//
//  TgrokClient.swift
//  Tgrok
//
//  Created by Yueyu Zhao on 2020/9/13.
//  Copyright © 2020 Yueyu Zhao. All rights reserved.
//

import Foundation
import Network

class TgrokClient: BaseClient {
    
    override func start() {
        super.start()
        if (nil == connection) {
            return
        }
        readLoop()
    }
    
    func readLoop() {
        readHeader(connection)
    }
    
    func readHeader(_ connection: NWConnection) {
        let headerLength: Int = 8
        connection.receive(minimumIncompleteLength: headerLength, maximumLength: headerLength) { (content, contentContext, isComplete, err) in
            if let error = err {
                print("read header error: ", error)
                return
            }
            if let content = content {
                let bodyLength = content.toUIntLE()
                self.readBody(connection, bodyLength)
                return
            }
            self.readLoop()
        }
    }
    
    func readBody(_ connection: NWConnection, _ bodyLength: Int) {
        connection.receive(minimumIncompleteLength: bodyLength, maximumLength: bodyLength) { (content, context, isComplete, err) in
            if let error = err {
                print("read body error: ", error)
                return
            }
            
            if let content = content {
                let data = String(data: content, encoding: .utf8)
                self.log("recv <<< " + data!)
                self.onData(data!)
            }
            if let context = context, context.isFinal, isComplete  {
                return
            }
            self.readLoop()
        }
    }
    
    func onData(_ data: String) {
    }
    
}
