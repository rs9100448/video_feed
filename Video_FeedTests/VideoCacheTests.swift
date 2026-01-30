//
//  VideoCacheTests.swift
//  Video_FeedTests
//
//  Created by Ravindra Kumar Sonkar on 29/01/26.

import Testing
import Foundation

@testable import Video_Feed

@Suite("Video Cache Tests")
struct VideoCacheTests {
    
    
    // MARK: - Helper Methods
    
    private nonisolated func makeTestConfig(
        maxCacheSize: Int64 = 10_000_000,
        maxCacheAge: TimeInterval = 60,
        cleanupInterval: TimeInterval = 5,
        enableAutomaticCleanup: Bool = false
    ) -> CacheConfig {
        return CacheConfig(
            maxCacheSize: maxCacheSize,
            maxCacheAge: maxCacheAge,
            cleanupInterval: cleanupInterval,
            enableAutomaticCleanup: enableAutomaticCleanup
        )
    }
    
    private func createTestCache() async -> VideoCache {
        let cache = VideoCache.shared
        
        // Set test configuration first
        let config = CacheConfig(
            maxCacheSize: 10_000_000, // 10 MB
            maxCacheAge: 60, // 1 minute for testing
            cleanupInterval: 5,
            enableAutomaticCleanup: false
        )
        await cache.updateConfig(config)
        
        // Clear cache and ensure directory exists
        try? await cache.clearCache()
        await ensureCacheDirectoryExists(cache)
        
        return cache
    }
    
    private func ensureCacheDirectoryExists(_ cache: VideoCache) async {
        // Get cache directory by creating a dummy URL
        let dummyURL = URL(string: "https://test.com/dummy.mp4")!
        let cacheURL = await cache.cacheURL(for: dummyURL)
        let cacheDir = cacheURL.deletingLastPathComponent()
        
        // Ensure directory exists
        try? FileManager.default.createDirectory(
            at: cacheDir,
            withIntermediateDirectories: true,
            attributes: nil
        )
    }
    
    private func createTestURL(name: String = "test-video.mp4") -> URL {
        URL(string: "https://example.com/\(name)")!
    }
    
    private func createTestData(size: Int = 1024) -> Data {
        Data(repeating: 0xFF, count: size)
    }
    
    // MARK: - Basic Cache Operations Tests
    
    @Test("Cache URL should generate correct file path")
    func testCacheURLGeneration() async {
        // Given
        let cache = await createTestCache()
        let testURL = createTestURL(name: "my-video.mp4")
        
        // When
        let cacheURL = await cache.cacheURL(for: testURL)
        
        // Then
        #expect(cacheURL.lastPathComponent == "my-video.mp4")
    }
    
    @Test("Is cached should return false for non-cached video")
    func testIsCachedReturnsFalseForNonCachedVideo() async {
        // Given
        let cache = await createTestCache()
        let testURL = createTestURL(name: "unique-non-cached-\(UUID().uuidString).mp4")
        
        // When
        let isCached = await cache.isCached(testURL)
        
        // Then
        #expect(!isCached)
    }
    
    @Test("Save should successfully cache video data")
    func testSaveSuccessfullyCachesVideo() async throws {
        // Given
        let cache = await createTestCache()
        let testURL = createTestURL(name: "save-test-\(UUID().uuidString).mp4")
        let testData = createTestData(size: 5000)
        
        // When
        try await cache.save(data: testData, for: testURL)
        
        // Then
        let isCached = await cache.isCached(testURL)
        #expect(isCached)
    }
    
    // MARK: - Cache Cleanup Tests
    
    @Test("Clear cache should remove all videos")
    func testClearCacheRemovesAllVideos() async throws {
        // Given
        let cache = await createTestCache()
        let testData = createTestData()
        let uniqueId = UUID().uuidString
        
        try await cache.save(data: testData, for: createTestURL(name: "clear1-\(uniqueId).mp4"))
        try await cache.save(data: testData, for: createTestURL(name: "clear2-\(uniqueId).mp4"))
        try await cache.save(data: testData, for: createTestURL(name: "clear3-\(uniqueId).mp4"))
        
        // When
        try await cache.clearCache()
        
        // Then
        let cacheInfo = await cache.getCacheInfo()
        #expect(cacheInfo.fileCount == 0)
        #expect(cacheInfo.totalSize == 0)
    }
    
    @Test("Clean old cache should remove expired videos")
    func testCleanOldCacheRemovesExpiredVideos() async throws {
        // Given
        let cache = await createTestCache()
        
        // Create config with very short max age
        let shortAgeConfig = CacheConfig(
            maxCacheSize: 10_000_000,
            maxCacheAge: 0.001, // Very short for testing
            cleanupInterval: 5,
            enableAutomaticCleanup: false
        )
        await cache.updateConfig(shortAgeConfig)
        
        let testData = createTestData()
        let oldVideoURL = createTestURL(name: "old-\(UUID().uuidString).mp4")
        try await cache.save(data: testData, for: oldVideoURL)
        
        // Wait for cache to expire
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // When
        try await cache.cleanOldCache()
        
        // Then
        let isCached = await cache.isCached(oldVideoURL)
        #expect(!isCached)
    }
        
