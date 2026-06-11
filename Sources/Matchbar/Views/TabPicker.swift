import SwiftUI

struct TabPicker: View {
    @Binding var selection: DashboardTab

    var body: some View {
        HStack(spacing: 2) {
            segment("Matches", .matches)
            segment("Groups", .groups)
        }
        .padding(2)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 7))
        .animation(.easeOut(duration: 0.12), value: selection)
    }

    private func segment(_ title: String, _ tab: DashboardTab) -> some View {
        Button {
            selection = tab
        } label: {
            Text(title)
                .font(.system(size: 11, weight: selection == tab ? .semibold : .regular))
                .foregroundStyle(selection == tab ? .white : .primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
                .background(
                    selection == tab ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(.clear),
                    in: RoundedRectangle(cornerRadius: 5)
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
