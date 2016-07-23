import UIKit
import Atlas

class ConversationViewController: ATLConversationViewController, ATLConversationViewControllerDataSource, ATLConversationViewControllerDelegate, ATLParticipantTableViewControllerDelegate {
    var dateFormatter: NSDateFormatter = NSDateFormatter()
    var usersArray: NSArray!
    
    override func viewDidLoad() {
        // Uncomment the following line if you want to show avatars in 1:1 conversations
        self.shouldDisplayAvatarItemForOneOtherParticipant = true
        self.shouldDisplayAvatarItemForAuthenticatedUser = true
        self.displaysAddressBar = false
        super.viewDidLoad()

        self.dataSource = self
        self.delegate = self

        // Setup the dateformatter used by the dataSource.
        self.dateFormatter.dateStyle = NSDateFormatterStyle.ShortStyle
        self.dateFormatter.timeStyle = NSDateFormatterStyle.ShortStyle
        self.configureUI()
    }
    
    // MARK - UI Configuration methods
    
    func configureUI() {
        ATLOutgoingMessageCollectionViewCell.appearance().messageTextColor = UIColor.whiteColor()
        self.title = getTitle()
    }
    
    func getTitle() -> String {
        if let title = conversation.metadata?["title"] {
            return title as! String
        } else {
            let listOfParticipant = conversation.participants
            let unresolvedParticipants: NSArray = UserManager.sharedManager.unCachedUserIDsFromParticipants(listOfParticipant)
            let resolvedNames: NSArray = UserManager.sharedManager.resolvedNamesFromParticipants(listOfParticipant)
            
            if (unresolvedParticipants.count > 0) {
                print("unable to resolve \(unresolvedParticipants.count) people")
                UserManager.sharedManager.queryAndCacheUsersWithIDs(unresolvedParticipants as! [String]) { (participants: NSArray?, error: NSError?) in
                    if (error == nil) {
                        if (participants?.count > 0) {
                            //self.reloadCellForMessage(self.message)
                        }
                    } else {
                        print("Error querying for Users: \(error)")
                    }
                }
            }
            
            if (resolvedNames.count > 0 && unresolvedParticipants.count > 0) {
                let resolved = resolvedNames.componentsJoinedByString(", ")
                return "\(resolved) and \(unresolvedParticipants.count) others"
            } else if (resolvedNames.count > 0 && unresolvedParticipants.count == 0) {
                return resolvedNames.componentsJoinedByString(", ")
            } else {
                return "Conversation with \(conversation.participants.count) users..."
            }
        }
    }
    
    // MARK - ATLConversationViewControllerDelegate methods
    
    func conversationViewController(viewController: ATLConversationViewController, didSendMessage message: LYRMessage) {
        print("Message sent!")
    }
    
    func conversationViewController(viewController: ATLConversationViewController, didFailSendingMessage message: LYRMessage, error: NSError) {
        print("Message failed to sent with error: \(error)")
    }
    
    func conversationViewController(viewController: ATLConversationViewController, didSelectMessage message: LYRMessage) {
        print("Message selected")
    }
    
    // MARK - ATLConversationViewControllerDataSource methods
    func conversationViewController(conversationViewController: ATLConversationViewController, participantForIdentity identity: LYRIdentity) -> ATLParticipant {
        var user: User? = UserManager.sharedManager.cachedUserForUserID(identity.userID)
        if (user == nil) {
            // returns a placeholder user before the user is fetch
            user = User(userID: "-1", firstName: "", lastName: "", avatarUrl: "")
            UserManager.sharedManager.queryAndCacheUsersWithIDs([identity.userID]) { (participants: NSArray?, error: NSError?) -> Void in
                if (participants?.count > 0 && error == nil) {
                    self.addressBarController.reloadView()
                    // TODO: Need a good way to refresh all the messages for the refreshed participants...
                    self.reloadCellsForMessagesSentByParticipantWithIdentifier(identity.userID)
                } else {
                    print("Error querying for users: \(error)")
                }
            }
        }
        return user!
    }
    
    func conversationViewController(conversationViewController: ATLConversationViewController, attributedStringForDisplayOfDate date: NSDate) -> NSAttributedString {
        let attributes: NSDictionary = [ NSFontAttributeName : UIFont.systemFontOfSize(14), NSForegroundColorAttributeName : UIColor.grayColor() ]
        return NSAttributedString(string: self.dateFormatter.stringFromDate(date), attributes: attributes as? [String : AnyObject])
    }
    
    func conversationViewController(conversationViewController: ATLConversationViewController, attributedStringForDisplayOfRecipientStatus recipientStatus: [NSObject:AnyObject]) -> NSAttributedString{
        if (recipientStatus.count == 0) {
            return NSAttributedString(string: "")
        }
        let mergedStatuses: NSMutableAttributedString = NSMutableAttributedString()
        
        let recipientStatusDict = recipientStatus as NSDictionary
        let allKeys = recipientStatusDict.allKeys as NSArray
        allKeys.enumerateObjectsUsingBlock { participant, _, _ in
            let participantAsString = participant as! String
            if (participantAsString == self.layerClient.authenticatedUser?.userID) {
                return
            }
            
            let checkmark: String = "✔︎"
            var textColor: UIColor = UIColor.lightGrayColor()
            let status: LYRRecipientStatus! = LYRRecipientStatus(rawValue: Int(recipientStatusDict[participantAsString]!.unsignedIntegerValue))
            switch status! {
            case .Sent:
                textColor = UIColor.lightGrayColor()
            case .Delivered:
                textColor = UIColor.orangeColor()
            case .Read:
                textColor = UIColor.greenColor()
            default:
                textColor = UIColor.lightGrayColor()
            }
            let statusString: NSAttributedString = NSAttributedString(string: checkmark, attributes: [NSForegroundColorAttributeName: textColor])
            mergedStatuses.appendAttributedString(statusString)
        }
        return mergedStatuses;
    }
    
    // MARK - ATLParticipantTableViewController Delegate Methods
    
    func participantTableViewController(participantTableViewController: ATLParticipantTableViewController, didSelectParticipant participant: ATLParticipant) {
        print("participant: \(participant)")
        self.addressBarController.selectParticipant(participant)
        print("selectedParticipants: \(self.addressBarController.selectedParticipants)")
        self.navigationController!.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func participantTableViewController(participantTableViewController: ATLParticipantTableViewController, didSearchWithString searchText: String, completion: (Set<NSObject>) -> Void) {
//        UserManager.sharedManager.queryForUserWithName(searchText) { (participants, error) in
//            if (error == nil) {
//                completion(NSSet(array: participants as! [AnyObject]) as Set<NSObject>)
//            } else {
//                print("Error search for participants: \(error)")
//            }
//        }
    }
}