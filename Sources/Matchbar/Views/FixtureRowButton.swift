import SwiftUI

struct FixtureRowButton: View {
    let fixture: Fixture
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            FixtureRow(fixture: fixture)
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
                .contentShape(Rectangle())
                .background(
                    hovering ? AnyShapeStyle(.quaternary.opacity(0.5)) : AnyShapeStyle(.clear),
                    in: RoundedRectangle(cornerRadius: 8)
                )
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .animation(.easeOut(duration: 0.1), value: hovering)
    }
}
