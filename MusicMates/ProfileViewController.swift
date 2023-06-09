//
//  ProfileViewController.swift
//  MusicMates
//
//  Created by Debashish Sahoo on 16/5/2023.
//

import UIKit
import Firebase
import FirebaseFirestoreSwift

/// View Controller for the Profile Screen
class ProfileViewController: UIViewController {
    
    var authController: Auth?
    weak var databaseController: DatabaseProtocol?

    @IBOutlet weak var profilePicImageView: UIImageView!
    
    @IBOutlet weak var nameLabel: UILabel!
    
    @IBOutlet weak var friendsBtn: UIButton!
    
    @IBOutlet weak var requestsBtn: UIButton!
        
    /// Handles user logging out
    /// - Parameter sender: The log out button
    @IBAction func logOutBtnClicked(_ sender: Any) {
        do {
            try authController?.signOut()
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let InitialNavController = storyboard.instantiateViewController(identifier: "InitialNavController")
            (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.changeRootViewController(InitialNavController) // Changes root view controller to the intial login screen nav controller
        } catch let signOutError as NSError {
            displayMessage(title: "Error", message: "Error signing out: \(signOutError)")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Get a reference to the database from the appDelegate
        let appDelegate = (UIApplication.shared.delegate as? AppDelegate)
        databaseController = appDelegate?.databaseController
        
        authController = Auth.auth()
    }
        
    override func viewDidAppear(_ animated: Bool) {
        // Set user's basic data on the profile page
        setBasicUserProfileData()
    }
    
    /// Set the user's name, username, and friends count from Firebase
    func setBasicUserProfileData() {
        databaseController?.getUserData(uid: (authController?.currentUser?.uid)!) { (userData) in
            let firstName = userData["firstname"] as! String
            let lastName = userData["lastname"] as! String
            self.nameLabel.text = firstName + " " + lastName
                        
            let friends = userData["friends"] as! [Any]
            self.friendsBtn.setTitle(String(friends.count), for: .normal)
            
            let requests = userData["requestsReceived"] as! [Any]
            self.requestsBtn.setTitle(String(requests.count), for: .normal)
        }
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
