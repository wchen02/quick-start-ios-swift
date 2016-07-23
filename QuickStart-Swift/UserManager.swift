import Foundation
import LayerKit
import Alamofire
import SwiftyJSON

class UserManager {
    static let sharedManager = UserManager()
    var userCache: NSCache = NSCache()
    var users = [User]()
    
    // MARK Query Methods
    func queryForUserWithName(searchText: String, completion: ((NSArray?, NSError?) -> Void)) {
        var contacts = [User]()
        for user in users {
            if user.displayName.rangeOfString(searchText, options: NSStringCompareOptions.CaseInsensitiveSearch) != nil {
                contacts.append(user)
            }
        }
        completion(contacts, nil)
    }
    
    func queryAndCacheUsersWithIDs(userIDs: [String], completion: ((NSArray?, NSError?) -> Void)?) {
        getUsers(userIDs, completion: completion)
    }
    
    func getUsers(userIds: [String], completion: ((NSArray?, NSError?) -> Void)?) {
        var users = [User]()
        
        let apiEndPoint = "http://108.61.159.150/~socialmedia"
        let headers: [String: String] = [
            "Authorization": "Basic YWRtaW46TllUd2ViQDU1MTQ=",
            "Accept": "application/json"
        ]
        
        let params = [
            "action": "getUsers",
            "users": userIds
        ]
        
        Alamofire.request(.POST, "\(apiEndPoint)/wp-content/plugins/cqg-chat/authorize.php", parameters: params as! [String : AnyObject], headers: headers)
            .responseJSON { response in
                if let value = response.result.value {
                    let usersJson = JSON(value)
                    
                    for (_,usersJson2):(String, JSON) in usersJson {
                        for (_,user):(String, JSON) in usersJson2 {
                            let newUser = User(userID: user["id"].string!, firstName: user["name"].string!, lastName: user["name"].string!, avatarUrl: user["avatar"].string!)
                            newUser.displayName = user["name"].string!
                            UserManager.sharedManager.cacheUserIfNeeded(newUser)
                            users.append(newUser)
                            print("\(user)")
                        }
                    }
                    
                    if let callback = completion {
                        callback(users, nil)
                    }
                }
        }
    }
    
    func cachedUserForUserID(userID: NSString) -> User? {
        if self.userCache.objectForKey(userID) != nil {
            return self.userCache.objectForKey(userID) as! User?
        }
        return nil
    }
    
    func cacheUserIfNeeded(user: User) {
        if self.userCache.objectForKey(user.userID) == nil {
            self.users.append(user)
            self.userCache.setObject(user, forKey: user.userID)
        }
    }
    
    func unCachedUserIDsFromParticipants(participants: Set<LYRIdentity>) -> NSArray {
        var array = [String]()
        for user in participants {
            if (user.userID == LQSCurrentUserID) {
                continue
            }
            if self.userCache.objectForKey(user.userID) == nil {
                array.append(user.userID)
            }
        }
        
        return NSArray(array: array)
    }
    
    func resolvedNamesFromParticipants(participants: Set<LYRIdentity>) -> NSArray {
        var array = [String]()
        for user in participants {
            if (user.userID == LQSCurrentUserID) {
                continue
            }
            if self.userCache.objectForKey(user.userID) != nil {
                let user: User = self.userCache.objectForKey(user.userID) as! User
                array.append(user.firstName)
            }
        }
        return NSArray(array: array)
    }
    
}