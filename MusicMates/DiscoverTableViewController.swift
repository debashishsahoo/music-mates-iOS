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
    
    let SECTION_USERS = 0
    let SECTION_INFO = 1
    
    let CELL_USER = "userCell"
    let CELL_INFO = "infoCell"
    
    var friendsDistanceDict: [String: ([String: Any?], Double, String)] = [:]
    var friendsList: [String] = []
    var discoverFriendsList: [([String:Any?], String)] = []
    
    var currentUserLocation: CLLocationCoordinate2D?
    var currentUserFriends: Array<DocumentReference>?
    
    var accessoryBtnTappedIndexPath: IndexPath?
        
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
        // Fetch all table data
        fetchAllData()
    }
    
    /// Refresh table data by swiping down
    @objc func refreshData() {
        // Fetch all table data
        fetchAllData()
        tabelRefreshControl.endRefreshing()
    }
        
    /// Fetch table data
    func fetchAllData() {
        friendsList = []
        getCurrentUserLocation()
        getDiscoverFriendsData()
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
            var counter = 0
            for user in usersData {
                counter += 1
                // Don't display the current user in the discover users page
                if (user.documentID != self.authController?.currentUser?.uid) {
                    self.databaseController?.getUserData(uid: (self.authController?.currentUser?.uid)!) { (userData) in
                        let friends = userData["friends"] as! Array<DocumentReference>
                        // Don't display a user in the discover users page if they are already a friend of the current user
                        if !(friends.contains(user.reference)) {
                            self.databaseController?.getUserData(uid: user.documentID) { (userData) in
                                let firstName = userData["firstname"] as! String
                                let lastName = userData["lastname"] as! String
                                
                                let location = userData["location"] as! GeoPoint
                                let latitude = location.latitude
                                let longitude = location.longitude
                                
                                let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
 
                                // Calculate distance of the other user from the current user, round it, and convert it to kilometers
                                let distance_from_current_user = round((CLLocation(latitude: self.currentUserLocation!.latitude, longitude: self.currentUserLocation!.longitude).distance(from: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude))/1000) * 100) / 100.0
                                
                                let string = firstName + " " + lastName + " — \(String(distance_from_current_user)) km"
                                self.friendsDistanceDict[user.documentID] = (userData, distance_from_current_user, string)  // Use a tuple for each value of the dict which also holds the string to append
                                
                                self.friendsList.append(user.documentID)
                                
                                let sortedFriendsList = self.friendsList.sorted(by: { lhs, rhs in
                                    return self.friendsDistanceDict[lhs]!.1 < self.friendsDistanceDict[rhs]!.1
                                })

                                self.friendsList = sortedFriendsList

                                if counter == usersData.count {
                                    self.discoverFriendsList.removeAll()
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
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == SECTION_USERS {
            return discoverFriendsList.count
        } else {
            return 1
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Configure and return user cell
        if indexPath.section == SECTION_USERS {
            let userCell = tableView.dequeueReusableCell(withIdentifier: CELL_USER, for: indexPath)
            var content = userCell.defaultContentConfiguration()
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
            
            content.text = discoverFriendsList[indexPath.row].1
            content.secondaryText = friendRequestStatus
            userCell.accessoryType = .detailButton
            userCell.contentConfiguration = content
            return userCell
        } else {
            let infoCell = tableView.dequeueReusableCell(withIdentifier: CELL_INFO, for: indexPath)
            var content = infoCell.defaultContentConfiguration()
            if discoverFriendsList.isEmpty {
                content.text = "No Users Found."
            } else {
                content.text = "\(discoverFriendsList.count) User(s)"
            }
            infoCell.contentConfiguration = content
            return infoCell
        }
    }
    
    // Get the index path of the row in which the accessory button (Detail) is clicked
    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        accessoryBtnTappedIndexPath = indexPath
        
        // Perform segue to show the selected user's favorite artists list
        performSegue(withIdentifier: "friendArtistsSegue", sender: self)
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
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Segue to a map showing the location of the selected user
        if segue.identifier == "mapSegue" {
             if let cell = sender as? UITableViewCell, let indexPath = tableView.indexPath(for: cell) {
                 let friendData = discoverFriendsList[indexPath.row].0
                 let friendFirstName = friendData["firstname"] as! String
                 let friendLastName = friendData["lastname"] as! String
                 let friendName = friendFirstName + " " + friendLastName

                 let friendLocation = friendData["location"] as! GeoPoint
                 let latitude = friendLocation.latitude
                 let longitude = friendLocation.longitude
                 
                 let controller = segue.destination as! MapViewController
                 
                 // Create a location annotation for the selected user to be displayed on the map
                 let annotation = LocationAnnotation(title: friendName, lat: latitude, long: longitude)
                 controller.annotation = annotation
             }
        } else if segue.identifier == "friendArtistsSegue" {
            // Segue to the list of favourite artists for the particular friend clicked on
            let friendData = discoverFriendsList[accessoryBtnTappedIndexPath!.row].0
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
