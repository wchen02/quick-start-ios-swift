import Foundation
import Atlas

class User: NSObject, ATLParticipant {
    
    var firstName: String
    
    var lastName: String
    
    var displayName: String
    
    var userID: String
    
    var avatarImageURL: NSURL?
    
    var avatarImage: UIImage?
    
    var avatarInitials: String?

    init(userID: String, firstName: String, lastName: String, avatarUrl: String) {
        self.firstName = firstName
        self.lastName = lastName
        self.displayName = "\(firstName) \(lastName)"
        self.userID = userID
        self.avatarImageURL = NSURL(string: avatarUrl)
    }
    
    private func getFirstCharacter(value: String) -> String {
        return (value as NSString).substringToIndex(1)
    }
}