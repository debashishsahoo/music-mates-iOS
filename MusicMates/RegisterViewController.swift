//
//  RegisterViewController.swift
//  MusicMates
//
//  Created by Debashish Sahoo on 30/4/2023.
//

import UIKit
import Firebase
import FirebaseFirestoreSwift
import SafariServices

/// View Controller for the Register Screen
class RegisterViewController: UIViewController {

    var authController: Auth?
    
    var database: Firestore = Firestore.firestore()

    weak var databaseController: DatabaseProtocol?
    var handle: AuthStateDidChangeListenerHandle?
    
    var usersRef: CollectionReference?
    var userRef: DocumentReference?
    var currentUser: FirebaseAuth.User?
    
    var checkBoxIsChecked = false
    let checkBoxImage = UIImage(named: "CheckedCheckbox")! as UIImage
    let uncheckedCheckBoxImage = UIImage(named: "UncheckedCheckbox")! as UIImage
    
    @IBOutlet weak var firstNameTextField: UITextField!
    
    @IBOutlet weak var lastNameTextField: UITextField!
    
    @IBOutlet weak var emailTextField: UITextField!
    
    @IBOutlet weak var passwordTextField: UITextField!
    
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    
    @IBOutlet weak var checkBoxBtn: UIButton!
    
    
    /// Toggles the check box for agreering to terms and conditions
    /// - Parameter sender: The checkbox button
    @IBAction func checkBoxBtnClicked(_ sender: UIButton) {
        checkBoxIsChecked = !checkBoxIsChecked

        if checkBoxIsChecked == true {
            sender.setImage(checkBoxImage, for: UIControl.State.normal)
        } else {
            sender.setImage(uncheckedCheckBoxImage, for: UIControl.State.normal)
        }
    }
    
    /// Handles user registration with Spotify connection and segues to the Spotify Authentication Login screen
    /// - Parameter sender: The Register with Spotify button
    @IBAction func registerWithSpotifyBtnClicked(_ sender: Any) {
        
        let firstName = firstNameTextField.text
        let lastName = lastNameTextField.text
        let email = emailTextField.text
        let password = passwordTextField.text
        let confirmPassword = confirmPasswordTextField.text
        
        // Save fields to user defaults temporarily in case spotify auth is cancelled
        let userDefaults = UserDefaults.standard
        let tempDict = [
            "firstName": firstName,
            "lastName": lastName,
            "email": email,
            "password": password
        ]
        userDefaults.set(tempDict, forKey: "tempDictKey")
            
        // Check that no fields are empty
        guard firstName?.isEmpty == false, lastName?.isEmpty == false, email?.isEmpty == false, password?.isEmpty == false, confirmPassword?.isEmpty == false else {
            displayMessage(title: "Error", message: "Cannot leave a field blank")
            return
        }
        
        // Check that email is valid
        guard isValidEmail(email!) == true else {
            displayMessage(title: "Error", message: "Please enter a valid email")
            return
        }
        
        // Check that the passwords match
        guard password == confirmPassword else {
            displayMessage(title: "Error", message: "Passwords do not match")
            return
        }
        
        // Check that the user has checked the Terms and Conditions box
        guard checkBoxIsChecked == true else {
            displayMessage(title: "Error", message: "Please tick the button to read and agree to our Terms and Conditions")
            return
        }
        
        // Segue to Spotify Login View Controller
        self.performSegue(withIdentifier: "spotifyLoginSegue", sender: self)
        
    }
    
