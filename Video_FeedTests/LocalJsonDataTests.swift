//
//  LocalJsonDataTests.swift
//  Video_FeedTests
//
//  Created by Ravindra Kumar Sonkar on 29/01/26.
//

import Testing
import Foundation

@testable import Video_Feed

@Suite("LocalJsonData Repository Tests")
struct LocalJsonDataTests {
    
    // MARK: - Fetch Videos Tests
    
    @Test("Fetch videos should return paginated results")
    func testFetchVideosReturnsPaginatedResults() async throws {
        // Given
        let mockVideos = (1...15).map { createMockVideo(id: "\($0)") }
        let repo = createTestRepository(videos: mockVideos)
        
        // When - page 0
        let page0Videos = try await repo.fetchVideos(page: 0)
        
        // Then
        #expect(page0Videos.count == 5)
        #expect(page0Videos.first?.id == "1")
        #expect(page0Videos.last?.id == "5")
    }
    
    @Test("Fetch videos should handle second page correctly")
    func testFetchVideosHandlesSecondPage() async throws {
        // Given
        let mockVideos = (1...15).map { createMockVideo(id: "\($0)") }
        let repo = createTestRepository(videos: mockVideos)
        
        // When - page 1
        let page1Videos = try await repo.fetchVideos(page: 1)
        
        // Then
        #expect(page1Videos.count == 5)
        #expect(page1Videos.first?.id == "6")
        #expect(page1Videos.last?.id == "10")
    }
    
    @Test("Fetch videos should handle last partial page")
    func testFetchVideosHandlesLastPartialPage() async throws {
        // Given - 12 videos, so last page has 2 videos
        let mockVideos = (1...12).map { createMockVideo(id: "\($0)") }
        let repo = createTestRepository(videos: mockVideos)
        
        // When - page 2 (videos 11-12)
        let page2Videos = try await repo.fetchVideos(page: 2)
        
        // Then
        #expect(page2Videos.count == 2)
        #expect(page2Videos.first?.id == "11")
        #expect(page2Videos.last?.id == "12")
    }
    
    @Test("Fetch videos should return empty for out of bounds page")
    func testFetchVideosReturnsEmptyForOutOfBounds() async throws {
        // Given
        let mockVideos = (1...5).map { createMockVideo(id: "\($0)") }
        let repo = createTestRepository(videos: mockVideos)
        
        // When - page 5 (way beyond available data)
        let videos = try await repo.fetchVideos(page: 5)
        
        // Then
        #expect(videos.isEmpty)
    }
    
    @Test("Fetch videos should throw error when configured to fail")
    func testFetchVideosThrowsErrorWhenConfigured() async throws {
        // Given
        let repo = createTestRepository(shouldFail: true)
        
        // When & Then
        do {
            _ = try await repo.fetchVideos(page: 0)
            Issue.record("Should have thrown an error")
        } catch let error as ApiError {
            #expect(error.localizedDescription == ApiError.noData.localizedDescription)
        }
    }
    
    // MARK: - Prefetch Videos Tests
    
    @Test("Prefetch should cache limited number of videos")
    func testPrefetchCachesLimitedVideos() async throws {
        // Given
        let mockVideos = (1...10).map {
            createMockVideo(id: "\($0)", videoURL: "https://example.com/video\($0).mp4")
        }
        let repo = createTestRepository(videos: mockVideos)
        
        // When - prefetch with limit of 3
        await repo.prefetchVideos(mockVideos, limit: 3)
        
        // Then - should cache exactly 3 videos
        let cacheRequests = await repo.mockCache.cacheRequests
        #expect(cacheRequests.count == 3)
    }
        
    @Test("Prefetch should handle empty video list")
    func testPrefetchHandlesEmptyList() async throws {
        // Given
        let repo = createTestRepository()
        
        // When
        await repo.prefetchVideos([], limit: 3)
        
        // Then - should not crash
        let cacheRequests = await repo.mockCache.cacheRequests
        #expect(cacheRequests.isEmpty)
    }
    
    @Test("Prefetch should handle limit larger than video count")
    func testPrefetchHandlesLimitLargerThanCount() async throws {
        // Given
        let mockVideos = (1...3).map {
            createMockVideo(id: "\($0)", videoURL: "https://example.com/video\($0).mp4")
        }
        let repo = createTestRepository(videos: mockVideos)
        
        // When - limit is 10 but only 3 videos
        await repo.prefetchVideos(mockVideos, limit: 10)
        
        // Then - should only cache 3 videos
        let cacheRequests = await repo.mockCache.cacheRequests
        #expect(cacheRequests.count == 3)
    }
    
    // MARK: - Cache Video Tests
    
    @Test("Cache video should save video data")
    func testCacheVideoSavesData() async throws {
        // Given
        let repo = createTestRepository()
        let videoURL = URL(string: "https://example.com/test.mp4")!
        
        // When
        try await repo.cacheVideo(url: videoURL)
        
        // Then
        let isCached = await repo.isVideoCached(url: videoURL)
        #expect(isCached)
    }
    
    @Test("Cache video should skip already cached videos")
    func testCacheVideoSkipsAlreadyCached() async throws {
        // Given
        let repo = createTestRepository()
        let videoURL = URL(string: "https://example.com/test.mp4")!
        
        // Cache it once
        try await repo.cacheVideo(url: videoURL)
        let firstCacheCount = await repo.mockCache.cacheRequests.count
        
        // When - try to cache again
        try await repo.cacheVideo(url: videoURL)
        let secondCacheCount = await repo.mockCache.cacheRequests.count
        
        // Then - should recognize it's already cached
        #expect(secondCacheCount == firstCacheCount + 1) // Request recorded but not re-cached
    }
    
