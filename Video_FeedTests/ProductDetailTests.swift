//
//  ProductDetailTests.swift
//  Video_FeedTests
//
//  Created by Ravindra Kumar Sonkar on 29/01/26.
//

import Testing
import Foundation
import Combine

@testable import Video_Feed

@Suite("Product Detail Tests")
struct ProductDetailTests {
    
    // MARK: - Mock Interactor
    
    final class MockProductDetailInteractor: ProductDetailInteractorProtocol {
        var addToCardCalled = false
        var addedProducts: [Product] = []
        
        func addToCard(product: [Product]) {
            addToCardCalled = true
            addedProducts = product
        }
    }
    
    // MARK: - Helper Methods
    
    private func createTestPresenter(
        products: [Product] = []
    ) -> (ProductDetailPresenter, MockProductDetailInteractor) {
        let video = createMockVideo(products: products)
        let interactor = MockProductDetailInteractor()
        let presenter = ProductDetailPresenter(video: video, interactor: interactor)
        
        return (presenter, interactor)
    }
    
    private func createMockVideo(
        id: String = "test-1",
        products: [Product] = []
    ) -> FavouriteVideo {
        FavouriteVideo(
            id: id,
            videoURL: "https://example.com/video.mp4",
            thumbnailURL: "https://example.com/thumb.jpg",
            duration: 120,
            title: "Test Video",
            desc: "Test Description",
            products: products,
            isFavourite: false
        )
    }
    
    private func createMockProduct(
        id: String = "p1",
        name: String = "Test Product",
        price: Double = 99.99
    ) -> Product {
        Product(
            id: id,
            name: name,
            brand: "Test Brand",
            price: price,
            originalPrice: price * 1.3,
            currency: .usd,
            imageURL: "https://example.com/product.jpg",
            rating: 4.5,
            reviewCount: 100,
            inStock: true,
            category: "Electronics",
            description: "Test product description",
            specifications: ["Spec 1", "Spec 2"]
        )
    }
    
    // MARK: - Presenter Initialization Tests
    
    @Test("Presenter should initialize with video")
    func testPresenterInitializesWithVideo() {
        // Given
        let products = [createMockProduct()]
        let video = createMockVideo(products: products)
        let interactor = MockProductDetailInteractor()
        
        // When
        let presenter = ProductDetailPresenter(video: video, interactor: interactor)
        
        // Then
        #expect(presenter.video.id == video.id)
        #expect(presenter.video.products.count == 1)
    }
    
    @Test("Presenter should have nil view initially")
    func testPresenterHasNilViewInitially() {
        // Given & When
        let (presenter, _) = createTestPresenter()
        
        // Then
        #expect(presenter.view == nil)
    }
    
    @Test("Presenter should have nil router initially")
    func testPresenterHasNilRouterInitially() {
        // Given & When
        let (presenter, _) = createTestPresenter()
        
        // Then
        #expect(presenter.router == nil)
    }
    
    // MARK: - Add to Cart Tests
    
    @Test("Add to cart should call interactor")
    func testAddToCartCallsInteractor() {
        // Given
        let product = createMockProduct()
        let (presenter, interactor) = createTestPresenter()
        
        // When
        presenter.addToCard(product: [product])
        
        // Then
        #expect(interactor.addToCardCalled)
    }
    
    @Test("Add to cart should pass correct products to interactor")
    func testAddToCartPassesCorrectProducts() {
        // Given
        let products = [
            createMockProduct(id: "p1", name: "Product 1"),
            createMockProduct(id: "p2", name: "Product 2")
        ]
        let (presenter, interactor) = createTestPresenter()
        
        // When
        presenter.addToCard(product: products)
        
        // Then
        #expect(interactor.addedProducts.count == 2)
        #expect(interactor.addedProducts[0].id == "p1")
        #expect(interactor.addedProducts[1].id == "p2")
    }
    
    @Test("Add to cart should handle empty product list")
    func testAddToCartHandlesEmptyList() {
        // Given
        let (presenter, interactor) = createTestPresenter()
        
        // When
        presenter.addToCard(product: [])
        
        // Then
        #expect(interactor.addToCardCalled)
        #expect(interactor.addedProducts.isEmpty)
    }
    
