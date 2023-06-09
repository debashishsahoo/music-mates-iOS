//
//  FriendsTableViewController.swift
//  MusicMates
//
//  Created by Debashish Sahoo on 16/5/2023.
//

import UIKit
import Firebase
import FirebaseFirestoreSwift

/// View Controller for the user's Friends Screen
class FriendsTableViewController: UITableViewController {
    
    let SECTION_FRIENDS = 0
    let SECTION_INFO = 1
    
    let CELL_FRIEND = "friendCell"
    let CELL_INFO = "infoCell"
    
    var friendsList: [[String: Any?]] = []
        
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
    
    /// Refresh table data by swiping down
    @objc func refreshData() {
        fetchAllData()
        tabelRefreshControl.endRefreshing()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        fetchAllData()
    }
    
    /// Fetch table data
    func fetchAllData() {
        getFriendsData()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == SECTION_FRIENDS {
            return friendsList.count
        } else {
            return 1
        }
    }

    // Display the user's friends and the count
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == SECTION_FRIENDS {
            let friendCell = tableView.dequeueReusableCell(withIdentifier: CELL_FRIEND, for: indexPath)
            var content = friendCell.defaultContentConfiguration()
            let firstName =  friendsList[indexPath.row]["firstname"] as! String
            let lastName = friendsList[indexPath.row]["lastname"] as! String
            content.text = firstName + " " + lastName
            friendCell.contentConfiguration = content
            return friendCell
        } else {
            let infoCell = tableView.dequeueReusableCell(withIdentifier: CELL_INFO, for: indexPath)
            var content = infoCell.defaultContentConfiguration()
            if friendsList.isEmpty {
                content.text = "No Friends. Head to the Discover Page."
            } else {
                content.text = "\(friendsList.count) Friends(s)"
            }
            infoCell.contentConfiguration = content
            return infoCell
        }
    }
    
    /// Get user data for all friends of the current user from Firebase
    func getFriendsData() {
        databaseController?.getUserData(uid: (authController?.currentUser?.uid)!) { (userData) in
            let friends = userData["friends"] as! [Any]
            self.friendsList.removeAll()
            var count = 0
            for friend in friends {
                count += 1
                self.databaseController?.getUserData(uid: (friend as AnyObject).documentID) { (userData) in
                    self.friendsList.append(userData)
                    if count == friends.count {
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
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    /// Add swipe options to Unfriend a friend
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let friendData = friendsList[indexPath.row]
        let friendUid = friendData["uid"] as! String
        
        let unfriend = UIContextualAction(style: .destructive, title: "Unfriend") { (action, view, completionHandler) in
            self.databaseController?.handleUnfriend(fromUid: (self.authController?.currentUser!.uid)! as String, toUid: friendUid)
            self.displayMessage(title: "Unfriend Complete", message: "Time to make some new friends?")
            self.friendsList.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            completionHandler(true)
        }
        unfriend.backgroundColor = .systemRed
        
        let configuration = UISwipeActionsConfiguration(actions: [unfriend])
        return configuration
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Segue to the list of favourite artists for the particular friend clicked on
        if segue.identifier == "friendArtistsSegue" {
            if let cell = sender as? UITableViewCell, let indexPath = tableView.indexPath(for: cell) {
                let friendData = friendsList[indexPath.row]
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
    
    
    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

}
