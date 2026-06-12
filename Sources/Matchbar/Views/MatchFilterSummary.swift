import SwiftUI

struct MatchFilterSummary: View {
    let text: String
    let clear: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Text(text)
                .font(.system(size: 10.5))
                .foregroundStyle(.secondary)
            Button(action: clear) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            }
            .buttonStyle(.plain)
            Spacer()
        }
    }
}
