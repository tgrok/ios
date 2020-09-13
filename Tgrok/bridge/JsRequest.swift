//
//  JsRequest.swift
//  Tgrok
//
//  Created by Yueyu Zhao on 2020/9/13.
//  Copyright © 2020 Yueyu Zhao. All rights reserved.
//

import Foundation
import SwiftyJSON
import WebKit

class JsRequest: NSObject {
    let webView: WKWebView
    
    let id: String!
    let clsName: String
    let clsMethod: String
    let params: JSON
    let callback: String
    let origMethod: String

    init(_ webView: WKWebView, _ json: String) {
        self.webView = webView

        let body = JSON(parseJSON: json)
        self.id = body["id"].string
        origMethod = body["method"].stringValue
        let methods = origMethod.components(separatedBy: "@")
        clsName = methods[0]
        clsMethod = methods[1]
        params = body["params"]
        callback = body["callback"].stringValue
    }

    func callback(_ result: String) {
        if nil == self.id {
            return;
        }
        var format = "Drmer.dequeue('%@', '%@');"
        // result is a JSON string
        if "null" == result || result.starts(with: "{") || result.starts(with: "[") {
            format = "Drmer.dequeue('%@', %@);"
        }
        let js = String(format: format, self.id, result)
        DispatchQueue.main.async {
            self.webView.evaluateJavaScript(js, completionHandler: nil)
        }
    }

    func callback(_ result: Bool) {
        self.callback(result ? "true" : "false")
    }

    func callback(_ result: JSON) {
        self.callback(result.description)
    }

    func intParam(_ key: String) -> Int {
        return self.params[key].intValue
    }

    func strParam(_ key: String) -> String {
        return self.params[key].stringValue
    }

    func boolParam(_ key: String) -> Bool {
        return self.params[key].boolValue
    }

    func jsonParam(_ key: String) -> JSON {
        return JSON(parseJSON: self.strParam(key))
    }
}
