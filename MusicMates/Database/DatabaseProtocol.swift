//
//  DatabaseProtocol.swift
//  MusicMates
//
//  Created by Debashish Sahoo on 3/5/2023.
//

import Foundation
import Firebase
import FirebaseFirestoreSwift


/// Protocol that contains methods that the Firebase Controller should implement
protocol DatabaseProtocol: AnyObject {

    func login(email: String, password: String)
    func signup(firstName: String, lastName: String, email: String, password: String)
    
    func getUserData(uid: String, completion: @escaping ([String: Any?]) -> Void)
    func getDiscoverFriendsData(completion: @escaping ([QueryDocumentSnapshot]) -> Void)
    
    func setUserData(uid: String, data: [String: Any])
    func updateUserData(uid: String, data: [String: Any])
    
    func handleUnfriend(fromUid: String, toUid: String)
    func handleFriendRequestSent(fromUid: String, toUid: String)
    func handleFriendRequestUnsent(fromUid: String, toUid: String)
    func handleFriendRequestAccepted(fromUid: String, toUid: String)
    func handleFriendRequestDeclined(fromUid: String, toUid: String)
}
