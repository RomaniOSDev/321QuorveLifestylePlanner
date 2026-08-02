import SwiftUI

struct EmojiPickerView: View {
    let emojis: [String]
    @Binding var selected: String
    var onSelect: (() -> Void)?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(emojis, id: \.self) { emoji in
                    Button {
                        selected = emoji
                        FeedbackHelper.tap()
                        onSelect?()
                    } label: {
                        Text(emoji)
                            .font(.system(size: 32))
                            .frame(width: 52, height: 52)
                            .background(
                                Circle()
                                    .fill(selected == emoji ? Color("AppPrimary").opacity(0.35) : Color("AppBackground").opacity(0.5))
                            )
                            .overlay(
                                Circle()
                                    .stroke(selected == emoji ? Color("AppAccent") : Color.clear, lineWidth: 2)
                            )
                            .scaleEffect(selected == emoji ? 1.12 : 1.0)
                            .animation(.spring(response: 0.35, dampingFraction: 0.65), value: selected)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("emoji_\(emoji)")
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
        }
    }
}
