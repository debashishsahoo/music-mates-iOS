//
//  DiscoverTableViewController.swift
//  MusicMates
//
//  Created by Debashish Sahoo on 17/5/2023.
//

import UIKit
import Firebase
import FirebaseFirestoreSwift
import MapKit

/// View Controller for the Discover Friends Screen
class DiscoverTableViewController: UITableViewController {
    
    var friendsDistanceDict: [String: ([String: Any?], Double, String)] = [:]
    var discoverFriendsList: [([String:Any?], String)] = []
    var friendsList: [String] = []
    var currentUserLocation: CLLocationCoordinate2D?
    var currentUserFriends: Array<DocumentReference>?
    
    let CELL_FRIEND = "friendCell"
    
    weak var databaseController: DatabaseProtocol?
    var authController: Auth?
    
    let tabelRefreshControl = UIRefreshControl()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        // Get a reference to the database from the appDelegate
        let appDelegate = (UIApplication.shared.delegate as? AppDelegate)
        databaseController = appDelegate?.databaseController
        
        authController = Auth.auth()
        
        // Set up table refreshing feature
        self.refreshControl = tabelRefreshControl
        tabelRefreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        DispatchQueue.main.async {
            self.fetchAllData()
        }
    }
    
    /// Refresh table data by swiping down
    @objc func refreshData() {
        fetchAllData()
        tabelRefreshControl.endRefreshing()
    }
        
    /// Fetch table data
    func fetchAllData() {
        friendsList = []
        discoverFriendsList = []
        getCurrentUserLocation()
        getDiscoverFriendsData()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return discoverFriendsList.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Configure and return artist cell
        let friendCell = tableView.dequeueReusableCell(withIdentifier: CELL_FRIEND, for: indexPath)
                
        let friendData = discoverFriendsList[indexPath.row].0
        let friendRequestsReceived = friendData["requestsReceived"] as! Array<DocumentReference>
        
        // Show if the current user has already sent a friend request to one of the users on the Discover Friends list
        var friendRequestStatus = ""
        for userRef in friendRequestsReceived {
            if userRef.documentID == authController?.currentUser?.uid {
                friendRequestStatus = "Friend Request Sent"
                break
            }
        }

        var content = friendCell.defaultContentConfiguration()
        content.text = discoverFriendsList[indexPath.row].1
        content.secondaryText = friendRequestStatus
        friendCell.contentConfiguration = content
        
        friendCell.accessoryType = .detailButton
        
        return friendCell
    }
        
    /// Get current user's location
    func getCurrentUserLocation() {
        databaseController?.getUserData(uid: (authController?.currentUser?.uid)!) { (userData) in
            let location = userData["location"] as! GeoPoint
            self.currentUserLocation = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
        }
    }
    
    /// Get current user's friends
    func getCurrentUserFriends() {
        databaseController?.getUserData(uid: (authController?.currentUser?.uid)!) { (userData) in
            let friends = userData["friends"] as! Array<DocumentReference>
            DispatchQueue.main.async {
                self.currentUserFriends = friends
            }
        }
    }
    
    /// Get nearby users and their location and sort them by their distance from the current user
    func getDiscoverFriendsData() {
        databaseController?.getDiscoverFriendsData() { (usersData) in
            for user in usersData {
                // Don't display the current user in the discover users page
                if (user.documentID != self.authController?.currentUser?.uid) {
                    self.databaseController?.getUserData(uid: (self.authController?.currentUser?.uid)!) { (userData) in
                        let friends = userData["friends"] as! Array<DocumentReference>
                        // Don't display a user in the discover users page if they are already a friend of the current user
                        if !(friends.contains(user.reference)) {
                            self.databaseController?.getUserData(uid: user.documentID) { (userData) in
                                self.discoverFriendsList = []
                                
                                let firstName = userData["firstname"] as! String
                                let lastName = userData["lastname"] as! String
                                
                                let location = userData["location"] as! GeoPoint
                                let latitude = location.latitude
                                let longitude = location.longitude
                                
                                let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                                
                                let distance_from_current_user = round((MKMapPoint(self.currentUserLocation!).distance(to: MKMapPoint(coordinate))/1000) * 100) / 100.0
                                
                                let string = firstName + " " + lastName + " — \(String(distance_from_current_user)) km"
                                self.friendsDistanceDict[user.documentID] = (userData, distance_from_current_user, string)  // Use a tuple for each value of the dict which also holds the string to append
                                
                                self.friendsList.append(user.documentID)
                                
                                let sortedFriendsList = self.friendsList.sorted(by: { lhs, rhs in
                                    return self.friendsDistanceDict[lhs]!.1 < self.friendsDistanceDict[rhs]!.1
                                })

                                self.friendsList = sortedFriendsList
                                
                                for id in self.friendsList {
                                    self.discoverFriendsList.append((self.friendsDistanceDict[id]!.0, self.friendsDistanceDict[id]!.2))
                                }

                                DispatchQueue.main.async {
                                    self.tableView.reloadData()
                                }
                            }
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
    
    /// Add swipe options to Send and Unsend friend requests for each user
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let userData = discoverFriendsList[indexPath.row].0
        let userFirstName = userData["firstname"] as! String
        let userUid = userData["uid"] as! String
        
        let add = UIContextualAction(style: .destructive, title: "Add Friend") { (action, view, completionHandler) in
            self.databaseController?.handleFriendRequestSent(fromUid: (self.authController?.currentUser?.uid)! as String, toUid: userUid)
            
            self.fetchAllData()
            tableView.reloadData()
            
            self.displayMessage(title: "Friend Request Sent", message: "Wait for \(userFirstName) to accept your friend request!")
            completionHandler(true)
        }
        add.backgroundColor = .systemGreen
        
        let unsendRequest = UIContextualAction(style: .destructive, title: "Unsend Request") { (action, view, completionHandler) in
            self.databaseController?.handleFriendRequestUnsent(fromUid: (self.authController?.currentUser!.uid)! as String, toUid: userUid)
            
            self.fetchAllData()
            tableView.reloadData()
            
            self.displayMessage(title: "Friend Request Unsent", message: "Go back and discover other friends!")
            completionHandler(true)
        }
        unsendRequest.backgroundColor = .systemRed
        
        tableView.reloadRows(at: [indexPath], with: UITableView.RowAnimation.none)

        let configuration = UISwipeActionsConfiguration(actions: [add, unsendRequest])
        return configuration
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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
