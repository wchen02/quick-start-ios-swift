import UIKit

// Metadata keys related to navbar color
let LQSBackgroundColorMetadataKey = "backgroundColor"
let LQSRedBackgroundColorMetadataKeyPath = "backgroundColor.red"
let LQSBlueBackgroundColorMetadataKeyPath = "backgroundColor.blue"
let LQSGreenBackgroundColorMetadataKeyPath = "backgroundColor.green"
let LQSRedBackgroundColor = "red"
let LQSBlueBackgroundColor = "blue"
let LQSGreenBackgroundColor = "green"

// Message State Images
let LQSMessageSentImageName = "message-sent"
let LQSMessageDeliveredImageName = "message-delivered"
let LQSMessageReadImageName = "message-read"

let LQSChatMessageCellReuseIdentifier = "ChatMessageCell"

let LQSLogoImageName = "Logo"
let LQSKeyboardHeight: CGFloat = 255.0

let LQSMaxCharacterLimit = 66

let MIMETypeImagePNG = "image/png"

func LSRandomColor() -> UIColor {
    let redFloat: CGFloat = CGFloat(drand48())
    let greenFloat: CGFloat = CGFloat(drand48())
    let blueFloat: CGFloat = CGFloat(drand48())
    
    return UIColor(red: redFloat, green: greenFloat, blue: blueFloat, alpha: 1.0)
}

class LQSViewController: UIViewController, UITextViewDelegate, LYRQueryControllerDelegate, UITableViewDelegate, UITableViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIAlertViewDelegate {
    var layerClient: LYRClient?
    var conversation: LYRConversation?
    var queryController: LYRQueryController?
    var sendingImage: Bool = false
    var photo: UIImage? //this is where the selected photo will be stored
    
    @IBOutlet weak var inputTextView: UITextView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var messageImage: UIImageView!
    @IBOutlet weak var typingIndicatorLabel: UILabel!
    
    // TODO: This should not belong to the view controller.
    var dateFormatter: NSDateFormatter {
        struct Static {
            static let instance : NSDateFormatter = {
                let formatter = NSDateFormatter()
                formatter.dateFormat = "HH:mm:ss"
                return formatter
            }()
        }
        return Static.instance
    }
    
