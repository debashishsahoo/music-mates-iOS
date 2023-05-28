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

    var requestsList: [[String: Any?]] = []
    
    let CELL_REQUEST = "requestCell"
    
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
        fetchAllData()
    }

    /// Refresh table data by swiping down
    @objc func refreshData() {
        fetchAllData()
        tabelRefreshControl.endRefreshing()
    }
    
    /// Fetch table data
    func fetchAllData() {
        requestsList = []
        getRequestsData()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return requestsList.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let requestCell = tableView.dequeueReusableCell(withIdentifier: CELL_REQUEST, for: indexPath)
        
        var content = requestCell.defaultContentConfiguration()
        let firstName =  requestsList[indexPath.row]["firstname"] as! String
        let lastName = requestsList[indexPath.row]["lastname"] as! String
        content.text = firstName + " " + lastName
        requestCell.contentConfiguration = content
        
        return requestCell
    }
    
    /// Get list of friend requests for the current user
    func getRequestsData() {
        databaseController?.getUserData(uid: (authController?.currentUser?.uid)!) { (userData) in
            let requestsReceived = userData["requestsReceived"] as! [Any]
            for friend in requestsReceived {
                self.databaseController?.getUserData(uid: (friend as AnyObject).documentID) { (userData) in
                    self.requestsList.append(userData)
                    
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
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
    
    /// Add swipe options to Accept and Decline each friend request
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let requestData = requestsList[indexPath.row]
        let requestUid = requestData["uid"] as! String
        
        let accept = UIContextualAction(style: .normal, title: "Accept") { (action, view, completionHandler) in
            self.databaseController?.handleFriendRequestAccepted(fromUid: requestUid, toUid: (self.authController?.currentUser!.uid)! as String)
            self.requestsList.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            self.displayMessage(title: "Friend Request Accepted", message: "You've got a new friend!")
            completionHandler(true)
        }
        accept.backgroundColor = .systemGreen

        let decline = UIContextualAction(style: .destructive, title: "Decline") { (action, view, completionHandler) in
            self.databaseController?.handleFriendRequestDeclined(fromUid: requestUid, toUid: (self.authController?.currentUser!.uid)! as String)
            self.requestsList.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            self.displayMessage(title: "Friend Request Rejected", message: "Not who you're looking for, it seems..")
            completionHandler(true)
        }
        decline.backgroundColor = .systemRed
        
        let configuration = UISwipeActionsConfiguration(actions: [accept, decline])

        return configuration
    }
    
    
    
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
