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

class ConversationListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    let ConversationCellReuseIdentifier = "ConversationCell"
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // MARK:- Table View Data Source Methods
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
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
