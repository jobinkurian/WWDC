//
//  WDCPartyWebViewController.swift
//  SFParties
//
//  Created by Genady Okrain on 11/20/14.
//  Copyright (c) 2014 Sugar So Studio. All rights reserved.
//

import UIKit
import WebKit

@objc class WDCPartyWebViewController: UIViewController {
    var url: NSURL?
    var observer: JVObserver?

    let webView = WKWebView()
    let progressView = UIProgressView(progressViewStyle: .Default)

    override func loadView() {
        super.loadView()

        // load progress and web views
        webView.addSubview(progressView)
        view = webView

        // auto layout progress view
        progressView.setTranslatesAutoresizingMaskIntoConstraints(false)
        let views = ["progressView": progressView]
        webView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[progressView]|", options: nil, metrics: nil, views: views))
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Google
        let tracker = GAI.sharedInstance().defaultTracker
        tracker.set(kGAIScreenName, value: "WDCPartyWebViewController")
        tracker.send(GAIDictionaryBuilder.createAppView().build().copy() as! [NSObject : AnyObject])

        // load url
        webView.loadRequest(NSURLRequest(URL:url!))

        // update progress
        observer = JVObserver(forObject: webView, keyPath: "estimatedProgress", target: self) { [weak self] _ in
            self?.progressView.progress = Float((self?.webView.estimatedProgress)!)
            if self?.webView.estimatedProgress == 1.0 {
                UIView.animateWithDuration(0.2) {
                    self?.progressView.alpha = 0
                }
            }
        }
    }

    @IBAction func share(sender: UIBarButtonItem) {
        let activity = TUSafariActivity() // open in safari
        let activityViewController : UIActivityViewController = UIActivityViewController(activityItems: [title!, url!], applicationActivities: [activity])
        activityViewController.completionWithItemsHandler = { [weak self] activityType, completed, _, _ in
            if let title = self?.title {
                var properties:NSDictionary;
                if activityType == nil {
                    properties = ["Party": title, "activityType": NSNull(), "completed": NSNumber(bool: completed)];
                } else {
                    properties = ["Party": title, "activityType": activityType, "completed": NSNumber(bool: completed)];
                }
                Mixpanel.sharedInstance().track("Share", properties: properties as [NSObject : AnyObject])
            }
            if (completed) {
                Mixpanel.sharedInstance().people.increment("Share", by: 1)
            }
        }
        activityViewController.popoverPresentationController?.barButtonItem = sender
        presentViewController(activityViewController, animated: true, completion: nil)
    }
}