    /// Handles user registration without Spotify connection
    /// - Parameter sender: The Register without Spotify button
    @IBAction func registerWithoutSpotifyBtnClicked(_ sender: Any) {
        
        let firstName = firstNameTextField.text
        let lastName = lastNameTextField.text
        let email = emailTextField.text
        let password = passwordTextField.text
        let confirmPassword = confirmPasswordTextField.text
        
        // Check that no fields are empty
        guard firstName?.isEmpty == false, lastName?.isEmpty == false, email?.isEmpty == false, password?.isEmpty == false, confirmPassword?.isEmpty == false else {
            displayMessage(title: "Error", message: "Cannot leave a field blank")
            return
        }
        
        // Check that email is valid
        guard isValidEmail(email!) == true else {
            displayMessage(title: "Error", message: "Please enter a valid email")
            return
        }
        
        // Check that the passwords match
        guard password == confirmPassword else {
            displayMessage(title: "Error", message: "Passwords do not match")
            return
        }
        
        // Check that the user has checked the Terms and Conditions box
        guard checkBoxIsChecked == true else {
            displayMessage(title: "Error", message: "Please tick the button to read and agree to our Terms and Conditions")
            return
        }
        
        Task {
            do {
                let authDataResult = try await authController!.createUser(withEmail: email!, password: password!)
                currentUser = authDataResult.user
                
                usersRef = database.collection("users")
                userRef = usersRef?.document(currentUser!.uid)
                try await userRef?.setData([
                    "uid": currentUser!.uid,
                    "firstname": firstName!,
                    "lastname": lastName!,
                    "email": email!,
                    "password": password!,
                    "username": "randomly-generated",
                    "photoURL": "default_photo.png",
                    "location": GeoPoint(latitude: 0, longitude: 0),
                    "friends": [],
                    "settings": [],
                    "favSongs": [],
                    "favArtists": [],
                    "accessToken": "",
                    "requestsSent": [],
                    "requestsReceived": []
                ])
            } catch {
                print("Firebase Authentication Failed with Error \(String(describing: error))")
            }
        }
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let TabBarController = storyboard.instantiateViewController(identifier: "TabBarController")
        (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.changeRootViewController(TabBarController)
        
    }
    
    /// Handles and actually registers user after afer the user successfully authenticates with Spotify on the Spotify Authentication Login screen
    /// - Parameter sender: The Register with Spotify button
    func registerWithSpotify(accessToken: String, refreshToken: String, expiresIn: Int) {
        
        authController = Auth.auth()
        database = Firestore.firestore()
        
        let userDefaults = UserDefaults.standard
        var strings: [String:String] = userDefaults.object(forKey: "tempDictKey") as? [String:String] ?? [:]
        
        Task {
            do {
                let authDataResult = try await authController!.createUser(withEmail: strings["email"]!, password: strings["password"]!)
                currentUser = authDataResult.user
                
                usersRef = database.collection("users")
                userRef = usersRef?.document(currentUser!.uid)
                
                try await userRef?.setData([
                    "uid": currentUser!.uid,
                    "firstname": strings["firstName"]!,
                    "lastname": strings["lastName"]!,
                    "email": strings["email"]!,
                    "password": strings["password"]!,
                    "username": "randomly-generated",
                    "photoURL": "default_photo.png",
                    "location": GeoPoint(latitude: 0, longitude: 0),
                    "friends": [],
                    "settings": [],
                    "favSongs": [],
                    "favArtists": [],
                    "accessToken": accessToken,
                    "refreshToken": refreshToken,
                    "expiresIn": expiresIn,
                    "requestsSent": [],
                    "requestsReceived": []
                ])
                
            }
            catch {
                print("Firebase Authentication Failed with Error \(String(describing: error))")
            }
        }
        
        // Delete the temp dict from user defaults
        userDefaults.removeObject(forKey: "tempDictKey")
        
        // Change Root View Controller to the Tab Bar Controller
        DispatchQueue.main.async {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let TabBarController = storyboard.instantiateViewController(identifier: "TabBarController")
            (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.changeRootViewController(TabBarController)
        }

    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Get a reference to the database from the appDelegate
        let appDelegate = (UIApplication.shared.delegate as? AppDelegate)
        databaseController = appDelegate?.databaseController
        
        checkBoxBtn.setImage(uncheckedCheckBoxImage, for: UIControl.State.normal)
        
        authController = Auth.auth()
        database = Firestore.firestore()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // Get a reference to the database from the appDelegate
        authController = Auth.auth()
        
        do {
            try authController?.signOut()
        } catch let signOutError as NSError {
            print("Error signing out: \(signOutError)")
        }
    }
    
    /// Checks if the email address entered is valid
    /// - Parameter email: Email string that the user enters
    /// - Returns: True or False, depending on if the email is valid
    func isValidEmail(_ email: String) -> Bool {
        let emailPattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailPattern)
        return emailPredicate.evaluate(with: email)
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
