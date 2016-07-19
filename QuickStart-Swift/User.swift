import Foundation
import Atlas

class User: NSObject, ATLParticipant {
    
    @objc var firstName: String {
        return "1"//self.username!
    }
    
    @objc var lastName: String {
        return "Test"
    }
    
    @objc var displayName: String {
        return "\(self.firstName) \(self.lastName)"
    }
    
    @objc var userID: String {
        return "0"
    }
    
    @objc var avatarImageURL: NSURL? {
        return nil
    }
    
    @objc var avatarImage: UIImage? {
        return nil
    }
    
    @objc var avatarInitials: String? {
        let initials = "\(getFirstCharacter(self.firstName))\(getFirstCharacter(self.lastName))"
        return initials.uppercaseString
    }
    
    private func getFirstCharacter(value: String) -> String {
        return (value as NSString).substringToIndex(1)
    }
}