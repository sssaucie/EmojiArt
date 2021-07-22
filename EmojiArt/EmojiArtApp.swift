//
//  EmojiArtApp.swift
//  EmojiArt
//
//  Created by Emily Thorne on 7/22/21.
//

import SwiftUI

@main
struct EmojiArtApp: App {
    let document = EmojiArtDocument()
    var body: some Scene {
        WindowGroup {
            EmojiArtDocumentView(document: document)
        }
    }
}