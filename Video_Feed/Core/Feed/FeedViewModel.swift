//
//  FeedViewModel.swift
//  Video_Feed
//
//  Created by Ravindra Kumar Sonkar on 27/01/26.
//

import Foundation
import Combine

@MainActor
final class FeedViewModel: ObservableObject {
    @Published var videos: [FavouriteVideo] = []
    @Published var error: ApiError? = nil
    
    func error(for apiError: ApiError) {
        self.error = apiError
    }
    
    func success(for videos: [FavouriteVideo]) {
        self.videos = videos
    }
}
