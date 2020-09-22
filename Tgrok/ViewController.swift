//
//  ViewController.swift
//  Tgrok
//
//  Created by Yueyu Zhao on 2020/9/12.
//  Copyright © 2020 Yueyu Zhao. All rights reserved.
//

import UIKit
import WebKit
import SwiftyJSON

class ViewController: UIViewController {
    
    var urlHome: String! = "www/index.html"
    
    var webView: WKWebView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        webView = WKWebView(frame: webViewRect(), configuration: webViewConfig())
        webView.navigationDelegate = self
        installBridge(webView)
        
        self.view.addSubview(webView)
        
        // Uncomment this if you need to debug gui
        // urlHome = "http://127.0.0.1:8080/"
        
        if nil != urlHome {
            loadRequest(urlHome)
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    func webViewRect() -> CGRect {
        let height = UIDevice.headerHeight()
        return CGRect(x: 0, y: -height, width: view.bounds.size.width, height: view.bounds.size.height + height)
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
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        NotificationCenter.default.removeObserver(self, name: .tgrok, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(rotated), name: UIDevice.orientationDidChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onTgrokEvent(_:)), name: .tgrok, object: nil)
    }
    
    @objc func rotated() {
        Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { (_) in
            self.webView.frame = self.webViewRect()
        }
    }
    
    @objc func onTgrokEvent(_ notification: Notification) {
        let json = notification.object as! JSON
        let format = "Drmer.events.emit('%@', %@);"
        let js = String(format: format, "tgrok", json.desc)
        // print(js)
        webView.evaluateJavaScript(js, completionHandler: nil)
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
