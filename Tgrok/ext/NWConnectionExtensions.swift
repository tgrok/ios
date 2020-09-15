//
//  NWConnectionExtensions.swift
//  Tgrok
//
//  Created by Yueyu Zhao on 2020/9/14.
//  Copyright © 2020 Yueyu Zhao. All rights reserved.
//

import Foundation
import Network

extension NWConnection {
    
    func pipe(_ connection: NWConnection) {
        self.receive(minimumIncompleteLength: 1, maximumLength: 2048) { (content, context, isComplete, error) in
            
            var isDone = false
            if let context = context, context.isFinal, isComplete {
                isDone = true
            }
            
            if let content = content {
                print("==>", content.count)
                print(String(data: content, encoding: .ascii)!)
                print("===", content.count)
                connection.send(content: content, completion: .contentProcessed({ (sendError) in
                    if let sendError = sendError {
                        print(sendError)
                        return
                    }
                    if isDone {
                        print("context is done");
                        connection.cancel()
                    }
                }))
            }

            if let error = error {
                print(error)
                return
            }
            
            if isDone {
                return
            }
            
            self.pipe(connection)
        }
        
    }
    
}
