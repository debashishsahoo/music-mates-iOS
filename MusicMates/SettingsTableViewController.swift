//
//  SettingsTableViewController.swift
//  MusicMates
//
//  Created by Debashish Sahoo on 8/6/2023.
//

import UIKit
import Firebase
import FirebaseFirestoreSwift

class SettingsTableViewController: UITableViewController {
    
    let SECTION_GENERAL = 0
    let SECTION_OTHER = 1
    
    var generalSettingsList: [String] = []
    var otherSettingsList: [String] = []

    var authController: Auth?

    override func viewDidLoad() {
        super.viewDidLoad()

        generalSettingsList = ["About"]
        otherSettingsList = ["Log Out"]
    }
    
    /// Handles user logging out
    func handleLogOut() {
        authController = Auth.auth()
        do {
            try authController?.signOut()
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let InitialNavController = storyboard.instantiateViewController(identifier: "InitialNavController")
            // Changes root view controller to the intial login screen nav controller
            (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.changeRootViewController(InitialNavController)
        } catch let signOutError as NSError {
            displayMessage(title: "Error", message: "Error signing out: \(signOutError)")
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == SECTION_GENERAL {
            return generalSettingsList.count
        } else {
            return otherSettingsList.count
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "settingsCell", for: indexPath)
        var content = cell.defaultContentConfiguration()
        
        if indexPath.section == SECTION_GENERAL {
            content.text = generalSettingsList[indexPath.row]
            cell.accessoryType = UITableViewCell.AccessoryType.disclosureIndicator
        } else if indexPath.section == SECTION_OTHER {
            content.text = otherSettingsList[indexPath.row]
        }
        
        cell.contentConfiguration = content
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == SECTION_GENERAL {
            if generalSettingsList[indexPath.row] == "About" {
                performSegue(withIdentifier: "aboutSegue", sender: self)
            }
        } else if indexPath.section == SECTION_OTHER {
            if otherSettingsList[indexPath.row] == "Log Out" {
                handleLogOut()
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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    }
    */
}
