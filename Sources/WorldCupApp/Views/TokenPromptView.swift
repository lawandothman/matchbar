import SwiftUI

struct TokenPromptView: View {
    let store: MatchStore
    @State private var token = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("API token required")
                .font(.headline)
            Text("Get a free token at football-data.org and paste it here.")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack {
                SecureField("Token", text: $token)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(save)
                Button("Save", action: save)
                    .disabled(token.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            Link("football-data.org/client/register", destination: URL(string: "https://www.football-data.org/client/register")!)
                .font(.caption)
        }
        .padding(12)
    }

    private func save() {
        store.saveToken(token)
    }
}
