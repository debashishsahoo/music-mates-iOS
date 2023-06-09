//
//  LoginViewController.swift
//  MusicMates
//
//  Created by Debashish Sahoo on 30/4/2023.
//


import UIKit
import Firebase
import FirebaseFirestoreSwift


/// View Controller for the Login Screen
class LoginViewController: UIViewController, UITextFieldDelegate {
    
    weak var databaseController: DatabaseProtocol?

    var authController: Auth?
    var handle: AuthStateDidChangeListenerHandle?
    
    var currentUser: FirebaseAuth.User?
    
    @IBOutlet weak var logoImageView: UIImageView!
    
    @IBOutlet weak var emailTextField: UITextField!
    
    @IBOutlet weak var passwordTextField: UITextField!
    
    @IBOutlet weak var loginButton: UIButton!
    
    @IBOutlet weak var registerButton: UIButton!
    
    /// Handles user login and signs in using Firebase authenticaton
    /// - Parameter sender: The log in button
    @IBAction func loginBtnClicked(_ sender: Any) {
        let email = emailTextField.text
        let password = passwordTextField.text
        
        guard email?.isEmpty == false, password?.isEmpty == false else {
            displayMessage(title: "Error", message: "Cannot leave a field blank")
            return
        }
        
        guard isValidEmail(emailTextField.text ?? "") == true else {
            displayMessage(title: "Error", message: "Please enter a valid email")
            return
        }
            
        Task {
            do {
                let authDataResult = try await authController!.signIn(withEmail: email!, password: password!)
                currentUser = authDataResult.user
                                
                // Change Root View Controller to the Tab Bar Controller
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let TabBarController = storyboard.instantiateViewController(identifier: "TabBarController")
                (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.changeRootViewController(TabBarController)
                
            }
            catch {
                print("Firebase Authentication Failed with Error \(String(describing: error))")
                displayMessage(title: "Error", message: "Unable to log in")
            }

        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Get a reference to the database from the appDelegate
        let appDelegate = (UIApplication.shared.delegate as? AppDelegate)
        databaseController = appDelegate?.databaseController
        
        authController = Auth.auth()
        
        // Set delegates for text fields to ensure keyboard disappears upon returning, and also setting appropriate placeholders

        emailTextField.delegate = self
        passwordTextField.delegate = self
        
        emailTextField.attributedPlaceholder = NSAttributedString(
            string: "Email Address",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.systemGray]
        )
        
        passwordTextField.attributedPlaceholder = NSAttributedString(
            string: "Password",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.systemGray]
        )
    }
    
    /// Checks if the email address entered is valid
    /// - Parameter email: Email string that the user enters 
    /// - Returns: True or False, depending on if the email is valid
    func isValidEmail(_ email: String) -> Bool {
        let emailPattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailPattern)
        return emailPredicate.evaluate(with: email)
    }
    
    
    /// Ensures the keyboard disappears upon typing into a text field and returning
    /// - Parameter textField: The text field
    /// - Returns: Boolean to signify the user has returned after typing
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
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
