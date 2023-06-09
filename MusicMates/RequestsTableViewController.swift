//
//  RequestsTableViewController.swift
//  MusicMates
//
//  Created by Debashish Sahoo on 23/5/2023.
//

import UIKit
import Firebase
import FirebaseFirestoreSwift

/// View Controller for the Friend Requests Screen
class RequestsTableViewController: UITableViewController {

    let SECTION_REQUESTS = 0
    let SECTION_INFO = 1

    let CELL_REQUEST = "requestCell"
    let CELL_INFO = "infoCell"
    
    var requestsList: [[String: Any?]] = []
    
    weak var databaseController: DatabaseProtocol?
    var authController: Auth?
    
    let tabelRefreshControl = UIRefreshControl()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Get a reference to the database from the appDelegate
        let appDelegate = (UIApplication.shared.delegate as? AppDelegate)
        databaseController = appDelegate?.databaseController
        
        authController = Auth.auth()
        
        // Set up table refreshing feature
        self.refreshControl = tabelRefreshControl
        tabelRefreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        fetchAllData() // Fetch all table data
    }

    /// Refresh table data by swiping down
    @objc func refreshData() {
        // Fetch all table data
        fetchAllData()
        tabelRefreshControl.endRefreshing()
    }
    
    /// Fetch table data
    func fetchAllData() {
        getRequestsData()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == SECTION_REQUESTS {
            return requestsList.count
        } else {
            return 1
        }
    }

    // Display the user's friend requests and the count
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == SECTION_REQUESTS {
            let requestCell = tableView.dequeueReusableCell(withIdentifier: CELL_REQUEST, for: indexPath)
            var content = requestCell.defaultContentConfiguration()
            let firstName =  requestsList[indexPath.row]["firstname"] as! String
            let lastName = requestsList[indexPath.row]["lastname"] as! String
            content.text = firstName + " " + lastName
            requestCell.contentConfiguration = content
            return requestCell
        } else {
            let infoCell = tableView.dequeueReusableCell(withIdentifier: CELL_INFO, for: indexPath)
            var content = infoCell.defaultContentConfiguration()
            if requestsList.isEmpty {
                content.text = "No Friend Requests At The Moment."
            } else {
                content.text = "\(requestsList.count) Friend Request(s)"
            }
            infoCell.contentConfiguration = content
            return infoCell
        }
    }
    
    /// Get list of friend requests for the current user
    func getRequestsData() {
        databaseController?.getUserData(uid: (authController?.currentUser?.uid)!) { (userData) in
            let requestsReceived = userData["requestsReceived"] as! [Any]
            self.requestsList.removeAll()
            var count = 0
            for friend in requestsReceived {
                count += 1
                self.databaseController?.getUserData(uid: (friend as AnyObject).documentID) { (userData) in
                    self.requestsList.append(userData)
                    if count == requestsReceived.count {
                        DispatchQueue.main.async {
                            self.tableView.reloadData()
                        }
                    }
                }
            }
        }
    }
    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    /// Add swipe options to Accept and Decline each friend request
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let requestData = requestsList[indexPath.row]
        let requestUid = requestData["uid"] as! String
        
        let accept = UIContextualAction(style: .normal, title: "Accept") { (action, view, completionHandler) in
            self.databaseController?.handleFriendRequestAccepted(fromUid: requestUid, toUid: (self.authController?.currentUser!.uid)! as String)
            self.requestsList.remove(at: indexPath.row)
            
            tableView.performBatchUpdates({
                self.tableView.deleteRows(at: [indexPath], with: .fade)
                self.tableView.reloadData()
            }, completion: nil)

            self.displayMessage(title: "Friend Request Accepted", message: "You've got a new friend!")
            completionHandler(true)
        }
        accept.backgroundColor = .systemGreen

        let decline = UIContextualAction(style: .destructive, title: "Decline") { (action, view, completionHandler) in
            self.databaseController?.handleFriendRequestDeclined(fromUid: requestUid, toUid: (self.authController?.currentUser!.uid)! as String)
            self.requestsList.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            tableView.reloadData()
            self.displayMessage(title: "Friend Request Rejected", message: "Not who you're looking for, it seems..")
            completionHandler(true)
        }
        decline.backgroundColor = .systemRed
        
        let configuration = UISwipeActionsConfiguration(actions: [accept, decline])

        return configuration
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Segue to the list of favourite artists for the particular friend clicked on
        if segue.identifier == "friendArtistsSegue" {
            if let cell = sender as? UITableViewCell, let indexPath = tableView.indexPath(for: cell) {
                let friendData = requestsList[indexPath.row]
                let friendName = friendData["firstname"] as! String
                let friendFavArtists = friendData["favArtists"] as! [[String: String]]
                
                var friendArtistNames: [String] = []
                for artist in friendFavArtists {
                    friendArtistNames.append(artist["name"]!)
                }
                
                let controller = segue.destination as! FriendMusicTasteTableViewController
                controller.friendName = friendName
                controller.friendArtistsList = friendArtistNames
            }
        }
    }
}
