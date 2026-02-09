//
//  HeaderComponents.swift
//  NepaliDaateMenuBar
//

import SwiftUI

struct ViewModeSwitcher: View {
    @Binding var selection: CalendarViewMode
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach([CalendarViewMode.month, CalendarViewMode.agenda], id: \.self) { mode in
                Text(mode == .month ? "Month" : "Agenda")
                    .font(.system(size: 11, weight: selection == mode ? .bold : .medium))
                    .foregroundColor(selection == mode ? .primary : .secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(
                        ZStack {
                            if selection == mode {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(Color(NSColor.controlBackgroundColor))
                                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                            }
                        }
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selection = mode
                        }
                    }
            }
        }
        .padding(2)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.primary.opacity(0.05))
        )
        .frame(width: 140)
    }
}

struct HeaderIconButton: View {
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(Color.primary.opacity(0.05))
                )
        }
        .buttonStyle(.plain)
        .focusable(false)
    }
}

struct TodayButton: View {
    let action: () -> Void
                
    var body: some View {
        Button(action: action) {
            Text("Today")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.accentColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.accentColor.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(Color.accentColor.opacity(0.2), lineWidth: 0.5)
                        )
                )
        }
        .buttonStyle(.plain)
        .focusable(false)
    }
}
