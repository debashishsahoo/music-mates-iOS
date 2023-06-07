//
//  ChatUser.swift
//  MusicMates
//
//  Created by Debashish Sahoo on 29/5/2023.
//

import Foundation
import MessageKit

class Sender: SenderType {
    var senderId: String
    var displayName: String
    
    init(senderId: String, displayName: String) {
        self.senderId = senderId
        self.displayName = displayName
    }
}

