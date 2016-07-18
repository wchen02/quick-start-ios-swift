//
//  ConversationListViewController.swift
//  QuickStart-Swift
//
//  Created by yan on 7/16/16.
//  Copyright © 2016 layer. All rights reserved.
//

import Foundation
import UIKit
import LayerKit
import Atlas

class ConversationListViewController: ATLConversationListViewController, ATLConversationListViewControllerDataSource, ATLConversationListViewControllerDelegate {
    let ConversationCellReuseIdentifier = "ConversationCell"
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func conversationListViewController(conversationListViewController: ATLConversationListViewController, titleForConversation conversation: LYRConversation) -> String {
        return "Conversation title";
    }
    
    func conversationListViewController(conversationListViewController: ATLConversationListViewController, didSelectConversation conversation: LYRConversation) {
        print("Selected convo")
        
        let conversationViewController = ConversationViewController()
        conversationViewController.layerClient = self.layerClient
        conversationViewController.conversation = conversation
        conversationViewController.displaysAddressBar = true
        navigationController!.pushViewController(conversationViewController, animated: true)
    }


    // MARK:- Table View Data Source Methods
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier(ConversationCellReuseIdentifier, forIndexPath: indexPath) as? ConversationCell
        if cell == nil {
            cell = ConversationCell(style: UITableViewCellStyle.Default, reuseIdentifier: ConversationCellReuseIdentifier)
        }
        
        configureCell(cell!, forRowAtIndexPath: indexPath)
        return cell!
    }
    
    func configureCell(cell: ConversationCell, forRowAtIndexPath indexPath: NSIndexPath) {
    }
}
