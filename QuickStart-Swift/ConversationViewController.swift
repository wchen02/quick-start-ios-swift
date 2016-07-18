//
//  ConversationViewController.swift
//  QuickStart-Swift
//
//  Created by yan on 7/18/16.
//  Copyright © 2016 layer. All rights reserved.
//

import Foundation
import UIKit
import LayerKit
import Atlas

class ConversationViewController: ATLConversationViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var textInput: UITextView!
    @IBOutlet weak var send: UIButton!
    
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1;
    }
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        return UITableViewCell();
    }

    @IBAction func onSendButtonPressed(sender: AnyObject) {
        print("send is pressed")
    }
    
    @IBAction func onCameraButtonPressed(sender: AnyObject) {
        print("camera is pressed")
    }
}