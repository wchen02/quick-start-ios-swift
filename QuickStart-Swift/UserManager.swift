import Foundation
import LayerKit
import Alamofire

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
    
    func queryAndCacheUsersWithIDs(userIDs: [String], completion: ((NSArray?, NSError?) -> Void)?) {
        for userId in userIDs {
            let user = getUser(userId)
            UserManager.sharedManager.cacheUserIfNeeded(user)
        }
        
        if let callback = completion {
            callback(objects, error)
        }
    }
    
    func getUser(userId: String) -> User {
        let apiEndPoint = "http://108.61.159.150/~socialmedia"
        let headers: [String: String] = [
            "Authorization": "Basic YWRtaW46TllUd2ViQDU1MTQ=",
            "Accept": "application/json"
        ]
        
        Alamofire.request(.GET, "\(apiEndPoint)/wp-json/cqg/v1/user_info", parameters: ["id": userId], headers: headers)
            .responseJSON { response in
                print(response.request)  // original URL request
                print(response.response) // URL response
                print(response.data)     // server data
                print(response.result)   // result of response serialization
                
                if let JSON = response.result.value {
                    print("JSON: \(JSON)")
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