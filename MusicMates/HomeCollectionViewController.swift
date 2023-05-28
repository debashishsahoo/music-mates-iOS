//
//  HomeCollectionViewController.swift
//  MusicMates
//
//  Created by Debashish Sahoo on 2/5/2023.
//

import UIKit
import Firebase
import FirebaseFirestoreSwift

private let reuseIdentifier = "Cell"

/// View Controller for the Home Screen (which ranks and displays the common favourite artists between the current user and their friends)
class HomeCollectionViewController: UICollectionViewController {
    
    var authController: Auth?
    weak var databaseController: DatabaseProtocol?
    
//    var combinedFavArtits: [String]?
    var commonArtistsRankedDict: [String: Int] = [:]
    
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
        
        self.navigationItem.setHidesBackButton(true, animated: true)
        
        self.fetchCommonArtists()

    }
    
    
    /// Fetch all the common favourite artists between the current user and their friends
    func fetchCommonArtists() {
        self.databaseController?.getUserData(uid: (self.authController?.currentUser?.uid)!) { (userData) in
            var combinedFavArtits: [String] = []
            let currentUserFavArtists = userData["favArtists"] as! [String]
            combinedFavArtits += currentUserFavArtists
            
            let dispatchGroup = DispatchGroup()
            let friends = userData["friends"] as! Array<DocumentReference>
            dispatchGroup.enter()
            for friend in friends {
                self.databaseController?.getUserData(uid: friend.documentID) { (userData) in
                    let friendFavArtists = userData["favArtists"] as! [String]
                    combinedFavArtits += friendFavArtists
                }
            }
            dispatchGroup.leave()
            dispatchGroup.notify(queue: .main) {
                print(combinedFavArtits)
                self.rankCombinedArtists(combinedFavArtists: combinedFavArtits)
            }
        }
        
    }
    
    /// Rank all the common favourite artists between the current user and their friends based on frequency
    /// - Parameter combinedFavArtists: List of common favourite artists between the current user and their friends
    func rankCombinedArtists(combinedFavArtists: [String]) {
        for artist in combinedFavArtists {
            if !(self.commonArtistsRankedDict.keys.contains(artist)) {
                self.commonArtistsRankedDict[artist as String] = 0
            }
            self.commonArtistsRankedDict[artist]! += 1
        }
        
        self.collectionView.reloadData()
        
        print(self.commonArtistsRankedDict)
        
    }
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return commonArtistsRankedDict.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)

        // Configure the cell
        let title = UILabel(frame: CGRect(x: 0, y: 0, width: cell.bounds.size.width, height: 50))
        let keysList = Array(commonArtistsRankedDict.keys) as [String]
        title.text = keysList[indexPath.row] //        title.text = "\(keysList[indexPath.row]) : \(String(commonArtistsRankedDict[keysList[indexPath.row]]!))"
        title.font = UIFont(name: "AvenirNext-Bold", size: 15)
        title.textAlignment = .center
        title.numberOfLines = 3
        cell.contentView.addSubview(title)

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

}
