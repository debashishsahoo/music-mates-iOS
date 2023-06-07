//
//  ChatViewController.swift
//  MusicMates
//
//  Created by Debashish Sahoo on 29/5/2023.
//
//  References:
//  "MessageKit": https://messagekit.github.io
//  "MessageKit Github": https://github.com/MessageKit/MessageKit
//  "3 Ways to Generate Random Strings in Swift": https://www.slingacademy.com/article/ways-to-generate-random-strings-in-swift/

import UIKit
import MessageKit
import InputBarAccessoryView
import Firebase
import FirebaseFirestore

/// View controller for the Chat Screen between two users
class ChatViewController: MessagesViewController, MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate, InputBarAccessoryViewDelegate {
    
    var currentUser: User = Auth.auth().currentUser!
    var messagesList = [ChatMessage]()

    var otherUserName: String?
    var otherUserUID: String?
    
    var chatRef: DocumentReference?
    
    /// Date formatter for displaying the date/time of a chat message
    let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeZone = .current
        formatter.dateFormat = "HH:mm dd/MM/yy"
        return formatter
    }()
    
    var database: Firestore?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        database = Firestore.firestore()
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messageInputBar.delegate = self
        
        scrollsToLastItemOnKeyboardBeginsEditing = true
        maintainPositionOnInputBarHeightChanged = true

        navigationItem.title = otherUserName
        
        // Get all the chat messages
        fetchChatMessages()
        
    }
    
    /// Fetches chat messages to display between the two users
    func fetchChatMessages() {
            
        // Get chats from database which contains the current user
        database?.collection("chats").whereField("users", arrayContains: Auth.auth().currentUser?.uid ?? "").getDocuments { (chatsQuerySnapshot, error) in
            
            if let error = error {
                print(error)
                return
            }
                         
            // Get chat data for the current user if chats exist
            if (chatsQuerySnapshot?.documents.count)! > 0 {
                for chatDocumentSnapshot in chatsQuerySnapshot!.documents {
                    
                    let chat = Chat(users: chatDocumentSnapshot.data()["users"] as! [String])
                    
                    // Retrieve the chat with the other user
                    if (chat.users.contains(self.otherUserUID ?? "")) == true {
                        self.chatRef = chatDocumentSnapshot.reference
                        // Retrieve all the messages in the chat between the two users and sort them by the time sent
                        self.chatRef?.collection("messages").order(by: "time").addSnapshotListener() { (querySnapshot, error) in
                            if let error = error {
                                print(error)
                                return
                            }
                            self.messagesList.removeAll()
                            for messageDocumentSnapshot in querySnapshot!.documents {
                                let messageData = messageDocumentSnapshot.data()
                                
                                // Retrieve all the message data
                                let messageId = messageData["id"] as! String
                                let senderId = messageData["senderId"] as! String
                                let senderName = messageData["senderName"] as! String
                                let sender = Sender(senderId: senderId, displayName: senderName)
                                let sentTimestamp = messageData["time"] as! Timestamp
                                let sentDate = sentTimestamp.dateValue()
                                let messageText = messageData["text"] as! String
                                
                                // Create a chat message object with the data retrieved and add it to the list of messages
                                let message = ChatMessage(sender: sender, messageId: messageId, sentDate: sentDate, message: messageText)
                                self.messagesList.append(message)
                            }
                            
                            // Reload the messages collection view and scroll down to the latest message
                            self.messagesCollectionView.reloadData()
                            self.messagesCollectionView.scrollToLastItem(at: .bottom, animated: true)
                        }
                        return
                    }
                }
                // If chats don't exist with the other user, create a new chat with the other user
                self.createChat()
            } else {
                // If chats don't exist at all for the current user, create a new chat with the other user
                self.createChat()
            }
        }
    }
    
    /// Create a new chat between the two users
    func createChat() {
        self.database?.collection("chats").addDocument(data: ["users": [self.currentUser.uid, self.otherUserUID]]) { (error) in
            if let error = error {
                print(error)
                return
            }
            // Fetch all the messages for this new chat
            self.fetchChatMessages()
        }
    }
    
    /// Adds and saves the message sent by the user in the input bar to the chat
    /// - Parameters:
    ///   - inputBar: The input bar
    ///   - text: The chat message entered by the user
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        let message = ChatMessage(sender: currentSender as! Sender, messageId: UUID().uuidString, sentDate: Timestamp().dateValue(), message: text)

        // Add message to the chat view
        messagesList.append(message)
        
        // Reload the messages collection view and scroll down to the latest message
        messagesCollectionView.reloadData()
        messagesCollectionView.scrollToLastItem(at: .bottom, animated: true)
        
        // Add the message to the database
        chatRef?.collection("messages").addDocument(data: [
            "senderId": message.sender.senderId,
            "senderName": message.sender.displayName,
            "text": text,
            "time": message.sentDate,
            "id": message.messageId
        ])
        
        // Clear the input bar text field
        inputBar.inputTextView.text = ""
    }
    
    
    /// Gets a specific message item at a specified index path
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messagesList[indexPath.section]
    }
    
    /// Used to get the current sender/user, which enables the view controller to display messages differently based on if the current user has sent them (left/right)
    var currentSender: SenderType {
        return Sender(senderId: Auth.auth().currentUser!.uid, displayName: "N/A")
    }
    
    /// Returns the number of messages to display in the chat
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messagesList.count
    }
    
    /// Displays the date and time below each text message
    func messageBottomLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        let dateString = formatter.string(from: message.sentDate)
        return NSAttributedString(string: dateString, attributes: [NSAttributedString.Key.font:UIFont.preferredFont(forTextStyle: .caption2)])
    }
    
    /// Sets the height of the label that displays the date and time below each text message
    func messageBottomLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 16
    }
    
    /// Customizes the style of the message based on whether the current user has sent the messages or not (left/right)
    func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
        let tail: MessageStyle.TailCorner = isFromCurrentSender(message: message) ? .bottomRight: .bottomLeft
        return .bubbleTail(tail, .curved)
    }
    
    /// Sets the avatar next to each chat message to the user's profile picture (default profile picture)
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        avatarView.image = UIImage(systemName: "person.circle.fill", withConfiguration: UIImage.SymbolConfiguration(paletteColors: [.white, .systemBlue]))
    }

    /// Sets the background color of each chat message differently for the current user and the other user
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return isFromCurrentSender(message: message) ? .systemTeal: .systemGray5
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
