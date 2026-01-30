//
//  FavouriteVideo.swift
//  Video_Feed
//
//  Created by Ravindra Kumar Sonkar on 28/01/26.
//

import Foundation
import SwiftData

@Model
class FavouriteVideo: @unchecked Sendable {
    var id: String
    var videoURL: String
    var thumbnailURL: String
    var duration: Int
    var title: String
    var desc: String
    var products: [Product]
    var isFavourite: Bool
    
    init(id: String, videoURL: String, thumbnailURL: String, duration: Int, title: String, desc: String, products: [Product], isFavourite: Bool) {
        self.id = id
        self.videoURL = videoURL
        self.thumbnailURL = thumbnailURL
        self.duration = duration
        self.title = title
        self.desc = desc
        self.products = products
        self.isFavourite = isFavourite
    }
}

extension FavouriteVideo {
    convenience init(_ video: VideoEntity) {
        self.init(id: video.id,
                  videoURL: video.videoURL,
                  thumbnailURL: video.thumbnailURL,
                  duration: video.duration,
                  title: video.title,
                  desc: video.description,
                  products: video.products,
                  isFavourite: false)
    }
}
