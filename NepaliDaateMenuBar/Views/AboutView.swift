//
//  AboutView.swift
//  NepaliDaateMenuBar
//

import SwiftUI

struct AboutView: View {
    var body: some View {
        VStack(spacing: 0) {
            // Hero
            ZStack {
                LinearGradient(
                    colors: [Color.accentColor.opacity(0.12), Color.accentColor.opacity(0.03)],
                    startPoint: .top,
                    endPoint: .bottom
                )

                VStack(spacing: 12) {
                    Image(nsImage: NSApplication.shared.applicationIconImage)
                        .resizable()
                        .frame(width: 80, height: 80)
                        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)

                    VStack(spacing: 4) {
                        Text("Yorion - BS Calendar")
                            .font(.system(size: 22, weight: .bold))

                        Text("Bikram Sambat")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)

                        Text("Version \(Bundle.main.appVersion) (\(Bundle.main.buildNumber))")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary.opacity(0.7))
                            .padding(.top, 2)
                    }
                }
                .padding(.vertical, 32)
            }

            Divider()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // About
                    AboutSection(icon: "info.circle", title: "About") {
                        Text("A minimal macOS menu bar app that displays Nepali (Bikram Sambat) dates with integrated calendar event viewing.")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineSpacing(3)
                    }

                    AboutDivider()

                    // License
                    AboutSection(icon: "doc.text", title: "License") {
                        AboutLinkRow(
                            icon: "checkmark.seal",
                            title: "GPL v3 — GNU General Public License",
                            subtitle: "Free to use, modify, and distribute",
                            url: URL(string: "https://www.gnu.org/licenses/gpl-3.0.txt")!
                        )
                    }

                    AboutDivider()

                    // Resources
                    AboutSection(icon: "link", title: "Resources") {
                        VStack(spacing: 6) {
                            AboutLinkRow(
                                icon: "chevron.left.forwardslash.chevron.right",
                                title: "Source Code",
                                subtitle: "github.com/stha-ums/NepaliCalendarMenuBar",
                                url: URL(string: "https://github.com/stha-ums/NepaliCalendarMenuBar")!
                            )
                            AboutLinkRow(
                                icon: "exclamationmark.bubble",
                                title: "Report an Issue",
                                subtitle: "Open a GitHub issue",
                                url: URL(string: "https://github.com/stha-ums/NepaliCalendarMenuBar/issues")!
                            )
                        }
                    }

                    AboutDivider()

                    // Copyright
                    Text("© 2026 Yorion · All rights reserved")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary.opacity(0.6))
                        .padding(.vertical, 16)
                }
            }
        }
        .frame(width: Constants.Window.aboutWidth, height: Constants.Window.aboutHeight)
    }
}

// MARK: - About Section

private struct AboutSection<Content: View>: View {
    let icon: String
    let title: String
    let content: Content

    init(icon: String, title: String, @ViewBuilder content: () -> Content) {
        self.icon = icon
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 7) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.accentColor)
                    .frame(width: 16)
                Text(title.uppercased())
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.secondary)
                    .tracking(0.5)
            }
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }
}

// MARK: - About Divider

private struct AboutDivider: View {
    var body: some View {
        Divider().padding(.horizontal, 24)
    }
}

// MARK: - About Link Row

private struct AboutLinkRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let url: URL
    @State private var isHovered = false

    var body: some View {
        Link(destination: url) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(Color.accentColor.opacity(0.1))
                        .frame(width: 30, height: 30)
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.accentColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary.opacity(0.5))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isHovered ? Color(NSColor.controlBackgroundColor) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(isHovered ? Color.primary.opacity(0.08) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isHovered)
    }
}

// MARK: - Bundle Extension

extension Bundle {
    var appVersion: String {
        return infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
    }

    var buildNumber: String {
        return infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
}
