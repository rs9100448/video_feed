//
//  TestableLocalJsonData.swift
//  Video_FeedTests
//
//  Created by Ravindra Kumar Sonkar on 30/01/26.
//

import Foundation
@testable import Video_Feed

// MARK: - Test LocalJsonData Implementation

final class TestableLocalJsonData: DataLayerRepo {
    let mockCache = MockVideoCache()
    var shouldFailFetch = false
    var mockVideos: [VideoEntity] = []
    
    func fetchVideos(page: Int) async throws -> [VideoEntity] {
        if shouldFailFetch {
            throw ApiError.noData
        }
        
        // Simulate pagination
        let pageSize = 5
        let start = page * pageSize
        let end = min(start + pageSize, mockVideos.count)
        
        guard start < mockVideos.count else {
            return []
        }
        
        return Array(mockVideos[start..<end])
    }
    
    func prefetchVideos(_ videos: [VideoEntity], limit: Int) async {
        let videosToCache = Array(videos.prefix(limit))
        
        for video in videosToCache {
            guard let url = URL(string: video.videoURL) else { continue }
            try? await cacheVideo(url: url)
        }
    }
    
    func getCachedVideoURL(url: URL) async -> URL? {
        await mockCache.cacheURL(for: url)
    }
    
    func cacheVideo(url: URL) async throws {
        await mockCache.recordCacheRequest(url)
        
        if await mockCache.isCached(url) {
            return
        }
        
        // Simulate caching
        let data = Data(repeating: 0xFF, count: 1000)
        try await mockCache.save(data: data, for: url)
    }
    
    func isVideoCached(url: URL) async -> Bool {
        await mockCache.isCached(url)
    }
}

// MARK: - Helper Methods

func createTestRepository(
    videos: [VideoEntity] = [],
    shouldFail: Bool = false
) -> TestableLocalJsonData {
    let repo = TestableLocalJsonData()
    repo.mockVideos = videos
    repo.shouldFailFetch = shouldFail
    return repo
}

func createMockVideo(
    id: String = "test-1",
    videoURL: String = "https://example.com/video.mp4"
) -> VideoEntity {
    VideoEntity(
        id: id,
        title: "Test Video",
        description: "Test Description",
        videoURL: videoURL,
        thumbnailURL: "https://example.com/thumb.jpg",
        duration: 120,
        views: 1000,
        likes: 100,
        createdAt: "2026-01-29T00:00:00Z",
        products: []
    )
}
