//
//  UIViewController+displayMessage.swift
//  MusicMates
//
//  Created by Debashish Sahoo on 7/5/2023.
//

import Foundation
import UIKit

extension UIViewController {
    /// DIsplays a UI Alert to the user on the screen (used for various purposes throughout the app, such as success and error messages)
    /// - Parameters:
    ///   - title: Title of the alert
    ///   - message: Message of the alert
    func displayMessage(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
}
