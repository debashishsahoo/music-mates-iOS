//
//  Message.swift
//  MusicMates
//
//  Created by Debashish Sahoo on 29/5/2023.
//

import Foundation
import UIKit
import Firebase
import MessageKit

// Represents a chat message
class ChatMessage: MessageType {
    var sender: SenderType
    var messageId: String
    var sentDate: Date
    var kind: MessageKind
    
    init(sender: Sender, messageId: String, sentDate: Date, message: String) {
        self.sender = sender
        self.messageId = messageId
        self.sentDate = sentDate
        self.kind = .text(message)
    }
}
