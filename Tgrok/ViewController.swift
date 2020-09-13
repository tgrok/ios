//
//  ViewController.swift
//  Tgrok
//
//  Created by Yueyu Zhao on 2020/9/12.
//  Copyright © 2020 Yueyu Zhao. All rights reserved.
//

import UIKit
import WebKit

class ViewController: UIViewController {
    
    var urlHome: String! = "www/index.html"
    
    var webView: WKWebView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        webView = WKWebView(frame: CGRect.zero, configuration: webViewConfig())
        webView.navigationDelegate = self
        installBridge(webView)
        
        self.view = webView
        
        // Uncomment this if you need to debug gui
        // urlHome = "http://127.0.0.1:8080/"
        
        if nil != urlHome {
            loadRequest(urlHome)
        }
    }

    func webViewConfig() -> WKWebViewConfiguration {
        let config = WKWebViewConfiguration()
        config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        return config
    }

    func installBridge(_ webView: WKWebView) {
        let bridge = JsBridge(webView)

        bridge.register(ConfigService.shared)
        bridge.register(PageService())
        bridge.register(TgrokService.shared)
        
        webView.configuration.userContentController.add(bridge, name: "jsBridge")
    }
    
    func loadRequest(_ file: String) {
        var url: URL
        if (file.starts(with: "file:///")) {
            url = URL(string: file)!
        } else if !file.starts(with: "http") {
            let path = Bundle.main.path(forResource: file, ofType: "", inDirectory: "")!
            url = URL(fileURLWithPath: path)
        } else {
            url = URL(string: file)!
        }
        
        webView.load(URLRequest(url: url))
    }
}

extension ViewController: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webView.evaluateJavaScript("window.jsBridge = window.webkit.messageHandlers.jsBridge", completionHandler: nil)

        self.disableLongPressGesturesForView(webView)
    }
    
    // Disables iOS 9 webview touch tooltip by disabling the long-press gesture recognizer in subviews
    // Thanks to Rye:
    // http://stackoverflow.com/questions/32687368/how-to-completely-disable-magnifying-glass-for-uiwebview-ios9
    func disableLongPressGesturesForView(_ view: UIView) {
        for subview in view.subviews {
            if let gestures = subview.gestureRecognizers as [UIGestureRecognizer]? {
                for gesture in gestures {
                    if gesture is UILongPressGestureRecognizer {
                        gesture.isEnabled = false
                    }
                }
            }
            disableLongPressGesturesForView(subview)
        }
    }
}
