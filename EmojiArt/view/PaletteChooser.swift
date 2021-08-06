//
//  PaletteChooser.swift
//  EmojiArt
//
//  Created by Emily Thorne on 8/6/21.
//

import SwiftUI

struct PaletteChooser: View {
    var body: some View {
        ScrollingEmojisView(emojis: testEmojis)
            .font(.system(size: defaultEmojiFontSize))
        
    }
        
    let testEmojis = "🥂🧗‍♀️🏄‍♂️🤽‍♀️⚾️🥌🏉🏈🏀"
}

struct ScrollingEmojisView: View {
    let emojis: String
    
    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(emojis.map { String($0) }, id: \.self) { emoji in
                    Text(emoji)
                        .onDrag { NSItemProvider(object: emoji as NSString) }
                }
            }
        }
    }
}

struct PaletteChooser_Previews: PreviewProvider {
    static var previews: some View {
        PaletteChooser()
    }
}