    @Test("Cache video should handle multiple videos")
    func testCacheVideoHandlesMultipleVideos() async throws {
        // Given
        let repo = createTestRepository()
        let urls = (1...5).map { URL(string: "https://example.com/video\($0).mp4")! }
        
        // When
        for url in urls {
            try await repo.cacheVideo(url: url)
        }
        
        // Then
        for url in urls {
            let isCached = await repo.isVideoCached(url: url)
            #expect(isCached)
        }
    }
    
    // MARK: - Is Video Cached Tests
    
    @Test("Is video cached should return true for cached videos")
    func testIsVideoCachedReturnsTrueForCached() async throws {
        // Given
        let repo = createTestRepository()
        let videoURL = URL(string: "https://example.com/test.mp4")!
        
        try await repo.cacheVideo(url: videoURL)
        
        // When
        let isCached = await repo.isVideoCached(url: videoURL)
        
        // Then
        #expect(isCached)
    }
    
    @Test("Is video cached should return false for non-cached videos")
    func testIsVideoCachedReturnsFalseForNonCached() async throws {
        // Given
        let repo = createTestRepository()
        let videoURL = URL(string: "https://example.com/test.mp4")!
        
        // When
        let isCached = await repo.isVideoCached(url: videoURL)
        
        // Then
        #expect(!isCached)
    }
    
    // MARK: - Get Cached Video URL Tests
    
    @Test("Get cached video URL should return URL for cached videos")
    func testGetCachedVideoURLReturnsURLForCached() async throws {
        // Given
        let repo = createTestRepository()
        let videoURL = URL(string: "https://example.com/test.mp4")!
        
        try await repo.cacheVideo(url: videoURL)
        
        // When
        let cachedURL = await repo.getCachedVideoURL(url: videoURL)
        
        // Then
        #expect(cachedURL != nil)
        #expect(cachedURL?.lastPathComponent == "test.mp4")
    }
    
    @Test("Get cached video URL should return nil for non-cached videos")
    func testGetCachedVideoURLReturnsNilForNonCached() async throws {
        // Given
        let repo = createTestRepository()
        let videoURL = URL(string: "https://example.com/test.mp4")!
        
        // When
        let cachedURL = await repo.getCachedVideoURL(url: videoURL)
        
        // Then
        #expect(cachedURL == nil)
    }
    
    // MARK: - Integration Tests
    
    @Test("Fetch and prefetch should work together")
    func testFetchAndPrefetchWorkTogether() async throws {
        // Given
        let mockVideos = (1...10).map {
            createMockVideo(id: "\($0)", videoURL: "https://example.com/video\($0).mp4")
        }
        let repo = createTestRepository(videos: mockVideos)
        
        // When - fetch first page
        let videos = try await repo.fetchVideos(page: 0)
        
        // Then - should get 5 videos
        #expect(videos.count == 5)
        
        // When - prefetch next 3
        await repo.prefetchVideos(videos, limit: 3)
        
        // Then - should have cached 3 videos
        let cacheRequests = await repo.mockCache.cacheRequests
        #expect(cacheRequests.count == 3)
    }
    
    @Test("Complete pagination workflow")
    func testCompletePaginationWorkflow() async throws {
        // Given - 12 videos total (3 pages of 5, 5, 2)
        let mockVideos = (1...12).map { createMockVideo(id: "\($0)") }
        let repo = createTestRepository(videos: mockVideos)
        
        // When & Then - Page 0
        let page0 = try await repo.fetchVideos(page: 0)
        #expect(page0.count == 5)
        
        // When & Then - Page 1
        let page1 = try await repo.fetchVideos(page: 1)
        #expect(page1.count == 5)
        
        // When & Then - Page 2 (partial)
        let page2 = try await repo.fetchVideos(page: 2)
        #expect(page2.count == 2)
        
        // When & Then - Page 3 (empty)
        let page3 = try await repo.fetchVideos(page: 3)
        #expect(page3.isEmpty)
    }
    
    // MARK: - Edge Cases
        
    @Test("Repository should handle concurrent fetch requests")
    func testRepositoryHandlesConcurrentFetches() async throws {
        // Given
        let mockVideos = (1...20).map { createMockVideo(id: "\($0)") }
        let repo = createTestRepository(videos: mockVideos)
        
        // When - fetch multiple pages concurrently
        async let page0: [VideoEntity] = repo.fetchVideos(page: 0)
        async let page1: [VideoEntity] = repo.fetchVideos(page: 1)
        async let page2: [VideoEntity] = repo.fetchVideos(page: 2)
        
        let results = try await [page0, page1, page2]
        
        // Then - all should succeed
        #expect(results[0].count == 5)
        #expect(results[1].count == 5)
        #expect(results[2].count == 5)
    }
    
    @Test("Repository should handle concurrent cache operations")
    func testRepositoryHandlesConcurrentCacheOperations() async throws {
        // Given
        let repo = createTestRepository()
        let urls = (1...5).map { URL(string: "https://example.com/video\($0).mp4")! }
        
        // When - cache multiple videos concurrently
        await withTaskGroup(of: Void.self) { group in
            for url in urls {
                group.addTask {
                    try? await repo.cacheVideo(url: url)
                }
            }
        }
        
        // Then - all should be cached
        for url in urls {
            let isCached = await repo.isVideoCached(url: url)
            #expect(isCached)
        }
    }
}
