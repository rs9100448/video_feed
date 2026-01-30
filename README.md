# Smart Video Commerce Feed - iOS Application

## 📋 Table of Contents
- [Project Overview](#project-overview)
- [High-Level System Design](#high-level-system-design)
- [Architecture Details](#architecture-details)
- [Key Features](#key-features)
- [Technology Stack](#technology-stack)
- [Design Decisions](#design-decisions)
- [Project Structure](#project-structure)
- [Setup & Installation](#setup--installation)
- [Performance Optimizations](#performance-optimizations)
- [Future Enhancements](#future-enhancements)

---

## 🎯 Project Overview

This iOS application implements a high-performance, scalable video commerce feed that seamlessly integrates product discovery within video content. Built using modern Swift concurrency, VIPER architecture, and SwiftUI, the app provides users with a smooth, infinite-scrolling video experience where they can browse products, view details, and manage favorites without leaving the primary viewing context.


---

## 🏗️ High-Level System Design

### System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                        PRESENTATION LAYER (SwiftUI)                  │
├─────────────────────────────────────────────────────────────────────┤
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐             │
│  │  Feed View   │  │ Product View │  │Favourite View│             │
│  │  (Infinite   │  │   (Modal)    │  │   (Grid)     │             │
│  │   Scroll)    │  │              │  │              │             │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘             │
│         │                 │                  │                      │
│         ▼                 ▼                  ▼                      │
├─────────────────────────────────────────────────────────────────────┤
│                     VIPER ARCHITECTURE LAYER                         │
├─────────────────────────────────────────────────────────────────────┤
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │  VIEW → PRESENTER → INTERACTOR → ENTITY                      │  │
│  │    ↑        ↓           ↓                                     │  │
│  │  ROUTER ←──────────────────                                  │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                     │
│  Module Separation:                                                │
│  • FeedModule (Video Feed)                                         │
│  • ProductDetailModule (Product Details)                           │
│  • FavouriteModule (Saved Items)                                   │
└─────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────┐
│                         BUSINESS LOGIC LAYER                         │
├─────────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐   │
│  │ Data Repository │  │  Video Cache    │  │ Prefetch Engine │   │
│  │   (LocalJSON)   │  │   (Actor)       │  │  (async/await)  │   │
│  └────────┬────────┘  └────────┬────────┘  └────────┬────────┘   │
│           │                    │                     │             │
│           └────────────────────┴─────────────────────┘             │
│                                │                                    │
│                                ▼                                    │
├─────────────────────────────────────────────────────────────────────┤
│                         PERSISTENCE LAYER                            │
├─────────────────────────────────────────────────────────────────────┤
│  ┌──────────────────┐                    ┌──────────────────┐     │
│  │   SwiftData      │                    │   File Cache     │     │
│  │  (Favourites &   │                    │  (Video Files)   │     │
│  │    History)      │                    │  500MB LRU Cache │     │
│  └──────────────────┘                    └──────────────────┘     │
└─────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────┐
│                          MEDIA LAYER                                 │
├─────────────────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │  AVPlayer (Video Playback)                                  │   │
│  │  • State Management (Play/Pause/Seek)                       │   │
│  │  • Lifecycle Management (Memory Safety)                     │   │
│  │  • Automatic Cleanup on View Transitions                    │   │
│  └─────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────┘
```

### Data Flow Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                          USER INTERACTION                            │
└────────────────────────────┬────────────────────────────────────────┘
                             │
                             ▼
                        [View Layer]
                             │
                             ▼
                      [Presenter Layer]
                    • Formats data for UI
                    • Handles user actions
                    • Manages state updates
                             │
                             ▼
                     [Interactor Layer]
                  • Business logic execution
                  • Data transformation
                  • Async operations (async/await)
                             │
                ┌────────────┴────────────┐
                ▼                         ▼
        [Repository Layer]        [Cache Layer (Actor)]
        • Fetches JSON data       • Video file caching
        • Pagination logic        • LRU eviction policy
        • Data mapping            • Metadata tracking
                │                         │
                └────────────┬────────────┘
                             ▼
                    [Persistence Layer]
                • SwiftData (Favourites)
                • File System (Videos)
                             │
                             ▼
                    [Model/Entity Layer]
                • FavouriteVideo
                • VideoEntity
                • Product
```

---

## 🏛️ Architecture Details

### VIPER Architecture Implementation

The application strictly follows the VIPER (View, Interactor, Presenter, Entity, Router) architecture pattern to ensure separation of concerns and maintainability.

#### Components Breakdown

**1. View (SwiftUI)**
- Responsible only for displaying data and capturing user interactions
- No business logic
- Observes Presenter state changes
- Examples: `FeedView`, `ProductDetailView`, `FavouriteView`

**2. Interactor**
- Contains all business logic
- Manages data operations (fetch, transform, cache)
- Interacts with Repository and Persistence layers
- Uses async/await for all async operations
- Examples: `FeedInteractor`, `ProductDetailInteractor`

**3. Presenter**
- Acts as intermediary between View and Interactor
- Formats data for display
- Manages presentation state
- Handles user actions from View
- Updates View through `@Published` properties
- Examples: `FeedPresenter`, `ProductDetailPresenter`

**4. Entity**
- Data models
- SwiftData models for persistence
- Codable models for JSON parsing
- Examples: `FavouriteVideo`, `VideoEntity`, `Product`

**5. Router**
- Handles navigation logic
- Creates and presents new modules
- Dependency injection
- Examples: `FeedRouter`, `ProductDetailRouter`

### Module Structure

```
Video_Feed/
├── Core/
│   ├── Feed/                        # Feed Module (VIPER)
│   │   ├── FeedView.swift           # View
│   │   ├── FeedPresenter.swift      # Presenter
│   │   ├── FeedInteractor.swift     # Interactor
│   │   ├── FeedRouter.swift         # Router
│   │   ├── FeedProtocols.swift      # Protocols
│   │   ├── FeedViewModel.swift      # View Model
│   │   └── Model/
│   │       ├── VideoEntity.swift    # Entity
│   │       └── FavouriteVideo.swift # SwiftData Model
│   │
│   ├── ProductDetail/               # Product Detail Module (VIPER)
│   │   ├── ProductDetailView.swift
│   │   ├── ProductDetailPresenter.swift
│   │   ├── ProductDetailInteractor.swift
│   │   ├── ProductDetailRouter.swift
│   │   └── ProductDetailProtocol.swift
│   │
│   └── Favourite/                   # Favourite Module (VIPER)
│       ├── FavouriteView.swift
│       ├── FavouritePresenter.swift
│       ├── FavouriteInteractor.swift
│       └── FavouriteRouter.swift
│
├── Services/                        # Service Layer
│   └── DataLayerRepo.swift         # Repository Pattern
│
├── Utils/                           # Utilities
│   ├── LocalJsonData.swift         # JSON Data Source
│   └── VideoCache.swift            # Video Caching (Actor)
│
├── Extensions/                      # Extensions
│   └── CustomVideoPlayer.swift     # AVPlayer Wrapper
│
└── Model/                          # Shared Models
```

---

## ✨ Key Features

### 1. Infinite Scrolling Video Feed
- **Smooth Scrolling**: Optimized scroll performance using lazy loading
- **Sequential Loading**: Videos load automatically as user scrolls
- **State Preservation**: Maintains playback state during transitions
- **Memory Efficient**: Automatic cleanup of off-screen video players

### 2. Intelligent Video Prefetching
- **Predictive Loading**: Prefetches next 3 videos based on scroll position
- **Background Processing**: Uses `Task.detached` for non-blocking prefetch
- **Cache-Aware**: Checks cache before downloading
- **Configurable**: Adjustable prefetch distance and limits

### 3. Product Details
- **Interactive Overlays**: Tappable product areas synchronized with video
- **Modal Presentation**: Product details shown without leaving video context
- **Rich Information**: Displays product specs, price, ratings, and reviews
- **Purchase CTA**: Clear call-to-action for product purchase

### 4. Favorites Management
- **Persistent Storage**: Uses SwiftData for local persistence
- **Quick Toggle**: One-tap favorite/unfavorite
- **Grid View**: Dedicated view for browsing saved items
- **Synchronization**: Real-time sync between feed and favorites

### 5. Advanced Video Caching
- **Actor-Based**: Thread-safe video cache using Swift Actor
- **LRU Eviction**: Least Recently Used cache eviction policy
- **Size Management**: Configurable max cache size (500MB default)
- **Metadata Tracking**: Tracks access patterns and file sizes
- **Automatic Cleanup**: Periodic cleanup of old/unused cache entries
- **Cache Statistics**: Real-time cache usage monitoring

### 6. Viewing History
- **Automatic Tracking**: Records all viewed videos
- **Quick Access**: Easy recall of recently watched content
- **SwiftData Integration**: Persistent history across app launches

---

## 🛠️ Technology Stack

### Core Technologies

| Technology | Purpose | Justification |
|-----------|---------|---------------|
| **SwiftUI** | UI Framework | Modern, declarative UI with excellent performance |
| **Swift Concurrency** | Async Operations | Type-safe concurrency with async/await |
| **SwiftData** | Persistence | Modern, type-safe persistence layer |
| **AVFoundation** | Video Playback | Industry-standard video playback framework |
| **Combine** | Reactive Programming | State management and data binding |
| **Swift Testing** | Unit Testing | Modern testing framework with better DX |

### Architecture Patterns

- **VIPER**: Strict separation of concerns
- **Repository Pattern**: Abstraction of data sources
- **Actor Pattern**: Thread-safe state management
- **Observer Pattern**: Reactive state updates

---

## 🎯 Design Decisions

### 1. Why VIPER Over MVVM?

**Decision**: Implemented VIPER architecture instead of MVVM

**Rationale**:
- **Scalability**: Better suited for large, complex applications
- **Testability**: Each layer can be tested in isolation
- **Separation of Concerns**: Clear responsibilities for each component
- **Team Collaboration**: Multiple developers can work on different layers
- **Navigation Logic**: Router provides centralized navigation management

**Trade-offs**:
- More boilerplate code
- Steeper learning curve for new team members
- Requires more initial setup

### 2. SwiftData vs CoreData

**Decision**: Chose SwiftData for persistence

**Rationale**:
- **Type Safety**: Compile-time type checking reduces runtime errors
- **Modern API**: Cleaner, more Swift-friendly API
- **SwiftUI Integration**: Seamless integration with SwiftUI views
- **Less Boilerplate**: Reduces code complexity
- **Future-Proof**: Apple's recommended persistence solution

**Trade-offs**:
- iOS 17+ requirement
- Less mature ecosystem
- Fewer advanced features than CoreData

### 3. async/await vs Completion Handlers

**Decision**: Used async/await for all asynchronous operations

**Rationale**:
- **Readability**: Linear code flow is easier to understand
- **Error Handling**: Try-catch is more intuitive than Result types
- **Composability**: Easy to chain async operations
- **Structured Concurrency**: Prevents common async bugs
- **Cancellation**: Built-in cancellation support

**Implementation**:
```swift
func fetchData() async throws {
    let videos = try await repository.fetchVideos(page: currentPage)
    
    // Background prefetch
    Task.detached(priority: .background) {
        await self.repository.prefetchVideos(videos, limit: 3)
    }
    
    let favVideos = try await transformVideoToFavourite(videos: videos)
    self.success(for: favVideos)
}
```

### 4. Actor-Based Video Cache

**Decision**: Implemented video cache as a Swift Actor

**Rationale**:
- **Thread Safety**: Eliminates data races without manual locking
- **Concurrent Access**: Multiple async calls can queue safely
- **Memory Safety**: Prevents concurrent modification issues
- **Performance**: Efficient task scheduling by Swift runtime

**Implementation Highlights**:
```swift
actor VideoCache {
    static let shared = VideoCache()
    
    func cacheURL(for url: URL) -> URL {
        // Thread-safe access to cache directory
    }
    
    func save(data: Data, for url: URL) async throws {
        // LRU eviction if needed
        if currentSize + data.count > maxCacheSize {
            try await evictLRUCache(toFreeBytes: data.count)
        }
        // Save and update metadata
    }
}
```

### 5. Prefetching Strategy

**Decision**: Prefetch 3 videos ahead on background thread

**Rationale**:
- **User Experience**: Eliminates loading delays during scroll
- **Network Efficiency**: Batches network requests
- **Resource Management**: Background priority doesn't block UI
- **Adaptive**: Checks cache before downloading

**Algorithm**:
```swift
func prefetchUpcomingVideos(currentIndex: Int, videos: [FavouriteVideo]) async {
    let videosToPreload = 3
    let startIndex = currentIndex + 1
    let endIndex = min(startIndex + videosToPreload, videos.count)
    
    Task.detached(priority: .background) {
        for index in startIndex..<endIndex {
            // Check cache, then download if needed
        }
    }
}
```

### 6. AVPlayer Lifecycle Management

**Decision**: Automatic cleanup and state management

**Rationale**:
- **Memory Leaks Prevention**: Proper cleanup on view disappear
- **State Consistency**: Centralized state management
- **Resource Efficiency**: Releases players not in use

**Implementation**:
```swift
class CustomVideoPlayer: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        // Setup player
        return controller
    }
    
    func dismantleUIViewController(_ uiViewController: AVPlayerViewController, coordinator: Coordinator) {
        // Cleanup: pause, remove observers, release player
        uiViewController.player?.pause()
        uiViewController.player = nil
    }
}
```

### 7. JSON Data Source Over Network API

**Decision**: Used local JSON file for data source

**Rationale**:
- **Offline Support**: App works without network connection
- **Consistent Testing**: Reproducible test scenarios
- **Development Speed**: No backend dependency
- **Easy Pagination**: Simple slice-based pagination
- **Demo Purpose**: Focuses on architecture rather than networking

**Note**: Production app would replace with proper REST API client.

---

## 📁 Project Structure

```
Video_Feed/
│
├── App/
│   └── Video_FeedApp.swift              # App entry point
│
├── Core/                                 # VIPER Modules
│   ├── Feed/                            # Video Feed Module
│   │   ├── View/
│   │   │   ├── FeedView.swift
│   │   │   └── FeedCell.swift
│   │   ├── FeedPresenter.swift
│   │   ├── FeedInteractor.swift
│   │   ├── FeedRouter.swift
│   │   ├── FeedViewModel.swift
│   │   ├── FeedProtocols.swift
│   │   └── Model/
│   │       ├── VideoEntity.swift
│   │       └── FavouriteVideo.swift
│   │
│   ├── ProductDetail/                    # Product Detail Module
│   │   ├── ProductDetailView.swift
│   │   ├── ProductDetailPresenter.swift
│   │   ├── ProductDetailInteractor.swift
│   │   ├── ProductDetailRouter.swift
│   │   └── ProductDetailProtocol.swift
│   │
│   └── Favourite/                        # Favourite Module
│       ├── FavouriteView.swift
│       ├── FavouritePresenter.swift
│       ├── FavouriteInteractor.swift
│       ├── FavouriteRouter.swift
│       └── PostGridView.swift
│
├── Services/                             # Business Services
│   └── DataLayerRepo.swift             # Repository Pattern
│
├── Utils/                                # Utilities
│   ├── LocalJsonData.swift              # JSON Data Handler
│   └── VideoCache.swift                 # Video Caching System
│
├── Extensions/                           # Extensions
│   └── CustomVideoPlayer.swift          # AVPlayer Wrapper
│
├── Model/                                # Shared Models
│   └── Product.swift
│
├── Root/                                 # Root Views
│   └── MainTabView.swift
│
└── Resource/                             # Resources
    └── videos_feed.json                 # Mock Data

Video_FeedTests/                          # Unit Tests
├── FeedInteractorTests.swift
├── FeedPresenterTests.swift
├── ProductDetailTests.swift
├── LocalJsonDataTests.swift
├── VideoCacheTests.swift
└── Mocks/                                # Test Mocks
    ├── MockFeedInteractor.swift
    ├── MockRepository.swift
    ├── MockVideoCache.swift
    ├── TestHelpers.swift
    └── TestableLocalJsonData.swift
```

---

## 🚀 Setup & Installation

### Prerequisites

- **Xcode**: 15.0 or later
- **iOS Deployment Target**: 17.0+
- **Swift**: 5.9+
- **macOS**: 13.0+ (for development)

### Installation Steps

1. **Clone the Repository**
```bash
git clone [repository-url]
cd Video_Feed
```

2. **Open Project in Xcode**
```bash
open Video_Feed.xcodeproj
```

3. **Select Target Device/Simulator**
- Open Xcode
- Select target device from dropdown (iPhone 15 Pro recommended)
- Minimum: iOS 17.0

4. **Build and Run**
```bash
# Command line
xcodebuild -scheme Video_Feed -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build

# Or use Xcode UI
# Press Cmd + R to build and run
```

### Dependencies

**No External Dependencies Required**
- All frameworks are part of iOS SDK
- No CocoaPods, SPM, or Carthage needed
- Self-contained project

### Configuration

**Cache Settings** (Optional - modify in `VideoCache.swift`)
```swift
struct CacheConfig: Sendable {
    var maxCacheSize: Int64 = 500_000_000      // 500 MB
    var maxCacheAge: TimeInterval = 7 * 24 * 60 * 60  // 7 days
    var cleanupInterval: TimeInterval = 24 * 60 * 60   // 1 day
    var enableAutomaticCleanup: Bool = true
}
```

**Data Source** (Modify in `LocalJsonData.swift` if needed)
```swift
// Update JSON file path or add network API
let videosURL = Bundle.main.url(forResource: "videos_feed", withExtension: "json")
```

## ⚡ Performance Optimizations

### 1. Video Prefetching
**Optimization**: Intelligent background prefetching
- **Strategy**: Prefetch 3 videos ahead of current position
- **Priority**: Background task priority to not block UI
- **Cache Check**: Skip already cached videos
- **Impact**: Near-zero latency when scrolling

### 2. LRU Cache Eviction
**Optimization**: Efficient memory management
- **Strategy**: Least Recently Used eviction policy
- **Metadata**: Track access patterns and timestamps
- **Automatic Cleanup**: Periodic cleanup of old entries
- **Impact**: Maintains performance under memory pressure

### 3. Actor-Based Concurrency
**Optimization**: Thread-safe operations without locks
- **Strategy**: Swift Actor for cache management
- **Benefit**: Eliminates data races
- **Performance**: Efficient task scheduling by runtime
- **Impact**: Safe concurrent access with good performance

### 4. Lazy Loading
**Optimization**: Load content as needed
- **Strategy**: Infinite scroll with pagination
- **Batch Size**: 10 videos per page
- **Trigger**: Load more at 3 items from bottom
- **Impact**: Fast initial load, smooth scrolling

### 5. AVPlayer Lifecycle
**Optimization**: Proper resource management
- **Strategy**: Create/destroy players as needed
- **Cleanup**: Automatic cleanup on view disappear
- **Memory**: Release players not in view
- **Impact**: Prevents memory leaks and crashes

### 6. SwiftUI Optimizations
**Optimization**: View rendering efficiency
- **Strategy**: `@Published` for reactive updates
- **Lazy Stacks**: Use LazyVStack for large lists
- **Id Stability**: Stable identifiers for list items
- **Impact**: Smooth 60fps scrolling

---

## 🔮 Future Enhancements

### Phase 1: Enhanced Features
1. **Push Notifications**
   - New product notifications
   - Favorites price drop alerts
   - New video notifications

2. **Analytics Integration**
   - Video view tracking
   - Product interaction metrics
   - User engagement analytics

3. **Search & Filters**
   - Search videos by title/description
   - Filter by category, price range
   - Sort options (newest, popular, etc.)

4. **User Authentication**
   - Login/Registration
   - Cloud sync of favorites
   - Cross-device sync

### Phase 2: Advanced Capabilities
5. **Social Features**
   - Share videos
   - Comment on videos
   - Like/Unlike functionality
   - User profiles

6. **Enhanced Video Player**
   - Picture-in-Picture support
   - Playback speed control
   - Quality selection
   - Subtitle support

7. **AR Product Preview**
   - AR view for products
   - Virtual try-on
   - 3D product visualization

8. **Advanced Caching**
   - Smart prefetch based on ML
   - Adaptive bitrate streaming
   - Progressive download

### Phase 3: Scalability
9. **Backend Integration**
   - REST API integration
   - GraphQL support
   - Real-time updates with WebSocket

10. **Performance Monitoring**
    - Crash reporting (Firebase Crashlytics)
    - Performance monitoring
    - A/B testing framework

11. **Accessibility**
    - VoiceOver optimization
    - Dynamic Type support
    - High contrast mode

12. **Internationalization**
    - Multi-language support
    - Localized content
    - RTL language support

---

## 📊 System Design Considerations

### Scalability

**Current Implementation**:
- Local JSON data source (up to 1000s of videos)
- File-based video cache (500MB limit)
- SwiftData for favorites (thousands of entries)

**Production Scaling**:
```
┌─────────────────────────────────────────────┐
│           CDN (Video Delivery)              │
│     • CloudFront / Fastly / Akamai          │
│     • Edge caching for low latency          │
└──────────────────┬──────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────┐
│         REST API / GraphQL Server           │
│     • Pagination (cursor-based)             │
│     • Rate limiting                         │
│     • Caching layer (Redis)                 │
└──────────────────┬──────────────────────────┘
                   │
        ┌──────────┴──────────┐
        ▼                     ▼
┌─────────────┐      ┌─────────────┐
│  Database   │      │ File Storage│
│  (Videos    │      │  (S3/GCS)   │
│  Metadata)  │      │             │
└─────────────┘      └─────────────┘
```

### High Availability Considerations

**Data Redundancy**:
- Multiple CDN edge locations
- Database replication
- S3 cross-region replication

**Failover Strategy**:
- Graceful degradation (show cached content)
- Retry logic with exponential backoff
- Circuit breaker pattern for API calls

### Security Considerations

**Current**: 
- Local data only (no network security needed)

**Production Requirements**:
- HTTPS for all API calls
- Certificate pinning
- API key encryption in Keychain
- OAuth 2.0 for authentication
- DRM for video content protection
