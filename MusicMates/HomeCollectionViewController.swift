//
//  HomeCollectionViewController.swift
//  MusicMates
//
//  Created by Debashish Sahoo on 2/5/2023.
//

import UIKit
import Firebase
import FirebaseFirestoreSwift
import MapKit

private let reuseIdentifier = "Cell"

/// View Controller for the Home Screen (which ranks and displays the common favourite artists between the current user and their friends)
class HomeCollectionViewController: UICollectionViewController, CLLocationManagerDelegate {
    
    var authController: Auth?
    weak var databaseController: DatabaseProtocol?
    
    // For Displaying Artists
    var currentUserFriends: Array<DocumentReference>?
    var combinedFavArtists: [String] = []
    var commonArtistsRankedDict: [String: (Int, String)] = [:]
    var finalCombinedArtistsList: [(String, Int, String)] = []
    
    // For User Location Purposes
    var locationManager: CLLocationManager = CLLocationManager()
    var currentLocation: CLLocationCoordinate2D?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
        self.collectionView!.register(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        
        // Get a reference to the database from the appDelegate
        let appDelegate = (UIApplication.shared.delegate as? AppDelegate)
        databaseController = appDelegate?.databaseController
        
        authController = Auth.auth()
                
        // Set up the desired accuracy, distance filter and delegate of the location manager.
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.distanceFilter = 10
        locationManager.delegate = self
        
        // Check if we have user authorization to access location info
        let authorisationStatus = locationManager.authorizationStatus
        if authorisationStatus != .authorizedWhenInUse {
            // If we have not yet asked the user for permission then request permission to access the location info
            if authorisationStatus == .notDetermined {
                locationManager.requestWhenInUseAuthorization()
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // Informs the location manager to stop updating the location once the view appears
        locationManager.startUpdatingLocation()
        
        // Fetch the user's spotify artists data before fetching data about the common artists in their friend circle
        fetchUserSpotifyData() { success in
            self.combinedFavArtists = []
            self.commonArtistsRankedDict = [:]
            self.finalCombinedArtistsList = []
            self.fetchCommonArtists()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        // Informs the location manager to stop updating the location once the view disappears
        locationManager.stopUpdatingLocation()
    }
    
    /// This method is called every time an update is received for the user's location
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last?.coordinate
        saveLocation()
    }
    
    /// Saves the current location of the user to their user data on  Firebase
    func saveLocation() {
        let geopoint = GeoPoint(latitude: currentLocation?.latitude ?? 0, longitude: currentLocation?.longitude ?? 0)
        self.databaseController?.updateUserData(uid: (self.authController?.currentUser!.uid)!, data: ["location": geopoint])
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
    
    /// Fetch all the common favourite artists between the current user and their friends and rank them based on frequency of mutuals
    func fetchCommonArtists() {
        databaseController?.getUserData(uid: (self.authController?.currentUser?.uid)!) { (userData) in
            let currentUserFavArtists = userData["favArtists"] as! [[String: String]]
            for artist in currentUserFavArtists {
                self.combinedFavArtists.append(artist["name"]!)
                self.commonArtistsRankedDict[artist["name"]!] = (1, artist["imageURL"]!)
            }
                        
            let friends = userData["friends"] as! Array<DocumentReference>
            if friends.count > 0 {
                for friend in friends {
                    self.databaseController?.getUserData(uid: friend.documentID) { (userData) in
                        let friendFavArtists = userData["favArtists"] as! [[String: String]]
                        for artist in friendFavArtists {
                            if !(self.commonArtistsRankedDict.keys.contains(artist["name"]!)) {
                                self.commonArtistsRankedDict[artist["name"]!] = (1, artist["imageURL"]!)
                                self.combinedFavArtists.append(artist["name"]!)
                            } else {
                                let countArtist = self.commonArtistsRankedDict[artist["name"]!]!.0 + 1
                                self.commonArtistsRankedDict[artist["name"]!] = (countArtist, artist["imageURL"]!)
                            }
                        }
                                            
                        let sortedArtistsList = self.combinedFavArtists.sorted(by: { lhs, rhs in
                            return self.commonArtistsRankedDict[lhs]!.0 > self.commonArtistsRankedDict[rhs]!.0
                        })

                        self.combinedFavArtists = sortedArtistsList

                        self.finalCombinedArtistsList = []
                        for artistName in self.combinedFavArtists {
                            self.finalCombinedArtistsList.append((artistName, self.commonArtistsRankedDict[artistName]!.0, self.commonArtistsRankedDict[artistName]!.1))
                        }
                        
                        DispatchQueue.main.async {
                            self.collectionView.reloadData()
                        }
                    }
                }
            } else {
                self.finalCombinedArtistsList = []
                for artistName in self.combinedFavArtists {
                    self.finalCombinedArtistsList.append((artistName, self.commonArtistsRankedDict[artistName]!.0, self.commonArtistsRankedDict[artistName]!.1))
                }
                
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                }
            }
        }
    }
    
    /// Fetch user's top tracks from Spotify using their access token
    func fetchUserSpotifyData(completion: @escaping (_ success: Bool) -> Void) {
        databaseController?.getUserData(uid: (authController?.currentUser!.uid)!) { (userData) in
            var userFavArtists: [Any] = []
            userFavArtists = userData["favArtists"] as! [Any]
            if userFavArtists.isEmpty {
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
                                    var artistsList: [[String: String]] = []
                                    for artist in artists {
                                        let artistName = artist["name"] as! String
                                        let artistImages = artist["images"] as! [[String: Any]]
                                        let artistImageURL = artistImages[1]["url"] as! String
                                        
                                        artistsList.append([
                                            "name": artistName,
                                            "imageURL": artistImageURL
                                        ])
                                    }
                                    self.databaseController?.updateUserData(uid: (self.authController?.currentUser!.uid)!, data: ["favArtists": artistsList])
                                    let success = true
                                    completion(success)
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
            } else {
                let success = true
                completion(success)
            }
        }
    }
    
    /// Adds a text label inside the given image
    /// - Parameters:
    ///   - text: The text to add to the image
    ///   - image: The image
    ///   - point: The point in the image to display the image
    /// - Returns: The new image with the text
    func textToImage(drawText text: String, inImage image: UIImage, atPoint point: CGPoint) -> UIImage {
        let textColor = UIColor.white
        let textFont = UIFont(name: "Helvetica Bold", size: 68)!
        let textBackground = UIColor.black

        let scale = UIScreen.main.scale
        UIGraphicsBeginImageContextWithOptions(image.size, false, scale)

        image.draw(in: CGRect(origin: CGPoint.zero, size: image.size))
        let rect = CGRect(origin: point, size: image.size)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        let attrs = [NSAttributedString.Key.font: textFont,
                     NSAttributedString.Key.foregroundColor : textColor,
                     NSAttributedString.Key.backgroundColor: textBackground,
                     NSAttributedString.Key.paragraphStyle: paragraphStyle]

        text.draw(with: rect, options: .usesLineFragmentOrigin, attributes: attrs, context: nil)

        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage!
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return finalCombinedArtistsList.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
        
        let artistImageURL = finalCombinedArtistsList[indexPath.row].2
        let artistCount = finalCombinedArtistsList[indexPath.row].1
        let artistName = finalCombinedArtistsList[indexPath.row].0
        
        // Fetch the artist's image using the image URL
        let urlSession = URLSession.shared
        let dataTask = urlSession.dataTask(with: URL(string: artistImageURL)!) { (data, response, error) in
            if let error = error {
                self.displayMessage(title: "Error", message: "Error: \(error.localizedDescription)")
            } else if let data = data, let response = response as? HTTPURLResponse {
                if response.statusCode == 200 {
                    Task {
                        if let artistImage = UIImage(data: data) {
                            // Add text to the image showing the artist's name and frequency in the friend group
                            let textToShow = artistName + " " + String(artistCount) + "x"
                            let imageWithText = self.textToImage(drawText: textToShow, inImage: artistImage, atPoint: CGPointMake(0, 10))
                            cell.backgroundView = UIImageView(image: imageWithText)
                        }
                    }
                } else {
                    print("HTTP Error: \(response.statusCode)")
                }
            }
        }
        dataTask.resume()
        
        return cell
    }

    // MARK: UICollectionViewDelegate

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
    
    }
    */
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

}