    // MARK:- VC Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        if layerClient == nil {
            let alert = UIAlertController(title: "\u{1F625}", message: "To correctly use this project you need to replace LAYER_APP_ID in AppDelegate.swift (line 6) with your App ID from developer.layer.com.", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: { _ in abort() } ))
            presentViewController(alert, animated: true, completion: nil)
            return
        }
        setupLayerNotificationObservers()
        fetchLayerConversation()
        
        // Setup for Shake
        becomeFirstResponder()
        
        let logoImageView: UIImageView = UIImageView(image: UIImage(named: LQSLogoImageName))
        logoImageView.frame = CGRectMake(0, 0, 36, 36)
        logoImageView.contentMode = UIViewContentMode.ScaleAspectFit
        navigationItem.titleView = logoImageView
        navigationItem.hidesBackButton = true
        inputTextView.delegate = self
        inputTextView.text = LQSInitialMessageText
    }

    override func viewWillAppear(animated: Bool) {
        scrollToBottom()
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    func setupLayerNotificationObservers() {
        // Register for Layer object change notifications
        // For more information about Synchronization, check out https://developer.layer.com/docs/integration/ios#synchronization
        NSNotificationCenter.defaultCenter().addObserver(self,
                                                         selector: #selector(LQSViewController.didReceiveLayerObjectsDidChangeNotification(_:)),
                                                         name: LYRClientObjectsDidChangeNotification,
                                                         object: nil)
        
        // Register for typing indicator notifications
        // For more information about Typing Indicators, check out https://developer.layer.com/docs/integration/ios#typing-indicator
        NSNotificationCenter.defaultCenter().addObserver(self,
                                                         selector: #selector(LQSViewController.didReceiveTypingIndicator(_:)),
                                                         name: LYRConversationDidReceiveTypingIndicatorNotification,
                                                         object: self.conversation)
        
        // Register for synchronization notifications
        NSNotificationCenter.defaultCenter().addObserver(self,
                                                         selector: #selector(LQSViewController.didReceiveLayerClientWillBeginSynchronizationNotification(_:)),
                                                         name: LYRClientWillBeginSynchronizationNotification,
                                                         object: self.layerClient)
        
        NSNotificationCenter.defaultCenter().addObserver(self,
                                                         selector: #selector(LQSViewController.didReceiveLayerClientDidFinishSynchronizationNotification(_:)),
                                                         name: LYRClientDidFinishSynchronizationNotification,
                                                         object: self.layerClient)
    }

    // MARK:- Fetching Layer Content

    func fetchLayerConversation() {
        // Fetches all conversations between the authenticated user and the supplied participant
        // For more information about Querying, check out https://developer.layer.com/docs/integration/ios#querying
        
        let query: LYRQuery = LYRQuery(queryableClass: LYRConversation.self)
        
        query.predicate = LYRPredicate(property: "participants", predicateOperator: LYRPredicateOperator.IsEqualTo, value: [ LQSCurrentUserID, LQSParticipantUserID, LQSParticipant2UserID ] as AnyObject)
        query.sortDescriptors = [ NSSortDescriptor(key: "createdAt", ascending: false) ]
        
        var error: NSError? = nil
        var conversations: NSOrderedSet?
        do {
            conversations = try layerClient?.executeQuery(query)
        } catch let error1 as NSError {
            error = error1
            conversations = nil
        }
        

        if conversations == nil || conversations!.count <= 0 {
            var convError: NSError? = nil
            do {
                self.conversation = try layerClient!.newConversationWithParticipants(NSSet(array: [LQSParticipantUserID, LQSParticipant2UserID]) as! Set<String>, options: nil)
            } catch let error as NSError {
                convError = error
                self.conversation = nil
            }
            if self.conversation == nil {
                print("New Conversation creation failed: \(convError)")
            }
        }
        
        if error == nil {
            print("\(conversations!.count) conversations with participants \([ LQSCurrentUserID, LQSParticipantUserID, LQSParticipant2UserID ])")
        } else {
            print("Query failed with error \(error)")
        }
        
        
        // Retrieve the last conversation
        if conversations != nil && conversations!.count > 0 {
            self.conversation = conversations!.lastObject as! LYRConversation?
            print("Get last conversation object: \(conversation!.identifier)")
            // setup query controller with messages from last conversation
            if queryController == nil {
                setupQueryController()
            }
        }
    }

    func setupQueryController() {
        // For more information about the Query Controller, check out https://developer.layer.com/docs/integration/ios#querying
        
        // Query for all the messages in conversation sorted by position
        let query: LYRQuery = LYRQuery(queryableClass: LYRMessage.self)
        query.predicate = LYRPredicate(property: "conversation", predicateOperator: LYRPredicateOperator.IsEqualTo, value: self.conversation)
        query.sortDescriptors = [ NSSortDescriptor(key: "position", ascending: true) ]
        
        // Set up query controller
        do {
            queryController = try layerClient!.queryControllerWithQuery(query)
        } catch let error {
            print("Query Controller initialization failed with error: %@", error);
        }
        queryController!.delegate = self
        
        var error: NSError?
        let success: Bool
        do {
            try queryController!.execute()
            success = true
        } catch let error1 as NSError {
            error = error1
            success = false
        }
        if success {
            print("Query fetched \(queryController!.numberOfObjectsInSection(0)) message objects")
        } else {
            print("Query failed with error: \(error)")
        }
        
        tableView.reloadData()
        do {
            try conversation!.markAllMessagesAsRead()
        } catch _ {
        }
    }
    
    // MARK:- Table View Data Source Methods

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Return number of objects in queryController
        if queryController == nil {
            return 0
        }
        let rows = queryController!.numberOfObjectsInSection(UInt(0))
        print("Rows \(rows)")
        return Int(rows)
    }

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let message = queryController?.objectAtIndexPath(indexPath) as! LYRMessage?
        if message == nil {
            return 70
        }
        let messagePart = message!.parts[0]
        
        //If it is type image
        if messagePart.MIMEType == "image/png" {
            return 130
        } else {
            return 70
        }
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        // Set up custom ChatMessageCell for displaying message
        //LQSPictureMessageCell
        var cell = tableView.dequeueReusableCellWithIdentifier(LQSChatMessageCellReuseIdentifier, forIndexPath: indexPath) as? LQSChatMessageCell
        if cell == nil {
            cell = LQSChatMessageCell(style: UITableViewCellStyle.Default, reuseIdentifier: LQSChatMessageCellReuseIdentifier)
        }
        
        configureCell(cell!, forRowAtIndexPath: indexPath)
        return cell!
    }

    func configureCell(cell: LQSChatMessageCell, forRowAtIndexPath indexPath: NSIndexPath) {
        // Get Message Object from queryController
        let message = queryController!.objectAtIndexPath(indexPath) as? LYRMessage
        let messagePart: LYRMessagePart = message!.parts[0] 
        
        //If it is type image
        if messagePart.MIMEType == "image/png" {
            cell.messageLabel.text = "";
            if messagePart.data != nil {
                cell.updateWithImage(UIImage(data: messagePart.data!)!)
            }
            
        } else {
            cell.removeImage() //just a safegaurd to ensure  that no image is present
            cell.assignText(NSString(data: messagePart.data!, encoding: NSUTF8StringEncoding) as! String)
        }
        var timestampText = ""
        
        // If the message was sent by current user, show Receipent Status Indicator
        if message!.sender.userID == LQSCurrentUserID {
            switch message!.recipientStatusForUserID(LQSParticipantUserID) {
                case LYRRecipientStatus.Sent:
                    cell.messageStatus.image = UIImage(named: LQSMessageSentImageName)
                    timestampText = "Sent: \(dateFormatter.stringFromDate(message!.sentAt!))"
                
                case LYRRecipientStatus.Delivered:
                    cell.messageStatus.image = UIImage(named: LQSMessageDeliveredImageName)
                    timestampText = "Delivered: \(dateFormatter.stringFromDate(message!.sentAt!))"
                
                case LYRRecipientStatus.Read:
                    cell.messageStatus.image = UIImage(named: LQSMessageReadImageName)
                    timestampText = "Read: \(dateFormatter.stringFromDate(message!.receivedAt!))"
                
                case LYRRecipientStatus.Invalid:
                    print("Participant: Invalid")

                default:
                    break
            }
        } else {
            do {
                try message!.markAsRead()
            } catch _ {
            }
            timestampText = "Received: \(dateFormatter.stringFromDate(message!.sentAt!))"
        }
        
        if message!.sender.userID != nil {
            cell.deviceLabel.text = "\(message!.sender.userID) @ \(timestampText)"
        }else {
            cell.deviceLabel.text = "Platform @ \(timestampText)"
        }
    }

    // MARK - Receiving Typing Indicator

    func didReceiveTypingIndicator(notification: NSNotification) {
        // For more information about Typing Indicators, check out https://developer.layer.com/docs/integration/ios#typing-indicator
        
        let dictionary: [String: AnyObject] = notification.userInfo as! [String: AnyObject]
        let participantID = dictionary[LYRTypingIndicatorObjectUserInfoKey];
        let typingIndicator = dictionary[LYRTypingIndicatorObjectUserInfoKey] as! LYRTypingIndicatorAction
        
        
        if (typingIndicator == LYRTypingIndicatorAction.Begin) {
            self.typingIndicatorLabel.alpha = 1
            self.typingIndicatorLabel.text = "\(participantID) is typing..."
        } else {
            self.typingIndicatorLabel.alpha = 0
            self.typingIndicatorLabel.text = ""
        }
    }

    // MARK: - IBActions

    @IBAction func sendMessageAction(sender: UIButton) {
        // Send Message
        sendMessage(inputTextView.text)
        
        // Lower the keyboard
        moveViewUpToShowKeyboard(false)
        inputTextView.resignFirstResponder()
    }

    func sendMessage(messageText: String) {
        // Send a Message
        // See "Quick Start - Send a Message" for more details
        // https://developer.layer.com/docs/quick-start/ios#send-a-message
        
        var messagePart: LYRMessagePart?
        messageImage.image = nil
        // If no conversations exist, create a new conversation object with a single participant
        if self.conversation == nil {
            fetchLayerConversation()
        }
        
        //if we are sending an image
        if (sendingImage) {
            let image: UIImage = self.photo! //get photo
            let imageData: NSData = UIImagePNGRepresentation(image)!
            messagePart = LYRMessagePart(MIMEType: MIMETypeImagePNG, data: imageData)
            sendingImage = false
        } else {
            //Creates a message part with text/plain MIME Type
            messagePart = LYRMessagePart(text: messageText)
        }
        
        // Creates and returns a new message object with the given conversation and array of message parts
        let pushMessage = "\(layerClient?.authenticatedUser?.userID) says \(messageText)"
        
        let defaultConfiguration: LYRPushNotificationConfiguration = LYRPushNotificationConfiguration();
        defaultConfiguration.alert = pushMessage;
        defaultConfiguration.category = LQSCategoryIdentifier;
        // The following dictionary will appear in push payload
        defaultConfiguration.data = [ "test_key": "test_value"];
        let pushOptions = [LYRMessageOptionsPushNotificationConfigurationKey: defaultConfiguration] as? LYRMessageOptions
        let message: LYRMessage? = try? layerClient!.newMessageWithParts([messagePart!], options: pushOptions)
        
        // Sends the specified message
        var error: NSError?
        let success: Bool
        do {
            try conversation!.sendMessage(message!)
            success = true
        } catch let error1 as NSError {
            error = error1
            success = false
        }
        if success {
            // If the message was sent by the participant, show the sentAt time and mark the message as read
            print("Message queued to be sent: \(messageText)")
            inputTextView.text = ""
            
        } else {
            print("Message send failed: \(error)")
        }
        self.photo = nil
        
        if queryController == nil {
            setupQueryController()
        }
    }

    // MARK: - Set up for Shake

    override func canBecomeFirstResponder() -> Bool {
        return true
    }

    override func motionEnded(motion: UIEventSubtype, withEvent event: UIEvent?) {
        // If user shakes the phone, change the navbar color and set metadata
        if motion == UIEventSubtype.MotionShake {
            let newNavBarBackgroundColor: UIColor = LSRandomColor()
            self.navigationController!.navigationBar.barTintColor = newNavBarBackgroundColor
            
            var redFloat: CGFloat = 0.0
            var greenFloat: CGFloat = 0.0
            var blueFloat: CGFloat = 0.0
            var alpha: CGFloat = 0.0
            newNavBarBackgroundColor.getRed(&redFloat, green: &greenFloat, blue: &blueFloat, alpha: &alpha)
            
            // For more information about Metadata, check out https://developer.layer.com/docs/integration/ios#metadata
            let metadata = [ LQSBackgroundColorMetadataKey : [
                                                LQSRedBackgroundColor : "\(redFloat)",
                                                LQSGreenBackgroundColor : "\(greenFloat)",
                                                LQSBlueBackgroundColor : "\(blueFloat)"]
                                        ]
            conversation!.setValuesForMetadataKeyPathsWithDictionary(metadata, merge: true)
        }
    }

    // MARK: - TextView Delegate Methods

    func textViewDidBeginEditing(textView: UITextView) {
        // For more information about Typing Indicators, check out https://developer.layer.com/docs/integration/ios#typing-indicator
        
        // Sends a typing indicator event to the given conversation.
        conversation!.sendTypingIndicator(LYRTypingIndicatorAction.Begin)
        moveViewUpToShowKeyboard(true)
    }

    func textViewDidEndEditing(textView: UITextView) {
        // Sends a typing indicator event to the given conversation.
        conversation!.sendTypingIndicator(LYRTypingIndicatorAction.Finish)
    }

    // Move up the view when the keyboard is shown
    func moveViewUpToShowKeyboard(movedUp: Bool) {
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(0.3)
        
        var rect: CGRect = view.frame
        if movedUp {
            if rect.origin.y == 0 {
                rect.origin.y = view.frame.origin.y - LQSKeyboardHeight
            }
        } else {
            if rect.origin.y < 0 {
                rect.origin.y = view.frame.origin.y + LQSKeyboardHeight
            }
        }
        view.frame = rect
        UIView.commitAnimations()
    }

    // If the user hits Return then dismiss the keyboard and move the view back down
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            inputTextView.resignFirstResponder()
            moveViewUpToShowKeyboard(false)
            return false
        }
        
        let limit: Int = LQSMaxCharacterLimit
        return !(inputTextView.text.characters.count > limit && text.characters.count > range.length)
    }

    // MARK:- Query Controller Delegate Methods

    func queryControllerWillChangeContent(queryController: LYRQueryController) {
        tableView.beginUpdates()
    }

    func queryController(controller: LYRQueryController, didChangeObject object: AnyObject, atIndexPath indexPath: NSIndexPath!, forChangeType type: LYRQueryControllerChangeType, newIndexPath: NSIndexPath!) {
        // Automatically update tableview when there are change events
        switch (type) {
            case LYRQueryControllerChangeType.Insert:
                tableView.insertRowsAtIndexPaths([newIndexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
            case LYRQueryControllerChangeType.Update:
                tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
            case LYRQueryControllerChangeType.Move:
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
                tableView.insertRowsAtIndexPaths([newIndexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
            case LYRQueryControllerChangeType.Delete:
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
        }
    }

    func queryControllerDidChangeContent(queryController: LYRQueryController) {
        tableView.endUpdates()
        scrollToBottom()
    }

    // MARK: - Layer Sync Notification Handler

    func didReceiveLayerClientWillBeginSynchronizationNotification(notification: NSNotification) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
    }

    func didReceiveLayerClientDidFinishSynchronizationNotification(notification: NSNotification) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
    }

    // MARK: - Layer Object Change Notification Handler

    func didReceiveLayerObjectsDidChangeNotification(notification: NSNotification) {
        // Get nav bar colors from conversation metadata
        setNavbarColorFromConversationMetadata(conversation?.metadata)
        fetchLayerConversation()
    }

    // MARK: - General Helper Methods

    func scrollToBottom() {
        let messages: Int = numberOfMessages()
        
        if self.conversation != nil && messages > 0 {
            let numberOfRowsInSection = tableView.numberOfRowsInSection(0)
            if numberOfRowsInSection > 0 {
                let ip: NSIndexPath = NSIndexPath(forRow: numberOfRowsInSection - 1, inSection: 0)
                tableView.scrollToRowAtIndexPath(ip, atScrollPosition: UITableViewScrollPosition.Top, animated: true)
            }
        }
    }

    func setNavbarColorFromConversationMetadata(metadata: NSDictionary?) {
        // For more information about Metadata, check out https://developer.layer.com/docs/integration/ios#metadata
        if let metadata = metadata as? [String : CGFloat] {
            if metadata[LQSBackgroundColorMetadataKey] == nil {
                return
            }
            let redColor: CGFloat = metadata[LQSRedBackgroundColorMetadataKeyPath]! as CGFloat
            let blueColor: CGFloat = metadata[LQSBlueBackgroundColorMetadataKeyPath]! as CGFloat
            let greenColor: CGFloat = metadata[LQSGreenBackgroundColorMetadataKeyPath]! as CGFloat
            navigationController!.navigationBar.barTintColor = UIColor(red: redColor, green: greenColor, blue: blueColor, alpha: 1.0)
        }
    }

//    @IBAction func CameraButtonSelected(sender: UIBarButtonItem) {
//        let picker = UIImagePickerController()
//        picker.delegate = self
//        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera) {
//            picker.sourceType = UIImagePickerControllerSourceType.Camera
//        } else if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.SavedPhotosAlbum) {
//            picker.sourceType = UIImagePickerControllerSourceType.SavedPhotosAlbum
//        }
//        self.presentViewController(picker, animated: true, completion: nil)
//    }

    func numberOfMessages() -> Int {
        let message: LYRQuery = LYRQuery(queryableClass: LYRMessage.self)
        
        let messageList: NSOrderedSet?
        do {
            messageList = try layerClient?.executeQuery(message)
        } catch _ {
            messageList = nil
        }
        
        return messageList != nil ? messageList!.count : 0
    }

    @IBAction func clearButtonPressed(sender: UIBarButtonItem) {
        let alert: UIAlertView = UIAlertView(title: "Delete messages?",
                                             message: "This action will clear all your current messages. Are you sure you want to do this?",
                                             delegate: self,
                                             cancelButtonTitle: "NO",
                                             otherButtonTitles: "Yes")
        alert.show()
    }

    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: NSInteger) {
        if buttonIndex == 1 {
            clearMessages()
        }
    }

    func clearMessages() {
        let message: LYRQuery = LYRQuery(queryableClass: LYRMessage.self)
        
        let messageList: NSOrderedSet?
        do {
            messageList = try layerClient!.executeQuery(message)
        } catch _ {
            messageList = nil
        }
        let error: NSErrorPointer = nil
        
        if messageList?.count > 0 {
            
            for (var i = 0; i < messageList?.count; i += 1) {
                let message: LYRMessage = messageList?.objectAtIndex(i) as! LYRMessage
                let success = message.delete(LYRDeletionMode.AllParticipants, error: error)
                
                print("Message is: \(message.parts)")

                if (success) {
                    print("The message has been deleted")
                } else {
                    print("Error")
                }
            }
        } else {
            print("Failed querying for messages: %@", error);
        }
        photo = nil
        sendingImage = false
    }

    @IBAction func cameraButtonPressed(sender: UIBarButtonItem) {
        inputTextView.text = ""
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
        
        presentViewController(picker, animated: true, completion: nil)
    }

    // MARK: - UIImagePickerControllerDelegate

    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        self.sendingImage = true
        var image = info[UIImagePickerControllerEditedImage] as! UIImage!
        
        if image == nil {
            image = info[UIImagePickerControllerOriginalImage] as! UIImage!
        }
        self.photo = image
        dismissViewControllerAnimated(true, completion: nil)
        
        messageImage.image = image
    }


    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        print("Cancel")
        dismissViewControllerAnimated(true, completion: nil)
        self.sendingImage = false
    }
    
    //  MARK: - Segue method

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if sender?.isKindOfClass(UIButton.self) != nil {
            if segue.destinationViewController.isKindOfClass(LQSAnnouncementsTableViewController.self) {
                let anncementsController: LQSAnnouncementsTableViewController = segue.destinationViewController as! LQSAnnouncementsTableViewController
                anncementsController.layerClient = layerClient
            }
        }
    }
}
