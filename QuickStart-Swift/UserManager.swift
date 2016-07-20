import Foundation
import LayerKit

class UserManager {
    static let sharedManager = UserManager()
    var userCache: NSCache = NSCache()
    
    
//    let cache = NSCache()
//    let myObject: ExpensiveObjectClass
//    
//    if let cachedVersion = cache.objectForKey("CachedObject") as? ExpensiveObjectClass {
//        // use the cached version
//        myObject = cachedVersion
//    } else {
//    // create it from scratch then store in the cache
//    myObject = ExpensiveObjectClass()
//    cache.setObject(myObject, forKey: "CachedObject")
//    }
    
    
    // MARK Query Methods
//    func queryForUserWithName(searchText: String, completion: ((NSArray?, NSError?) -> Void)) {
//        
//        let query: PFQuery! = User.query()
//        query.whereKey("userID", notEqualTo: User.currentUser()!.userID!)
//        
//        query.findObjectsInBackgroundWithBlock { objects, error in
//            var contacts = [User]()
//            if (error == nil) {
//                for user: User in (objects as! [User]) {
//                    if user.displayName.rangeOfString(searchText, options: NSStringCompareOptions.CaseInsensitiveSearch) != nil {
//                        contacts.append(user)
//                    }
//                }
//            }
//            completion(contacts, error)
//        }
//    }
//    
//    func queryForAllUsersWithCompletion(completion: ((NSArray?, NSError?) -> Void)?) {
//        let query: PFQuery! = User.query()
//        query.whereKey("userID", notEqualTo: User.currentUser()!.userID!)
//        query.findObjectsInBackgroundWithBlock { objects, error in
//            if let callback = completion {
//                callback(objects, error)
//            }
//        }
//    }
//    
//    func queryAndCacheUsersWithIDs(userIDs: [String], completion: ((NSArray?, NSError?) -> Void)?) {
//        let query: PFQuery! = User.query()
//        query.whereKey("userID", containedIn: userIDs)
//        query.findObjectsInBackgroundWithBlock { objects, error in
//            if (error == nil) {
//                for user: User in (objects as! [User]) {
//                    self.cacheUserIfNeeded(user)
//                }
//            }
//            if let callback = completion {
//                callback(objects, error)
//            }
//        }
//    }
//    
    func cachedUserForUserID(userID: NSString) -> User? {
        if self.userCache.objectForKey(userID) != nil {
            return self.userCache.objectForKey(userID) as! User?
        }
        return nil
    }
    
    func cacheUserIfNeeded(user: User) {
        if self.userCache.objectForKey(user.userID) == nil {
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