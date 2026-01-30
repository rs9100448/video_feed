//
//  FeedInteractor.swift
//  Video_Feed
//
//  Created by Ravindra Kumar Sonkar on 28/01/26.
//

import Foundation
import Combine
import SwiftData

class FeedInteractor: FeedInteractorProtocol, ObservableObject {

    @Published var model: FeedViewModel
    private let modelContext: ModelContext
    var repository: DataLayerRepo
    var currentPage: Int = 0
    private var lastPrefetchedIndex: Int = -1
    
    init(model: FeedViewModel,repository: DataLayerRepo, modelContext: ModelContext) {
        self.model = model
        self.modelContext = modelContext
        self.repository = repository
    }
    
    func error(for apiError: ApiError) {
        self.model.error = apiError
    }
    
    func success(for videos: [FavouriteVideo]) {
        self.model.videos = videos
    }
    
    func appendVideos(for videos: [FavouriteVideo]) {
        self.model.videos.append(contentsOf: videos)
    }
    
    func fetchData() async throws {
        currentPage = 0
        do {
            let videos: [VideoEntity] = try await self.repository.fetchVideos(page: currentPage)
            
            // Prefetch in background
            Task.detached(priority: .background) {[weak self] in
                await self?.repository.prefetchVideos(videos, limit: 3)
            }
            
            let favVideo = try await transformVideoToFavourite(videos: videos)
            self.success(for: favVideo)
            
            // Increment page for next load
            currentPage += 1
        } catch let error as ApiError {
            self.error(for: error)
        } catch {
            self.error(for: .unknown(error))
        }
    }
    
    func loadMoreData() async throws {
        do {
            let videos: [VideoEntity] = try await self.repository.fetchVideos(page: currentPage)
            
            // If no videos returned, we've reached the end
            guard !videos.isEmpty else {
                return
            }
            
            // Prefetch in background
            Task.detached(priority: .background) {[weak self] in
                await self?.repository.prefetchVideos(videos, limit: 2)
            }
            
            let favVideo = try await transformVideoToFavourite(videos: videos)
            self.appendVideos(for: favVideo)
            
            // Increment page for next load
            currentPage += 1
        } catch let error as ApiError {
            self.error(for: error)
        } catch {
            self.error(for: .unknown(error))
        }
    }
    
    // MARK: - Video Prefetching Logic
    func prefetchUpcomingVideos(currentIndex: Int, videos: [FavouriteVideo]) async {
        // Only prefetch if we've moved to a new video
        guard currentIndex > lastPrefetchedIndex else { return }
        lastPrefetchedIndex = currentIndex
        
        // Prefetch next 3 videos ahead
        let videosToPreload = 3
        let startIndex = currentIndex + 1
        let endIndex = min(startIndex + videosToPreload, videos.count)
        
        // Run prefetch in background
        Task.detached(priority: .background) { [weak self] in
            guard let self = self else { return }
            
            for index in startIndex..<endIndex {
                let video = videos[index]
                guard let videoURL = URL(string: video.videoURL) else {
                    print("⚠️ Invalid URL for video at index \(index)")
                    continue
                }
                
                // Check if already cached
                let isCached = await self.repository.isVideoCached(url: videoURL)
                if isCached {
                    print("✅ Video \(index) already cached: \(videoURL.lastPathComponent)")
                    continue
                }
                
                // Cache the video
                print("⬇️ Prefetching video \(index): \(videoURL.lastPathComponent)")
                do {
                    try await self.repository.cacheVideo(url: videoURL)
                    print("✅ Successfully cached video \(index)")
                } catch {
                    print("❌ Failed to cache video \(index): \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func transformVideoToFavourite(videos: [VideoEntity]) async throws -> [FavouriteVideo] {
        // Fetch all favourites once instead of per video
        let allFavourites = try fetchAllFavourites()
        let favouritesDict = Dictionary(uniqueKeysWithValues: allFavourites.map { ($0.id, $0) })
        
        // Map videos with O(1) lookup
        return videos.map { video in
            let favVideo = FavouriteVideo(video)
            if let _ = favouritesDict[favVideo.id] {
                favVideo.isFavourite = true
            }
            return favVideo
        }
    }

    // Add this helper method to fetch all favourites at once
    private func fetchAllFavourites() throws -> [FavouriteVideo] {
        let descriptor = FetchDescriptor<FavouriteVideo>()
        return try modelContext.fetch(descriptor)
    }

    
    func markAsFavourite(video: FavouriteVideo) async throws {
        let videoId = video.id
        let descriptor = FetchDescriptor<FavouriteVideo>(
            predicate: #Predicate<FavouriteVideo> { vid in
                vid.id == videoId
            }
        )
        
        if let vid = try modelContext.fetch(descriptor).first {
            vid.isFavourite = false
            modelContext.delete(vid)
            try modelContext.save()
        }else {
            modelContext.insert(video)
        }

    }
}