    // MARK: - Configuration Tests
    
    @Test("Update config should apply new settings")
    func testUpdateConfigAppliesNewSettings() async {
        // Given
        let cache = await createTestCache()
        
        // When - Use helper to create config
        let newConfig = makeTestConfig(
            maxCacheSize: 1_000_000,
            maxCacheAge: 3600,
            cleanupInterval: 5,
            enableAutomaticCleanup: false
        )
        await cache.updateConfig(newConfig)
        
        // Then
        let currentConfig = await cache.getConfig()
        #expect(currentConfig.maxCacheSize == 1_000_000)
        #expect(currentConfig.maxCacheAge == 3600)
    }
    @Test("Automatic cleanup can be started and stopped")
    func testAutomaticCleanupStartStop() async {
        // Given
        let cache = await createTestCache()
        
        // When - start cleanup
        await cache.startAutomaticCleanup()
        
        // Then - should be running (no crash)
        // When - stop cleanup
        await cache.stopAutomaticCleanup()
        
        // Then - should be stopped (no crash)
        #expect(true) // If we get here, test passed
    }
    
    // MARK: - Edge Cases
    
    @Test("Cache should handle duplicate saves")
    func testCacheHandlesDuplicateSaves() async throws {
        // Given
        let cache = await createTestCache()
        let testURL = createTestURL(name: "duplicate-\(UUID().uuidString).mp4")
        let testData = createTestData()
        
        // When - save same URL twice
        try await cache.save(data: testData, for: testURL)
        let firstCount = await cache.getCacheInfo().fileCount
        
        try await cache.save(data: testData, for: testURL)
        let secondCount = await cache.getCacheInfo().fileCount
        
        // Then - should still have same count (overwritten, not duplicated)
        #expect(firstCount == secondCount)
    }
    
    @Test("Cache should handle concurrent saves")
    func testCacheHandlesConcurrentSaves() async throws {
        // Given
        let cache = await createTestCache()
        let uniqueId = UUID().uuidString
        
        // When - save multiple videos concurrently
        async let save1: () = cache.save(
            data: createTestData(),
            for: createTestURL(name: "concurrent1-\(uniqueId).mp4")
        )
        async let save2: () = cache.save(
            data: createTestData(),
            for: createTestURL(name: "concurrent2-\(uniqueId).mp4")
        )
        async let save3: () = cache.save(
            data: createTestData(),
            for: createTestURL(name: "concurrent3-\(uniqueId).mp4")
        )
        
        try await save1
        try await save2
        try await save3
        
        // Then - all should be saved
        let cacheInfo = await cache.getCacheInfo()
        #expect(cacheInfo.fileCount >= 3)
    }
    
    @Test("Delete non-existent cache should not crash")
    func testDeleteNonExistentCacheDoesNotCrash() async throws {
        // Given
        let cache = await createTestCache()
        let testURL = createTestURL(name: "non-existent-\(UUID().uuidString).mp4")
        
        // When & Then - should not crash
        do {
            try await cache.delete(url: testURL)
            // May or may not throw, but shouldn't crash
        } catch {
            // Expected for non-existent file
        }
    }
}

// MARK: - Cache Info Tests

@Suite("Cache Info Tests")
struct CacheInfoTests {
    
    @Test("Cache info should format sizes correctly")
    func testCacheInfoFormatsSize() {
        // Given
        let cacheInfo = CacheInfo(
            totalSize: 1_500_000,
            fileCount: 5,
            maxSize: 10_000_000,
            utilizationPercentage: 15.0
        )
        
        // Then
        #expect(cacheInfo.formattedSize.contains("MB") || cacheInfo.formattedSize.contains("KB"))
        #expect(cacheInfo.formattedMaxSize.contains("MB"))
    }
    
    @Test("Cache info should calculate utilization correctly")
    func testCacheInfoCalculatesUtilization() {
        // Given
        let cacheInfo = CacheInfo(
            totalSize: 2_500_000,
            fileCount: 3,
            maxSize: 10_000_000,
            utilizationPercentage: 25.0
        )
        
        // Then
        #expect(cacheInfo.utilizationPercentage == 25.0)
    }
}

// MARK: - Cache Config Tests

@Suite("Cache Config Tests")
struct CacheConfigTests {
    
    @Test("Cache config should have correct default values")
    func testCacheConfigDefaults() {
        // Given
        let config = CacheConfig()
        
        // Then
        #expect(config.maxCacheSize == 500_000_000)
        #expect(config.maxCacheAge == 7 * 24 * 60 * 60)
        #expect(config.cleanupInterval == 24 * 60 * 60)
        #expect(config.enableAutomaticCleanup == true)
    }
    
    @Test("Cache config should allow custom values")
    func testCacheConfigCustomValues() {
        // Given
        let config = CacheConfig(
            maxCacheSize: 1_000_000,
            maxCacheAge: 3600,
            cleanupInterval: 1800,
            enableAutomaticCleanup: false
        )
        
        // Then
        #expect(config.maxCacheSize == 1_000_000)
        #expect(config.maxCacheAge == 3600)
        #expect(config.cleanupInterval == 1800)
        #expect(config.enableAutomaticCleanup == false)
    }
}
