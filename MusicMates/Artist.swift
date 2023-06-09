//
//  Artist.swift
//  MusicMates
//
//  Created by Debashish Sahoo on 8/6/2023.
//

import Foundation
import UIKit

class Artist: NSObject {
    var name: String
    var image: UIImage

    init(name: String, image: UIImage) {
        self.name = name
        self.image = image
    }
}
