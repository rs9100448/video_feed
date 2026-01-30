//
//  TestHelpers.swift
//  Video_FeedTests
//
//  Created by Ravindra Kumar Sonkar on 30/01/26.
//

import Foundation
@testable import Video_Feed

// MARK: - VideoEntity Test Helpers

extension VideoEntity {
    /// Creates a test VideoEntity with default values for testing
    static func testEntity(
        id: String = "test-1",
        title: String = "Test Video",
        description: String = "Test Description",
        videoURL: String = "https://example.com/video.mp4",
        thumbnailURL: String = "https://example.com/thumb.jpg",
        duration: Int = 120,
        views: Int = 1000,
        likes: Int = 100,
        createdAt: String = "2026-01-29T00:00:00Z",
        products: [Product] = []
    ) -> VideoEntity {
        VideoEntity(
            id: id,
            title: title,
            description: description,
            videoURL: videoURL,
            thumbnailURL: thumbnailURL,
            duration: duration,
            views: views,
            likes: likes,
            createdAt: createdAt,
            products: products
        )
    }
}

// MARK: - Product Test Helpers

extension Product {
    /// Creates a test Product with default values for testing
    static func testProduct(
        id: String = "p1",
        name: String = "Test Product",
        brand: String = "Test Brand",
        price: Double = 99.99,
        originalPrice: Double? = 129.99,
        currency: Currency = .usd,
        imageURL: String = "https://example.com/product.jpg",
        rating: Double = 4.5,
        reviewCount: Int = 100,
        inStock: Bool = true,
        category: String = "Electronics",
        description: String = "Test product description",
        specifications: [String] = ["Spec 1", "Spec 2"]
    ) -> Product {
        Product(
            id: id,
            name: name,
            brand: brand,
            price: price,
            originalPrice: originalPrice,
            currency: currency,
            imageURL: imageURL,
            rating: rating,
            reviewCount: reviewCount,
            inStock: inStock,
            category: category,
            description: description,
            specifications: specifications
        )
    }
}

// MARK: - FavouriteVideo Test Helpers

extension FavouriteVideo {
    /// Creates a test FavouriteVideo with default values for testing
    static func testFavourite(
        id: String = "fav-1",
        videoURL: String = "https://example.com/video.mp4",
        thumbnailURL: String = "https://example.com/thumb.jpg",
        duration: Int = 120,
        title: String = "Test Favourite",
        desc: String = "Test Description",
        products: [Product] = [],
        isFavourite: Bool = false
    ) -> FavouriteVideo {
        FavouriteVideo(
            id: id,
            videoURL: videoURL,
            thumbnailURL: thumbnailURL,
            duration: duration,
            title: title,
            desc: desc,
            products: products,
            isFavourite: isFavourite
        )
    }
}

// MARK: - Test Data Generators

struct TestDataGenerator {
    
    /// Generates multiple test videos
    static func videos(count: Int, withProducts: Bool = false) -> [VideoEntity] {
        (1...count).map { index in
            let products = withProducts ? [Product.testProduct(id: "p\(index)", name: "Product \(index)")] : []
            return VideoEntity.testEntity(
                id: "v\(index)",
                title: "Video \(index)",
                videoURL: "https://example.com/video\(index).mp4",
                products: products
            )
        }
    }
    
    /// Generates multiple test products
    static func products(count: Int) -> [Product] {
        (1...count).map { index in
            Product.testProduct(
                id: "p\(index)",
                name: "Product \(index)",
                price: Double(index * 10)
            )
        }
    }
    
    /// Generates multiple test favourites
    static func favourites(count: Int) -> [FavouriteVideo] {
        (1...count).map { index in
            FavouriteVideo.testFavourite(
                id: "fav\(index)",
                title: "Favourite \(index)",
                isFavourite: true
            )
        }
    }
}

// MARK: - URL Test Helpers

extension URL {
    /// Creates a test video URL
    static func testVideoURL(name: String = "test-video.mp4") -> URL {
        URL(string: "https://example.com/\(name)")!
    }
    
    /// Creates a test image URL
    static func testImageURL(name: String = "test-image.jpg") -> URL {
        URL(string: "https://example.com/\(name)")!
    }
}

// MARK: - Assertion Helpers

/// Custom assertion helpers for common test scenarios
struct TestAssertions {
    
    /// Verifies that a video has the expected basic properties
    static func assertVideoBasics(_ video: FavouriteVideo, id: String, title: String) {
        assert(video.id == id, "Video ID mismatch")
        assert(video.title == title, "Video title mismatch")
        assert(!video.videoURL.isEmpty, "Video URL should not be empty")
    }
    
    /// Verifies that a product has the expected basic properties
    static func assertProductBasics(_ product: Product, id: String, name: String, price: Double) {
        assert(product.id == id, "Product ID mismatch")
        assert(product.name == name, "Product name mismatch")
        assert(product.price == price, "Product price mismatch")
    }
}
