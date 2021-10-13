//
//  EmojiArtDocument.swift
//  EmojiArt
//
//  Created by Emily Thorne on 7/22/21.
//

import SwiftUI
import Combine

class EmojiArtDocument: ObservableObject {
    @Published private(set) var emojiArt: EmojiArtModel {
        didSet {
            scheduleAutoSave()
            if emojiArt.background != oldValue.background {
                fetchBackgroundImageDataIfNecessary()
            }
        }
    }
    
    private var autoSaveTimer: Timer?
    
    private func scheduleAutoSave() {
        autoSaveTimer?.invalidate()
        autoSaveTimer = Timer.scheduledTimer(withTimeInterval: Autosave.coalescingInterval, repeats: false) { _ in
            self.autoSave()
        }
    }
    
    private struct Autosave {
        static let filename = "Autosaved.emojiart"
        static var url: URL? {
            let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            return documentDirectory?.appendingPathComponent(filename)
        }
        static let coalescingInterval = 5.0
    }
    
    private func autoSave() {
        if let url = Autosave.url {
            save(to: url)
        }
    }
    
    private func save(to url: URL) {
        let thisFunction = "\(String(describing: self)).\(#function)"
        do {
            let data: Data = try emojiArt.json()
            print("\(thisFunction) json = \(String(data: data, encoding: .utf8) ?? "nil")")
            try data.write(to: url)
            print("\(thisFunction) success!")
        } catch let encodingError where encodingError is EncodingError {
            print("\(thisFunction) couldn't encode EmojiArt as JSON because \(encodingError.localizedDescription)")
        }
        catch {
            print("\(thisFunction) error = \(error)")
        }
    }
    
    init() {
        if let url = Autosave.url, let autosavedEmojiArt = try? EmojiArtModel(url: url) {
            emojiArt = autosavedEmojiArt
            fetchBackgroundImageDataIfNecessary()
        } else {
            emojiArt = EmojiArtModel()
        }
        emojiArt = EmojiArtModel()
        //        emojiArt.addEmoji("🏉", at: (-200, -100), size: 80)
        //        emojiArt.addEmoji("🥎", at: (100, -50), size: 25)
    }
    
    var emojis: [EmojiArtModel.Emoji] { emojiArt.emojis }
    var background: EmojiArtModel.Background { emojiArt.background }
    
    @Published var backgroundImage: UIImage?
    @Published var backgroundImageFetchStatus = BackgroundImageFetchStatus.idle
    
    enum BackgroundImageFetchStatus: Equatable {
        case idle
        case fetching
        case failed(URL)
    }
    
    private var backgroundImageFetchCancellable: AnyCancellable? // Need to import Combine to use AnyCancellable
    
    private func fetchBackgroundImageDataIfNecessary() {
        backgroundImage = nil
        switch emojiArt.background {
        case .url(let url):
            // fetch the url
            backgroundImageFetchStatus = .fetching
            // DispatchQueue.global commented code is a substitute for the same action as the below code
            backgroundImageFetchCancellable?.cancel()
            let session = URLSession.shared
            let publisher = session.dataTaskPublisher(for: url)
                .map { (data, urlResponse) in UIImage(data: data) }
                .replaceError(with: nil)
                .receive(on: DispatchQueue.main)
            backgroundImageFetchCancellable = publisher
                .sink { [weak self] image in
                    self?.backgroundImage = image
                    self?.backgroundImageFetchStatus = (image != nil) ? .idle : .failed(url)
                }
            
            // Example of code that would be useful if the Failure was not Never
            //                .sink(
            //                    receiveCompletion: { result in
            //                        switch result {
            //                        case .finished:
            //                            print("success!")
            //                        case .failure(let error):
            //                            print("failed: error = \(error)")
            //                        }
            //                    },
            //
            //                    receiveValue: { [weak self] image in
            //                        self?.backgroundImage = image
            //                        self?.backgroundImageFetchStatus = (image != nil) ? .idle : .failed(url)
            //                    }
            //                )
            
            //            DispatchQueue.global(qos: .userInitiated).async {
            //                let imageData = try? Data(contentsOf: url)
            //                DispatchQueue.main.async { [ weak self ] in
            //                    // Ensure the URL background chosen is the same as the URL background displaying
            //                    // UX should not have a slow background from a slow server pop up after waiting 5 minutes and
            //                    // selecting something else instead - that "something else" should take priority
            //                    if self?.emojiArt.background == EmojiArtModel.Background.url(url) {
            //                        self?.backgroundImageFetchStatus = .idle
            //                        if imageData != nil {
            //                            self?.backgroundImage = UIImage(data: imageData!)
            //                        }
            //                        if self?.backgroundImage == nil {
            //                            self?.backgroundImageFetchStatus = .failed(url)
            //                        }
            //                    }
            //                }
            //            }
        case .imageData(let data):
            backgroundImage = UIImage(data: data)
        case .blank:
            break
        }
    }
    
    // MARK: - Intent(s)
    
    func setBackground(_ background: EmojiArtModel.Background) {
        emojiArt.background = background
        print("background set to \(background)")
    }
    
    func addEmoji(_ emoji: String, at location: (x: Int, y: Int), size: CGFloat) {
        emojiArt.addEmoji(emoji, at: location, size: Int(size))
    }
    
    func moveEmoji(_ emoji: EmojiArtModel.Emoji, by offset: CGSize) {
        if let index = emojiArt.emojis.firstIndex(of: emoji) {
            emojiArt.emojis[index].x += Int(offset.width)
            emojiArt.emojis[index].y += Int(offset.height)
        }
    }
    
    func scaleEmoji(_ emoji: EmojiArtModel.Emoji, by scale: CGFloat) {
        if let index = emojiArt.emojis.firstIndex(of: emoji) {
            emojiArt.emojis[index].size = Int((CGFloat(emojiArt.emojis[index].size) * scale)
                                                .rounded(.toNearestOrAwayFromZero))
        }
    }
}
