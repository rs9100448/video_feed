//
//  LocalJsonData.swift
//  Video_Feed
//
//  Created by Ravindra Kumar Sonkar on 28/01/26.
//

import Foundation

protocol DataLayerRepo {
    func fetchVideos(page: Int) async throws -> [VideoEntity]
    func prefetchVideos(_ videos: [VideoEntity], limit: Int) async
    func getCachedVideoURL(url: URL) async -> URL?
    func cacheVideo(url: URL) async throws
    func isVideoCached(url: URL) async -> Bool
}

final class LocalJsonData: DataLayerRepo {
    
    func fetchVideos(page: Int) async throws -> [VideoEntity] {
        guard let url = Bundle.main.url(forResource: "videos_feed", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            throw ApiError.noData
        }
        
        let videoResponse = try JSONDecoder().decode(VideoResponse.self, from: data)
        
        // Simulate pagination
        let pageSize = 5
        let start = page * pageSize
        let end = min(start + pageSize, videoResponse.videos.count)
        
        guard start < videoResponse.videos.count else {
            return []
        }
        
        let videos = Array(videoResponse.videos[start..<end])
        
        // ✅ CACHE INTEGRATION: Prefetch first video in background
        if let firstVideo = videos.first,
           let videoURL = URL(string: firstVideo.videoURL) {
            Task.detached(priority: .background) {
                try? await self.cacheVideo(url: videoURL)
            }
        }
        
        return videos
    }
    
    func cacheVideo(url: URL) async throws {
        if await VideoCache.shared.isCached(url) {
            return
        }
                
        let (data, _) = try await URLSession.shared.data(from: url)
        
        try await VideoCache.shared.save(data: data, for: url)
    }
    
    func isVideoCached(url: URL) async -> Bool {
        await VideoCache.shared.isCached(url)
    }
    
    func getCachedVideoURL(url: URL) async -> URL? {
        if await VideoCache.shared.isCached(url) {
            return await VideoCache.shared.cacheURL(for: url)
        }
        return nil
    }
}

extension LocalJsonData {
    
    // Prefetch multiple videos
    func prefetchVideos(_ videos: [VideoEntity], limit: Int = 3) async {
        let videosToCache = Array(videos.prefix(limit))
        
        for video in videosToCache {
            guard let url = URL(string: video.videoURL) else { continue }
            try? await cacheVideo(url: url)
        }
    }
}
