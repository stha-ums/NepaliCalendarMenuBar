//
//  HTMLTextView.swift
//  NepaliDaateMenuBar
//
//  A SwiftUI view that renders HTML content using native AttributedString.
//

import SwiftUI

struct HTMLTextView: View {
    let html: String
    
    @State private var attributedString: AttributedString?
    
    var body: some View {
        Group {
            if let attributedString = attributedString {
                Text(attributedString)
                    .textSelection(.enabled)
            } else {
                Text(html)
                    .onAppear {
                        computeString()
                    }
            }
        }
        .font(.system(size: 13))
    }
    
    private func computeString() {
        // Compute in background to keep UI responsive and avoid presentation lag
        DispatchQueue.global(qos: .userInitiated).async {
            let css = """
            <style>
                body {
                    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
                    font-size: 13px;
                    color: var(--text-color);
                    line-height: 1.4;
                }
                @media (prefers-color-scheme: dark) {
                    :root { --text-color: #dfdfdf; }
                    a { color: #4daafc; }
                }
                @media (prefers-color-scheme: light) {
                    :root { --text-color: #333333; }
                    a { color: #007aff; }
                }
            </style>
            """
            let styledHTML = css + html
            let result = (try? AttributedString(htmlData: Data(styledHTML.utf8))) ?? AttributedString(html)
            
            DispatchQueue.main.async {
                self.attributedString = result
            }
        }
    }
}

extension AttributedString {
    init(htmlData: Data) throws {
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]
        
        // Use main thread for attributed string creation if possible, or handle carefully
        let nsAttributedString = try NSAttributedString(data: htmlData, options: options, documentAttributes: nil)
        self.init(nsAttributedString)
    }
}
