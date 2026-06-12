import SwiftUI

struct FormDots: View {
    let form: [FormResult]

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<5, id: \.self) { index in
                Circle()
                    .fill(color(at: index))
                    .overlay(
                        Circle().strokeBorder(.secondary.opacity(index < form.count ? 0 : 0.4), lineWidth: 1)
                    )
                    .frame(width: 7, height: 7)
            }
        }
    }

    private func color(at index: Int) -> Color {
        guard index < form.count else { return .clear }
        switch form[index] {
        case .win: return .green
        case .draw: return .gray
        case .loss: return .red
        }
    }
}
