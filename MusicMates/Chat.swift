//
//  Chat.swift
//  MusicMates
//
//  Created by Debashish Sahoo on 29/5/2023.
//

import Foundation

// Represents a chat channel between two users
class Chat: NSObject {
    var users: [String]

    init(users: [String]) {
        self.users = users
    }
}

