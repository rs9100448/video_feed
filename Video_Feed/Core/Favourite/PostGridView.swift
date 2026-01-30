//
//  PostGridView.swift
//  Video_Feed
//
//  Created by Ravindra Kumar Sonkar on 27/01/26.
//

import SwiftUI
import Kingfisher

struct PostGridView: View {
    let favourites: [FavouriteVideo]
    private let columns = [
        GridItem(.flexible(), spacing: 1),
        GridItem(.flexible(), spacing: 1),
        GridItem(.flexible()),
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 2) {
            ForEach(favourites) { fav in
                GeometryReader { geo in
                    let width = geo.size.width
                    let height = width * 16/9
                    
                    ZStack(alignment: .bottom) {
                        KFImage(URL(string: fav.thumbnailURL))
                            .resizable()
                            .aspectRatio(9/16, contentMode: .fill)
                            .frame(width: width, height: height)
                            .clipped()
                       
                        HStack {
                            Text(fav.title)
                                .font(.caption)
                                .multilineTextAlignment(.leading)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .lineLimit(2)
                                .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                                .padding(.horizontal, 6)
                                .padding(.bottom, 6)
                            Spacer()
                        }
                    }
                }
                .aspectRatio(9/16, contentMode: .fit)
            }
        }
    }
}














