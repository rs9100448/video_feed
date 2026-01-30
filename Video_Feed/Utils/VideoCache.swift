//
//  VideoCache.swift
//  Video_Feed
//
//  Created by Ravindra Kumar Sonkar on 29/01/26.
//

import SwiftUI
import AVFoundation

// MARK: - Cache Configuration
struct CacheConfig: Sendable {
    var maxCacheSize: Int64 = 500_000_000 // 500 MB default
    var maxCacheAge: TimeInterval = 7 * 24 * 60 * 60 // 7 days
    var cleanupInterval: TimeInterval = 24 * 60 * 60 // 1 day
    var enableAutomaticCleanup: Bool = true
}

// MARK: - Cache Metadata
struct CacheMetadata: Codable, Sendable {
    let url: String
    let fileSize: Int64
    let createdAt: Date
    var lastAccessedAt: Date
    var accessCount: Int
    
    mutating func recordAccess() {
        lastAccessedAt = Date()
        accessCount += 1
    }
}

// MARK: - Video Cache (Swift 6 Compliant)
actor VideoCache {
    // Use lazy initialization for shared instance
    static let shared: VideoCache = {
        let config = CacheConfig()
        let paths = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        let cacheDir = paths[0].appendingPathComponent("VideoCache")
        
        // Create directory before actor initialization
        try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
        
        return VideoCache(cacheDir: cacheDir, config: config)
    }()
    
    private let fileManager = FileManager.default
    private let cacheDir: URL
    private let metadataURL: URL
    private var config: CacheConfig
    private var metadata: [String: CacheMetadata]
    private var cleanupTask: Task<Void, Never>?
    
    // Private init - use shared instance
    private init(cacheDir: URL, config: CacheConfig) {
        self.cacheDir = cacheDir
        self.metadataURL = cacheDir.appendingPathComponent("metadata.json")
        self.config = config
        self.metadata = [:]
        
        // Load metadata synchronously in init (actor-isolated context)
        if let data = try? Data(contentsOf: metadataURL),
           let decoded = try? JSONDecoder().decode([String: CacheMetadata].self, from: data) {
            self.metadata = decoded
        }
    }
    
    // Start automatic cleanup
    func startAutomaticCleanup() {
        guard config.enableAutomaticCleanup else { return }
        
        // Cancel existing task if any
        cleanupTask?.cancel()
        
        // Start new cleanup task
        cleanupTask = Task {
            while !Task.isCancelled && config.enableAutomaticCleanup {
                // Wait for cleanup interval
                try? await Task.sleep(nanoseconds: UInt64(config.cleanupInterval * 1_000_000_000))
                
                // Check if still should run
                guard !Task.isCancelled else { break }
                
                // Perform cleanup
                try? await performAutomaticCleanup()
            }
        }
    }
    
    func stopAutomaticCleanup() {
        cleanupTask?.cancel()
        cleanupTask = nil
    }
    
    // MARK: - Core Cache Operations
    
    func cacheURL(for url: URL) -> URL {
        let fileName = url.lastPathComponent
        return cacheDir.appendingPathComponent(fileName)
    }
    
    func isCached(_ url: URL) -> Bool {
        let path = cacheURL(for: url).path
        return fileManager.fileExists(atPath: path)
    }
    
    func save(data: Data, for url: URL) async throws {
        // Check if we need to free up space
        let currentSize = await getCurrentCacheSize()
        if currentSize + Int64(data.count) > config.maxCacheSize {
            try await evictLRUCache(toFreeBytes: Int64(data.count))
        }
        
        // Save file
        let cacheURL = cacheURL(for: url)
        try data.write(to: cacheURL)
        
        // Update metadata
        let meta = CacheMetadata(
            url: url.absoluteString,
            fileSize: Int64(data.count),
            createdAt: Date(),
            lastAccessedAt: Date(),
            accessCount: 1
        )
        metadata[url.absoluteString] = meta
        saveMetadata()
    }
    
    func getCachedData(for url: URL) async throws -> Data {
        let cacheURL = cacheURL(for: url)
        
        // Update access metadata
        if var meta = metadata[url.absoluteString] {
            await meta.recordAccess()
            metadata[url.absoluteString] = meta
            saveMetadata()
        }
        
        return try Data(contentsOf: cacheURL)
    }
    
    func delete(url: URL) throws {
        let cacheURL = cacheURL(for: url)
        try fileManager.removeItem(at: cacheURL)
        metadata.removeValue(forKey: url.absoluteString)
        saveMetadata()
    }
    
    // MARK: - Cache Size Management
    
    func getCurrentCacheSize() async -> Int64 {
        guard let contents = try? fileManager.contentsOfDirectory(
            at: cacheDir,
            includingPropertiesForKeys: [.fileSizeKey]
        ) else {
            return 0
        }
        
        var totalSize: Int64 = 0
        for url in contents {
            // Exclude metadata file
            guard url.pathExtension != "json" else { continue }
            
            if let fileSize = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                totalSize += Int64(fileSize)
            }
        }
        
        return totalSize
    }
    
    func getCacheInfo() async -> CacheInfo {
        let size = await getCurrentCacheSize()
        let fileCount = (try? fileManager.contentsOfDirectory(at: cacheDir, includingPropertiesForKeys: nil))?.filter { $0.pathExtension != "json" }.count ?? 0
        
        return CacheInfo(
            totalSize: size,
            fileCount: fileCount,
            maxSize: config.maxCacheSize,
            utilizationPercentage: Double(size) / Double(config.maxCacheSize) * 100
        )
    }
    
    // MARK: - Cache Cleanup
    
    func clearCache() async throws {
        let contents = try fileManager.contentsOfDirectory(at: cacheDir, includingPropertiesForKeys: nil)
        
        for url in contents {
            try fileManager.removeItem(at: url)
        }
        
        metadata.removeAll()
        saveMetadata()
    }
    
    func cleanOldCache() async throws {
        let cutoffDate = Date().addingTimeInterval(-config.maxCacheAge)
        var deletedCount = 0
        var freedBytes: Int64 = 0
        
        let urlsToDelete = metadata.filter { $0.value.createdAt < cutoffDate }
        
        for (urlString, meta) in urlsToDelete {
            if let url = URL(string: urlString) {
                try? delete(url: url)
                deletedCount += 1
                freedBytes += meta.fileSize
            }
        }
        
        if deletedCount > 0 {
        }
    }
    
    func evictLRUCache(toFreeBytes bytesNeeded: Int64) async throws {
        var freedBytes: Int64 = 0
        
        // Sort by last accessed date (LRU)
        let sortedByLRU = metadata.sorted { $0.value.lastAccessedAt < $1.value.lastAccessedAt }
        
        for (urlString, meta) in sortedByLRU {
            if freedBytes >= bytesNeeded { break }
            
            if let url = URL(string: urlString) {
                try? delete(url: url)
                freedBytes += meta.fileSize
            }
        }
    }
    
    func deleteUnusedCache(maxAccessCount: Int = 1) async throws {
        var deletedCount = 0
        var freedBytes: Int64 = 0
        
        let urlsToDelete = metadata.filter { $0.value.accessCount <= maxAccessCount }
        
        for (urlString, meta) in urlsToDelete {
            if let url = URL(string: urlString) {
                try? delete(url: url)
                deletedCount += 1
                freedBytes += meta.fileSize
            }
        }
        
        if deletedCount > 0 {
#if DEBUG
            print("🗑️ Deleted \(deletedCount) unused files, freed \(ByteCountFormatter.string(fromByteCount: freedBytes, countStyle: .file))")
#endif
        }
    }
    
    // MARK: - Automatic Cleanup
    
    func performAutomaticCleanup() async throws {
        
        // 1. Remove old files
        try await cleanOldCache()
        
        // 2. Check if over size limit
        let currentSize = await getCurrentCacheSize()
        if currentSize > config.maxCacheSize {
            let excessBytes = currentSize - config.maxCacheSize
            try await evictLRUCache(toFreeBytes: excessBytes)
        }
        
    }
    
    // MARK: - Metadata Management
    
    private func saveMetadata() {
        guard let data = try? JSONEncoder().encode(metadata) else { return }
        try? data.write(to: metadataURL)
    }
    
    // MARK: - Configuration
    
    func updateConfig(_ newConfig: CacheConfig) {
        self.config = newConfig
        
        // Restart cleanup with new config
        if newConfig.enableAutomaticCleanup {
            startAutomaticCleanup()
        } else {
            stopAutomaticCleanup()
        }
    }
    
    func getConfig() -> CacheConfig {
        config
    }
}

// MARK: - Cache Info Model
struct CacheInfo: Sendable {
    let totalSize: Int64
    let fileCount: Int
    let maxSize: Int64
    let utilizationPercentage: Double
    
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }
    
    var formattedMaxSize: String {
        ByteCountFormatter.string(fromByteCount: maxSize, countStyle: .file)
    }
}
