//
//  SpotifyLoginViewController.swift
//  MusicMates
//
//  Created by Debashish Sahoo on 7/5/2023.
//

import UIKit
import SafariServices
import AuthenticationServices


/// View Controller for the Spotify Authentication Login Screen
class SpotifyLoginViewController: UIViewController, ASWebAuthenticationPresentationContextProviding {
    
    var registerViewController: RegisterViewController?
    
    var webAuthSession: ASWebAuthenticationSession?
    
    let clientID = MyClientID // ENTER YOUR OWN SPOTIFY CLIENT ID TO RUN THE APP
    let clientSecret = MyClientSecret // ENTER YOUR OWN SPOTIFY CLIENT SECRET TO RUN THE APP
    let redirectURI = MyRedirectURI // ENTER YOUR OWN SPOTIFY REDIRECT URI TO RUN THE APP

    let authorizeURLString = "https://accounts.spotify.com/authorize"
    let tokenEndpointURLString = "https://accounts.spotify.com/api/token"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        registerViewController = RegisterViewController()
        
        // Build URL for authorization with Spotify and start a web authentication session
        let authorizeURL = URL(string: authorizeURLString + "?client_id=\(clientID)&response_type=code&redirect_uri=\(redirectURI)&scope=user-read-email%20user-top-read%20user-read-private")!
        
        webAuthSession = ASWebAuthenticationSession(url: authorizeURL, callbackURLScheme: "musicmates", completionHandler: { (url, error) in
            if let error = error {
                
                // Go back to the Register Screen, if the user closes the web authentication pop up page or there was any error
                self.navigationController?.popViewController(animated: true)
                
                self.displayMessage(title: "Error", message: "Spotify Authentication Error: \(error.localizedDescription)")
                
            } else if let url = url {
                let queryItems = URLComponents(string: url.absoluteString)?.queryItems
                
                // Successful authentication
                if let code = queryItems?.first(where: { $0.name == "code" })?.value {
                    // Get user's access token, which also then sets the new root view controller to the tab bar controller
                    self.getAccessToken(code)
                    
                } else {
                    // Go back to the Register Screen, if the user closes the web authentication pop up page or there was any error
                    self.navigationController?.popViewController(animated: true)
                    self.displayMessage(title: "Error", message: "Spotify Authentication Error")
                }
            }
        })
        
        webAuthSession?.presentationContextProvider = self // Delegate set to itself which displays a context in which the authentication session can be shown
        webAuthSession?.prefersEphemeralWebBrowserSession = true // Resets the session so that it doesn't remember the last authenticated session
        webAuthSession?.start()

    }
    
    func getAccessToken(_ code: String) {
        
        // Build the request method, headers, and parameters for the token endpoint url required to grab access token from Spotify using the received authorization code earlier
        let tokenEndpointURL = URL(string: tokenEndpointURLString)!
        var urlRequest = URLRequest(url: tokenEndpointURL)
        urlRequest.httpMethod = "POST"
        
        let clientData = "\(clientID):\(clientSecret)".data(using: .ascii)!
        let secureString = clientData.base64EncodedString()
        urlRequest.setValue("Basic \(secureString)", forHTTPHeaderField: "Authorization")
        
        let parameters = ["grant_type": "authorization_code", "code": code, "redirect_uri": redirectURI]
        let paramsString = parameters.map {"\($0)=\($1)"}.joined(separator: "&")
        urlRequest.httpBody = paramsString.data(using: .utf8)
        
        // Request data from Spotify API
        let urlSession = URLSession.shared
        let dataTask = urlSession.dataTask(with: urlRequest) { (data, response, error) in
            if let error = error {
                self.displayMessage(title: "Error", message: "Error: \(error.localizedDescription)")
            } else if let data = data, let response = response as? HTTPURLResponse {
                if response.statusCode == 200 {
                    do {
                        let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                        
                        // Get user's Access Token, Refresh Token, and the time their access token expires in (seconds)
                        if let accessToken = json?["access_token"] as? String, let refreshToken = json?["refresh_token"] as? String, let expiresIn = json?["expires_in"] as? Int {
                            print("User's Access Token: \(accessToken)")
                            print("User's Refresh Token: \(refreshToken)")
                            print("User's Access Token Expires In: \(expiresIn)")
                            
                            // Actually Register Account
                            self.registerViewController?.registerWithSpotify(accessToken: accessToken, refreshToken: refreshToken, expiresIn: expiresIn)
                            
                        } else {
                            self.displayMessage(title: "Error", message: "Failed to fully connect your Spotify account. Try again.")
                        }
                    } catch {
                        print("JSON Error: \(error.localizedDescription)")
                    }
                } else {
                    print("HTTP Error: \(response.statusCode)")
                }
            } else {
                print("Error: Nothing to parse.")
            }
        }
        dataTask.resume()
    }
    
    /// Informs the delegate from which window it should present content to the user.
    /// - Parameter session: The web authentication session
    /// - Returns: The window where the content should be presented
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return view.window ?? ASPresentationAnchor()
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
