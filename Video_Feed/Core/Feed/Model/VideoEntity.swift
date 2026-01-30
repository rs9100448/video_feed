
import Foundation

struct VideoEntity: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let videoURL: String
    let thumbnailURL: String
    let duration: Int
    let views: Int
    let likes: Int
    let createdAt: String
    let products: [Product]
    
    enum CodingKeys: String, CodingKey {
        case id, title, description
        case videoURL = "videoUrl"
        case thumbnailURL = "thumbnailUrl"
        case duration, views, likes, createdAt, products
    }
    
}

struct Product: Identifiable, Codable {
    let id, name, brand: String
    let price: Double
    let originalPrice: Double?
    let currency: Currency
    let imageURL: String
    let rating: Double
    let reviewCount: Int
    let inStock: Bool
    let category, description: String
    let specifications: [String]
    
    enum CodingKeys: String, CodingKey {
        case id, name, brand, price, originalPrice, currency
        case imageURL = "imageUrl"
        case rating, reviewCount, inStock, category, description, specifications
    }
    
    var formattedPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = Currency.usd.rawValue
        return formatter.string(from: (price as Double) as NSNumber) ?? "\(currency) \(price)"
    }
}

enum Currency: String, Codable {
    case usd = "USD"
}

struct VideoResponse: Codable {
    let videos: [VideoEntity]
}
