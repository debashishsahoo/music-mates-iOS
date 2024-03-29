//
//  MyMusicTasteTableViewController.swift
//  MusicMates
//
//  Created by Debashish Sahoo on 16/5/2023.
//

import UIKit
import Firebase
import FirebaseFirestoreSwift

/// View Controller for user's "My Music Taste" Screen
class MyMusicTasteTableViewController: UITableViewController {
    
    weak var databaseController: DatabaseProtocol?
    var authController: Auth?

    let clientID = MyClientID
    let clientSecret = MyClientSecret
    let redirectURI = MyRedirectURI

    let tokenEndpointURLString = "https://accounts.spotify.com/api/token"

    let SECTION_ARTISTS = 0
    let CELL_ARTIST = "artistCell"
    
    var artistsList: [[String: String]] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Get a reference to the database from the appDelegate
        let appDelegate = (UIApplication.shared.delegate as? AppDelegate)
        databaseController = appDelegate?.databaseController
        
        authController = Auth.auth()
        
        // Use the user's refresh token to set a new access token for the user, which then fetches the top artists for the user
        refreshUserAccessToken()
    }
    
    /// Set a new access token for the user using their Spotify refresh token as access tokens expire in 1 hour
    /// - Parameter refreshToken: The user's Spotify refresh token
    func setNewAccessToken(_ refreshToken: String) {
        // Build the request method, headers, and parameters for the token endpoint url required to grab refresh token from Spotify
        let tokenEndpointURL = URL(string: tokenEndpointURLString)!
        var urlRequest = URLRequest(url: tokenEndpointURL)
        urlRequest.httpMethod = "POST"
        
        let clientData = "\(clientID):\(clientSecret)".data(using: .ascii)!
        let secureString = clientData.base64EncodedString()
        urlRequest.setValue("Basic \(secureString)", forHTTPHeaderField: "Authorization")
        
        let parameters = ["grant_type": "refresh_token", "refresh_token": refreshToken]
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
                        if let accessToken = json?["access_token"] as? String, let expiresIn = json?["expires_in"] as? Int {
                            print("User's Access Token: \(accessToken)")
                            print("Expires In: \(expiresIn)")

                            self.databaseController?.updateUserData(uid: (self.authController?.currentUser!.uid)!, data: ["accessToken": accessToken, "expiresIn": expiresIn])
                            
                            // Fetch the user's top artists
                            self.fetchUserSpotifyData()
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
    
    /// Use the user's refresh token to set a new access token for the user (as access tokens are only valid for 1 hour)
    func refreshUserAccessToken() {
        databaseController?.getUserData(uid: (authController?.currentUser!.uid)!) { (userData) in
            // Only go ahead with fetching Spotify details if the user registered with the app using Spotify
            if userData["registeredWithSpotify"] as! Bool == true {
                // Use the user's refresh token as the access tokens are only valid for 1 hour
                let refreshToken = userData["refreshToken"] as! String
                self.setNewAccessToken(refreshToken)
            }
        }
    }

    /// Fetch user's top tracks from Spotify using their access token
    func fetchUserSpotifyData() {
        databaseController?.getUserData(uid: (authController?.currentUser!.uid)!) { (userData) in
            let accessToken = userData["accessToken"] as! String
            
            // Build the request method, headers, and parameters for the token endpoint url required to grab access token from Spotify using the received authorization code earlier
            let topItemsEndpointURL = URL(string: "https://api.spotify.com/v1/me/top/artists")!
            var urlRequest = URLRequest(url: topItemsEndpointURL)
            urlRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            
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
                            if let artists = json?["items"] as? [[String: Any]] {
                                for artist in artists {
                                    let artistName = artist["name"] as! String
                                    let artistImages = artist["images"] as! [[String: Any]]
                                    let artistImageURL = artistImages[1]["url"] as! String
                                    
                                    self.artistsList.append([
                                        "name": artistName,
                                        "imageURL": artistImageURL
                                    ])
                                }
                                
                                // Update the user's favorite artists list in Firebase
                                self.databaseController?.updateUserData(uid: (self.authController?.currentUser!.uid)!, data: ["favArtists": self.artistsList])
                                DispatchQueue.main.async {
                                    self.tableView.reloadData()
                                }
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
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch (section) {
            case SECTION_ARTISTS:
                if !artistsList.isEmpty {
                    return artistsList.count
                } else {
                    return 1
                }
            default:
                return 0
        }
    }
    
    // Display the user's favourite artists
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {        
        let artistCell = tableView.dequeueReusableCell(withIdentifier: CELL_ARTIST, for: indexPath)
        var content = artistCell.defaultContentConfiguration()
        if !artistsList.isEmpty {
            content.text = "\(indexPath.row + 1)) \(artistsList[indexPath.row]["name"]!)"
        } else {
            content.text = "Please Connect Your Spotify Account."
        }
        artistCell.contentConfiguration = content
        return artistCell
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
