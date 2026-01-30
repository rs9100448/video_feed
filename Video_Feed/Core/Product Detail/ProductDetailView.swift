//
//  ProductDetailView.swift
//  Video_Feed
//
//  Created by Ravindra Kumar Sonkar on 29/01/26.
//

import SwiftUI
import Kingfisher

// MARK: - Main Product Details View
protocol ProductDetailViewProtocol: AnyObject {
    // Add future methods here
}
struct ProductDetailsView: View {
    
    private let videoData: FavouriteVideo
    let presenter: ProductDetailPresenterProtocol
    
    init(presenter: ProductDetailPresenterProtocol) {
        self.presenter = presenter
        videoData = presenter.video
    }
    
    @State private var selectedProductIndex: Int = 0
    @State private var quantity: Int = 1
    @State private var isFavorite: Bool = false
    
    var selectedProduct: Product {
        videoData.products[selectedProductIndex]
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                VideoHeaderView(videoData: videoData)
                
                if videoData.products.count > 1 {
                    ProductSelectorView(
                        products: videoData.products,
                        selectedIndex: $selectedProductIndex
                    )
                }
                
                VStack(alignment: .leading, spacing: 20) {
                    ProductImageView(imageUrl: selectedProduct.imageURL)
                    ProductInfoSection(
                        product: selectedProduct,
                        quantity: $quantity,
                        isFavorite: $isFavorite
                    )
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemBackground))
    }
}

// MARK: - Video Header Subview

struct VideoHeaderView: View {
    let videoData: FavouriteVideo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(videoData.title)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(videoData.desc)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
    }
}

// MARK: - Product Selector Subview

struct ProductSelectorView: View {
    let products: [Product]
    @Binding var selectedIndex: Int
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Array(products.enumerated()), id: \.element.id) { index, product in
                    ProductTabButton(
                        product: product,
                        isSelected: selectedIndex == index
                    ) {
                        withAnimation {
                            selectedIndex = index
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
    }
}

// MARK: - Product Tab Button Subview

struct ProductTabButton: View {
    let product: Product
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                AsyncImage(url: URL(string: product.imageURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color(.systemGray5)
                }
                .frame(width: 40, height: 40)
                .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(product.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                    
                    Text("$\(String(format: "%.2f", product.price))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color(.systemBackground))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(10)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
    }
}

// MARK: - Product Image Subview

struct ProductImageView: View {
    let imageUrl: String
    
    var body: some View {
        KFImage(URL(string: imageUrl))
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(height: 300)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

// MARK: - Product Info Section Subview

struct ProductInfoSection: View {
    let product: Product
    @Binding var quantity: Int
    @Binding var isFavorite: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            BrandCategoryHeader(brand: product.brand, category: product.category)
            
            ProductNameView(name: product.name)
            
            RatingView(rating: product.rating, reviewCount: product.reviewCount)
            
            StockStatusView(inStock: product.inStock)
            
            Divider()
                .padding(.vertical, 8)
            
            PriceView(price: product.price, currency: .usd)
            
            DescriptionView(description: product.description)
            
            SpecificationsView(specifications: product.specifications)
            
            Divider()
                .padding(.vertical, 8)
            
            QuantitySelector(quantity: $quantity)
            
            ActionButtons(inStock: product.inStock)
        }
    }
}

// MARK: - Brand and Category Header Subview

struct BrandCategoryHeader: View {
    let brand: String
    let category: String
    
    var body: some View {
        HStack {
            Text(brand)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
            
            Spacer()
            
            Text(category)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .cornerRadius(12)
        }
    }
}

// MARK: - Product Name Subview

struct ProductNameView: View {
    let name: String
    
    var body: some View {
        Text(name)
            .font(.title2)
            .fontWeight(.bold)
    }
}

// MARK: - Rating Subview

struct RatingView: View {
    let rating: Double
    let reviewCount: Int
    
    var body: some View {
        HStack(spacing: 8) {
            HStack(spacing: 2) {
                ForEach(0..<5) { index in
                    Image(systemName: starType(for: index))
                        .foregroundColor(.yellow)
                        .font(.system(size: 16))
                }
            }
            
            Text(String(format: "%.1f", rating))
                .font(.subheadline)
                .fontWeight(.semibold)
            
            Text("(\(reviewCount) reviews)")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    private func starType(for index: Int) -> String {
        if Double(index) < floor(rating) {
            return "star.fill"
        } else if Double(index) < rating {
            return "star.leadinghalf.filled"
        } else {
            return "star"
        }
    }
}

// MARK: - Stock Status Subview

struct StockStatusView: View {
    let inStock: Bool
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: inStock ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .foregroundColor(inStock ? .green : .red)
            
            Text(inStock ? "In Stock" : "Out of Stock")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(inStock ? .green : .red)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(inStock ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Price Subview

struct PriceView: View {
    let price: Double
    let currency: Currency
    
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("$\(String(format: "%.2f", price))")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.primary)

            
            Text(currency.rawValue)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}

// MARK: - Description Subview

struct DescriptionView: View {
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Description")
                .font(.headline)
            
            Text(description)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding(.top, 8)
    }
}

// MARK: - Specifications Subview

struct SpecificationsView: View {
    let specifications: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Key Features")
                .font(.headline)
            
            ForEach(specifications, id: \.self) { spec in
                SpecificationRow(specification: spec)
            }
        }
        .padding(.top, 8)
    }
}

// MARK: - Specification Row Subview

struct SpecificationRow: View {
    let specification: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.system(size: 14))
                .padding(.top, 2)
            
            Text(specification)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Quantity Selector Subview

struct QuantitySelector: View {
    @Binding var quantity: Int
    
    var body: some View {
        HStack {
            Text("Quantity")
                .font(.headline)
            
            Spacer()
            
            HStack(spacing: 0) {
                Button(action: {
                    if quantity > 1 {
                        quantity -= 1
                    }
                }) {
                    Image(systemName: "minus")
                        .frame(width: 44, height: 44)
                        .background(Color(.systemGray6))
                }
                
                Text("\(quantity)")
                    .font(.headline)
                    .frame(width: 60, height: 44)
                    .background(Color(.systemGray5))
                
                Button(action: {
                    quantity += 1
                }) {
                    Image(systemName: "plus")
                        .frame(width: 44, height: 44)
                        .background(Color(.systemGray6))
                }
            }
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
        }
    }
}

// MARK: - Action Buttons Subview

struct ActionButtons: View {
    let inStock: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            AddToCartButton(inStock: inStock)
        }
        .padding(.top, 8)
    }
}

// MARK: - Add to Cart Button Subview

struct AddToCartButton: View {
    let inStock: Bool
    
    var body: some View {
        Button(action: {
            // Add to cart action
        }) {
            HStack {
                Image(systemName: "cart.fill")
                Text("Add to Cart")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(!inStock)
        .opacity(inStock ? 1 : 0.5)
    }
}

// MARK: - Favorite Button Subview

struct FavoriteButton: View {
    @Binding var isFavorite: Bool
    
    var body: some View {
        Button(action: {
            isFavorite.toggle()
        }) {
            Image(systemName: isFavorite ? "heart.fill" : "heart")
                .font(.system(size: 20))
                .foregroundColor(isFavorite ? .red : .gray)
                .frame(width: 50, height: 50)
                .background(Color(.systemGray6))
                .cornerRadius(12)
        }
    }
}
