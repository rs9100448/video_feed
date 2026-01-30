//
//  MockFeedInteractor.swift
//  Video_FeedTests
//
//  Created by Ravindra Kumar Sonkar on 30/01/26.
//

import Foundation
@testable import Video_Feed


@MainActor
final class MockFeedInteractor: FeedInteractorProtocol {
    var model: FeedViewModel
    var repository: DataLayerRepo
    var currentPage: Int = 0
    
    var fetchDataCalled = false
    var loadMoreDataCalled = false
    var markAsFavouriteCalled = false
    var prefetchCalled = false
    var shouldThrowError = false
    
    var videosToReturn: [FavouriteVideo] = []
    var markedVideo: FavouriteVideo?
    var prefetchedIndex: Int?
    
    init(model: FeedViewModel, repository: DataLayerRepo) {
        self.model = model
        self.repository = repository
    }
    
    func error(for apiError: ApiError) {
        model.error = apiError
    }
    
    func success(for videos: [FavouriteVideo]) {
        model.videos = videos
    }
    
    func appendVideos(for videos: [FavouriteVideo]) {
        model.videos.append(contentsOf: videos)
    }
    
    func fetchData() async throws {
        fetchDataCalled = true
        if shouldThrowError {
            throw ApiError.noData
        }
        success(for: videosToReturn)
    }
    
    func loadMoreData() async throws {
        loadMoreDataCalled = true
        if shouldThrowError {
            throw ApiError.noData
        }
        appendVideos(for: videosToReturn)
    }
    
    func markAsFavourite(video: FavouriteVideo) async throws {
        markAsFavouriteCalled = true
        markedVideo = video
        video.isFavourite.toggle()
    }
    
    func prefetchUpcomingVideos(currentIndex: Int, videos: [FavouriteVideo]) async {
        prefetchCalled = true
        prefetchedIndex = currentIndex
    }
}