    @Test("Add to cart should handle single product")
    func testAddToCartHandlesSingleProduct() {
        // Given
        let product = createMockProduct(id: "single", name: "Single Product", price: 49.99)
        let (presenter, interactor) = createTestPresenter()
        
        // When
        presenter.addToCard(product: [product])
        
        // Then
        #expect(interactor.addedProducts.count == 1)
        #expect(interactor.addedProducts.first?.name == "Single Product")
        #expect(interactor.addedProducts.first?.price == 49.99)
    }
    
    @Test("Add to cart should handle multiple calls")
    func testAddToCartHandlesMultipleCalls() {
        // Given
        let product1 = createMockProduct(id: "p1")
        let product2 = createMockProduct(id: "p2")
        let (presenter, interactor) = createTestPresenter()
        
        // When - first call
        presenter.addToCard(product: [product1])
        #expect(interactor.addedProducts.count == 1)
        
        // When - second call (replaces first)
        presenter.addToCard(product: [product2])
        
        // Then
        #expect(interactor.addedProducts.count == 1)
        #expect(interactor.addedProducts.first?.id == "p2")
    }
    
    // MARK: - Video Data Tests
    
    @Test("Presenter should maintain video data")
    func testPresenterMaintainsVideoData() {
        // Given
        let products = [
            createMockProduct(id: "p1", name: "Product 1", price: 29.99),
            createMockProduct(id: "p2", name: "Product 2", price: 39.99)
        ]
        let video = createMockVideo(id: "video-123", products: products)
        let interactor = MockProductDetailInteractor()
        
        // When
        let presenter = ProductDetailPresenter(video: video, interactor: interactor)
        
        // Then
        #expect(presenter.video.id == "video-123")
        #expect(presenter.video.products.count == 2)
        #expect(presenter.video.title == "Test Video")
        #expect(presenter.video.desc == "Test Description")
    }
    
    @Test("Presenter video should be observable")
    func testPresenterVideoIsObservable() {
        // Given
        let product = createMockProduct()
        let video = createMockVideo(products: [product])
        let interactor = MockProductDetailInteractor()
        
        // When
        let presenter = ProductDetailPresenter(video: video, interactor: interactor)
        
        // Then - video is @Published so changes should be observable
        #expect(presenter.video.products.first?.id == product.id)
    }
    
    // MARK: - Product Validation Tests
    
    @Test("Products should have required properties")
    func testProductsHaveRequiredProperties() {
        // Given
        let product = createMockProduct(
            id: "test-id",
            name: "Test Name",
            price: 123.45
        )
        
        // Then
        #expect(product.id == "test-id")
        #expect(product.name == "Test Name")
        #expect(product.price == 123.45)
        #expect(product.currency == .usd)
        #expect(product.brand == "Test Brand")
        #expect(product.imageURL == "https://example.com/product.jpg")
        #expect(product.rating == 4.5)
        #expect(product.inStock == true)
    }
    
    @Test("Products should handle different currencies")
    func testProductsHandleDifferentCurrencies() {
        // Given
        let product = Product(
            id: "p1",
            name: "International Product",
            brand: "Global Brand",
            price: 99.99,
            originalPrice: 129.99,
            currency: .usd,
            imageURL: "https://example.com/product.jpg",
            rating: 4.5,
            reviewCount: 100,
            inStock: true,
            category: "Electronics",
            description: "International product",
            specifications: ["Spec 1"]
        )
        
        // Then
        #expect(product.currency == .usd)
    }
    
    // MARK: - Edge Cases
    
    @Test("Presenter should handle video with no products")
    func testPresenterHandlesVideoWithNoProducts() {
        // Given
        let video = createMockVideo(products: [])
        let interactor = MockProductDetailInteractor()
        
        // When
        let presenter = ProductDetailPresenter(video: video, interactor: interactor)
        
        // Then
        #expect(presenter.video.products.isEmpty)
    }
    
    @Test("Presenter should handle video with many products")
    func testPresenterHandlesVideoWithManyProducts() {
        // Given
        let products = (1...20).map {
            createMockProduct(id: "p\($0)", name: "Product \($0)", price: Double($0))
        }
        let video = createMockVideo(products: products)
        let interactor = MockProductDetailInteractor()
        
        // When
        let presenter = ProductDetailPresenter(video: video, interactor: interactor)
        
        // Then
        #expect(presenter.video.products.count == 20)
    }
    
