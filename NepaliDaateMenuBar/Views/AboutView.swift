//
//  AboutView.swift
//  NepaliDaateMenuBar
//
//  About and credits view
//

import SwiftUI

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // App icon and title
                VStack(spacing: 12) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 56))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.accentColor, Color.accentColor.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text("Nepali Date Mac Menu Bar")
                        .font(.title2.weight(.bold))
                    
                    Text("Version 0.0.1")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)
                
                Divider()
                
                // Description
                VStack(alignment: .leading, spacing: 12) {
                    Text("About")
                        .font(.headline)
                    
                    Text("A minimal macOS menu bar application that displays Nepali (Bikram Sambat) dates with integrated calendar event viewing.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Divider()
                
                // Used Open Source Tools
                VStack(alignment: .leading, spacing: 12) {
                    Text("Used Open Source Tools")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Link(destination: URL(string: "https://github.com/SushilShrestha/pyBSDate")!) {
                            HStack {
                                Image(systemName: "link")
                                Text("pyBSDate by Sushil Shrestha")
                            }
                            .font(.caption)
                        }
                        
                        Text("Date conversion algorithm (MIT License)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(12)
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
                    .cornerRadius(8)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Divider()
                
                // License
                VStack(alignment: .leading, spacing: 12) {
                    Text("License")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("GPL v3 - GNU General Public License")
                            .font(.subheadline.weight(.medium))
                        
                        Text("This software is free to use and modify. Commercial distribution requires contribution back to the project.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Link("View Full License", destination: URL(string: "https://www.gnu.org/licenses/gpl-3.0.txt")!)
                            .font(.caption)
                    }
                    .padding(12)
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
                    .cornerRadius(8)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Divider()
                
                // Links
                VStack(alignment: .leading, spacing: 12) {
                    Text("Resources")
                        .font(.headline)
                    
                    VStack(spacing: 6) {
                        Link(destination: URL(string: "https://github.com/yourusername/NepaliDateMacMenuBar")!) {
                            HStack {
                                Image(systemName: "chevron.left.forwardslash.chevron.right")
                                Text("Source Code")
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption2)
                            }
                        }
                        
                        Link(destination: URL(string: "https://github.com/yourusername/NepaliDateMacMenuBar/issues")!) {
                            HStack {
                                Image(systemName: "exclamationmark.bubble")
                                Text("Report an Issue")
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption2)
                            }
                        }
                    }
                    .font(.caption)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
                
                // Copyright
                Text("© 2025 Nepali Date Mac Menu Bar\nAll rights reserved")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 20)
            }
            .padding(.horizontal, 24)
        }
        .frame(width: Constants.Window.aboutWidth, height: Constants.Window.aboutHeight)
    }
}

