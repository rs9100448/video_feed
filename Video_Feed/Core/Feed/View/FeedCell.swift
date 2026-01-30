//
//  FeedCell.swift
//  Video_Feed
//
//  Created by Ravindra Kumar Sonkar on 27/01/26.
//

import SwiftUI
import AVKit
import Kingfisher

struct FeedCell: View {
    let video: FavouriteVideo
    var player: AVPlayer
    @State private var showModal = false
    let onFavoriteToggle: (Bool) -> Void
    let navigateToProductDetail: () -> AnyView
    
    init(video: FavouriteVideo, player: AVPlayer, onFavoriteToggle: @escaping (Bool) -> Void, navigateToProductDetail: @escaping () -> AnyView) {
        self.video = video
        self.player = player
        self.onFavoriteToggle = onFavoriteToggle
        self.navigateToProductDetail = navigateToProductDetail
    }
    
    var body: some View {
        ZStack {
            CustomVideoPlayer(player: player)
                .containerRelativeFrame([.horizontal, .vertical])
            VStack {
                Spacer()
                
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading) {
                        Text(video.title)
                            .fontWeight(.semibold)
                        Text(video.desc)
                    }
                    .foregroundStyle(.white)
                    .font(.subheadline)
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                    
                    Spacer()
                    UserActionOptionalView(video: video, player: player, showModal: $showModal, navigateToProductDetail: navigateToProductDetail)
                        .foregroundColor(.white)
                }
                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                .padding(.bottom, 80)
            }
            .padding()
            
        }
        .onTapGesture {
            switch player.timeControlStatus {
            case .paused:
                player.play()
            case .waitingToPlayAtSpecifiedRate:
                player.rate = 1.3
            case .playing:
                player.pause()
            @unknown default:
                break
            }
        }
        .onChange(of: video.isFavourite) { oldValue, newValue in
            onFavoriteToggle(newValue)
        }
    }
}

struct UserActionOptionalView: View {
    let video: FavouriteVideo
    var player: AVPlayer
    @Binding var showModal: Bool
    let navigateToProductDetail: () -> AnyView
    var body: some View {
        VStack(spacing: 40){
            KFImage(URL(string: video.thumbnailURL))
                .resizable()
                .clipShape(Circle())
                .scaledToFit()
                .frame(width: 60, height: 60)
            Button(action: {
                video.isFavourite.toggle()
            }) {
                Image(systemName: video.isFavourite ? "heart.fill" : "heart")
                    .resizable()
                    .frame(width: 28, height: 28)
            }
            
            Button(action: {
                showModal = true
            }) {
                Image(systemName: "info.circle")
                    .resizable()
                    .frame(width: 28, height: 28)
            }
            .fullScreenCover(isPresented: $showModal, content: {
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            showModal = false
                            player.play()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title)
                                .foregroundColor(.gray)
                        }
                        .padding()
                    }
                    navigateToProductDetail()
                        .onAppear() {
                            player.pause()
                        }
                }
            })
            
        }
    }
}
