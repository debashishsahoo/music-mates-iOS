//
//  FirebaseController.swift
//  MusicMates
//
//  Created by Debashish Sahoo on 3/5/2023.
//


import UIKit

import Firebase
import FirebaseFirestoreSwift

import SafariServices

/// Controls the Firestore database on Firebase and contains methods of getting/setting data in the database
class FirebaseController: NSObject, DatabaseProtocol {
    //  References to the Firebase Authentication System, the Firebase Firestore Database and references for documents/collections
    var authController: Auth
    var database: Firestore
    
    var usersRef: CollectionReference?
    var userRef: DocumentReference?
    var currentUser: User?
    
    weak var homeScreen: HomeCollectionViewController?
    
    /// Initialize class with reference to the Firebase Firestore database
    override init() {
        FirebaseApp.configure()
        authController = Auth.auth()
        database = Firestore.firestore()
                       
        super.init()
    }
    
    /// Retrieving a user's data from databse
    /// - Parameters:
    ///   - uid: Unique UID of the user
    ///   - completion: Completion of retrieving user data
    func getUserData(uid: String, completion: @escaping ([String: Any?]) -> Void) {
        usersRef = database.collection("users")
        userRef = usersRef?.document(uid)
        
        userRef?.getDocument { (document, error) in
            if let document = document, document.exists {
                let userData = document.data()
                completion(userData!)
            } else {
                print("Document does not exist")
            }
        }
        
    }
    
    /// Retrieving all user's data from database
    /// - Parameter completion: Completion of retrieving user data
    func getDiscoverFriendsData(completion: @escaping ([QueryDocumentSnapshot]) -> Void) {
        usersRef = database.collection("users")
        
        usersRef?.getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                let usersData = querySnapshot!.documents
                completion(usersData)
            }
        }

    }
    
    /// Setting a user's data with given input
    /// - Parameters:
    ///   - uid: Unique UID of the user
    ///   - data: Data to set in the form of a dictionary
    func setUserData(uid: String, data: [String: Any]) {
        usersRef = database.collection("users")
        userRef = usersRef?.document(uid)
        
        userRef?.setData(data)
    }
    
    /// Updating a user's data with given input
    /// - Parameters:
    ///   - uid: Unique UID of the user
    ///   - data: Data to update in the form of a dictionary
    func updateUserData(uid: String, data: [String: Any]) {
        usersRef = database.collection("users")
        userRef = usersRef?.document(uid)
        
        userRef?.updateData(data)
    }
    
    /// Handle unfriend action
    /// - Parameters:
    ///   - fromUid: Unique UID of user who unfriends
    ///   - toUid: Unique UID of user who is unfriended
    func handleUnfriend(fromUid: String, toUid: String) {
        usersRef = database.collection("users")
        
        let fromUserRef = usersRef?.document(fromUid)
        let toUserRef = usersRef?.document(toUid)
        
        fromUserRef?.updateData(["friends": FieldValue.arrayRemove([toUserRef!])])
        toUserRef?.updateData(["friends": FieldValue.arrayRemove([fromUserRef!])])
    }
    
    /// Handle friend request sent action
    /// - Parameters:
    ///   - fromUid: Unique UID of user who sent the friend request
    ///   - toUid: Unique UID of user who received the friend request
    func handleFriendRequestSent(fromUid: String, toUid: String) {
        usersRef = database.collection("users")
        
        let fromUserRef = usersRef?.document(fromUid)
        let toUserRef = usersRef?.document(toUid)
        
        fromUserRef?.updateData(["requestsSent": FieldValue.arrayUnion([toUserRef!])])
        toUserRef?.updateData(["requestsReceived": FieldValue.arrayUnion([fromUserRef!])])
    }
    
    /// Handle friend request sent action
    /// - Parameters:
    ///   - fromUid: Unique UID of user who unsent the friend request
    ///   - toUid: Unique UID of user who had received the friend request
    func handleFriendRequestUnsent(fromUid: String, toUid: String) {
        usersRef = database.collection("users")
        
        let fromUserRef = usersRef?.document(fromUid)
        let toUserRef = usersRef?.document(toUid)
        
        fromUserRef?.updateData(["requestsSent": FieldValue.arrayRemove([toUserRef!])])
        toUserRef?.updateData(["requestsReceived": FieldValue.arrayRemove([fromUserRef!])])
    }
    
    /// Handle friend request sent action
    /// - Parameters:
    ///   - fromUid: Unique UID of user who sent the friend request
    ///   - toUid: Unique UID of user who received the friend request
    func handleFriendRequestAccepted(fromUid: String, toUid: String) {
        usersRef = database.collection("users")
        
        let fromUserRef = usersRef?.document(fromUid)
        let toUserRef = usersRef?.document(toUid)
        
        fromUserRef?.updateData(["requestsSent": FieldValue.arrayRemove([toUserRef!])])
        toUserRef?.updateData(["requestsReceived": FieldValue.arrayRemove([fromUserRef!])])
        
        fromUserRef?.updateData(["friends": FieldValue.arrayUnion([toUserRef!])])
        toUserRef?.updateData(["friends": FieldValue.arrayUnion([fromUserRef!])])
    }
    
    /// Handle friend request sent action
    /// - Parameters:
    ///   - fromUid: Unique UID of user who sent the friend request
    ///   - toUid: Unique UID of user who received the friend request
    func handleFriendRequestDeclined(fromUid: String, toUid: String) {
        usersRef = database.collection("users")
        
        let fromUserRef = usersRef?.document(fromUid)
        let toUserRef = usersRef?.document(toUid)
        
        fromUserRef?.updateData(["requestsSent": FieldValue.arrayRemove([toUserRef!])])
        toUserRef?.updateData(["requestsReceived": FieldValue.arrayRemove([fromUserRef!])])
    }
}