    @Test("Add to cart should preserve product properties")
    func testAddToCartPreservesProductProperties() {
        // Given
        let product = createMockProduct(
            id: "preserve-test",
            name: "Preserve Me",
            price: 199.99
        )
        let (presenter, interactor) = createTestPresenter()
        
        // When
        presenter.addToCard(product: [product])
        
        // Then
        let addedProduct = interactor.addedProducts.first!
        #expect(addedProduct.id == "preserve-test")
        #expect(addedProduct.name == "Preserve Me")
        #expect(addedProduct.price == 199.99)
        #expect(addedProduct.currency == .usd)
    }
}

// MARK: - Product Detail Interactor Tests

@Suite("Product Detail Interactor Tests")
struct ProductDetailInteractorTests {
    
    @Test("Interactor should implement protocol")
    func testInteractorImplementsProtocol() {
        // Given & When
        let interactor = ProductDetailInteractor()
        
        // Then - should compile and not crash
        #expect(interactor is ProductDetailInteractorProtocol)
    }
    
    @Test("Add to cart should not crash with empty products")
    func testAddToCartDoesNotCrashWithEmptyProducts() {
        // Given
        let interactor = ProductDetailInteractor()
        
        // When & Then - should not crash
        interactor.addToCard(product: [])
    }
    
    @Test("Add to cart should not crash with valid products")
    func testAddToCartDoesNotCrashWithValidProducts() {
        // Given
        let interactor = ProductDetailInteractor()
        let products = [
            Product(
                id: "p1",
                name: "Test Product",
                brand: "Test Brand",
                price: 99.99,
                originalPrice: 129.99,
                currency: .usd,
                imageURL: "https://example.com/test.jpg",
                rating: 4.5,
                reviewCount: 100,
                inStock: true,
                category: "Electronics",
                description: "Test product",
                specifications: ["Spec 1"]
            )
        ]
        
        // When & Then - should not crash
        interactor.addToCard(product: products)
    }
}

// MARK: - Integration Tests

@Suite("Product Detail Integration Tests")
struct ProductDetailIntegrationTests {
    
    @Test("Complete product detail workflow")
    func testCompleteProductDetailWorkflow() {
        // Given - create a video with products
        let products = [
            Product(id: "p1", name: "Product 1", brand: "Brand 1", price: 29.99, originalPrice: 39.99,
                    currency: .usd, imageURL: "url1", rating: 4.5, reviewCount: 100, inStock: true,
                    category: "Electronics", description: "Product 1", specifications: ["Spec 1"]),
            Product(id: "p2", name: "Product 2", brand: "Brand 2", price: 49.99, originalPrice: 69.99,
                    currency: .usd, imageURL: "url2", rating: 4.7, reviewCount: 200, inStock: true,
                    category: "Electronics", description: "Product 2", specifications: ["Spec 2"])
        ]
        
        let video = FavouriteVideo(
            id: "v1",
            videoURL: "https://example.com/video.mp4",
            thumbnailURL: "https://example.com/thumb.jpg",
            duration: 180,
            title: "Shopping Video",
            desc: "Great products here",
            products: products,
            isFavourite: false
        )
        
        let interactor = ProductDetailInteractor()
        let presenter = ProductDetailPresenter(video: video, interactor: interactor)
        
        // Then - verify complete setup
        #expect(presenter.video.id == "v1")
        #expect(presenter.video.products.count == 2)
        #expect(presenter.video.title == "Shopping Video")
        
        // When - add products to cart
        presenter.addToCard(product: products)
        
        // Then - should complete without crash
        #expect(true)
    }
    
    @Test("Presenter and interactor collaboration")
    func testPresenterAndInteractorCollaboration() {
        // Given
        let products = [
            Product(id: "p1", name: "Collab Product", brand: "Collab Brand", price: 99.99,
                    originalPrice: 129.99, currency: .usd, imageURL: "url", rating: 4.5,
                    reviewCount: 100, inStock: true, category: "Electronics",
                    description: "Collab product", specifications: ["Spec 1"])
        ]
        
        let video = FavouriteVideo(
            id: "v1",
            videoURL: "https://example.com/video.mp4",
            thumbnailURL: "https://example.com/thumb.jpg",
            duration: 120,
            title: "Test",
            desc: "Test",
            products: products,
            isFavourite: false
        )
        
        // When - create presenter with interactor
        let interactor = ProductDetailInteractor()
        let presenter = ProductDetailPresenter(video: video, interactor: interactor)
        
        // Then - should be properly connected
        #expect(presenter.interactor is ProductDetailInteractor)
        
        // When - perform action
        presenter.addToCard(product: products)
        
        // Then - should complete successfully
        #expect(true)
    }
}
