import SwiftUI

struct DashboardView: View {
    let store: MatchStore
    @State private var tab: DashboardTab = .matches

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()

            Group {
                if !store.hasToken {
                    TokenPromptView(store: store)
                } else {
                    VStack(alignment: .leading, spacing: 0) {
                        tabPicker
                        switch tab {
                        case .matches:
                            if store.sections.isEmpty {
                                emptyState
                            } else {
                                fixtureList
                            }
                        case .groups:
                            StandingsView(standings: store.standings)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, minHeight: 380, alignment: .top)

            Divider()
            footer
        }
        .frame(width: 420)
    }

    private var tabPicker: some View {
        Picker("", selection: $tab) {
            Text("Matches").tag(DashboardTab.matches)
            Text("Groups").tag(DashboardTab.groups)
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .controlSize(.small)
        .padding(.horizontal, 12)
        .padding(.top, 8)
    }

    private var header: some View {
        HStack {
            Text("World Cup 2026")
                .font(.system(size: 14, weight: .bold))
            Spacer()
            Text(Date(), format: .dateTime.weekday(.wide).day().month())
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var fixtureList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(store.sections) { section in
                    Text(section.title)
                        .font(.system(size: 10, weight: .semibold))
                        .textCase(.uppercase)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.top, 10)
                        .padding(.bottom, 2)

                    ForEach(section.fixtures) { fixture in
                        FixtureRow(fixture: fixture)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                    }
                }
            }
            .padding(.bottom, 8)
        }
        .frame(maxHeight: 460)
    }

    private var emptyState: some View {
        Text(store.lastError ?? "No upcoming matches")
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
    }

    private var footer: some View {
        HStack {
            if let error = store.lastError, !store.fixtures.isEmpty {
                Text(error)
                    .font(.caption2)
                    .foregroundStyle(.red)
            } else if let updated = store.lastUpdated {
                Text("Updated \(updated, format: .dateTime.hour().minute())")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("Refresh") {
                Task { await store.refresh() }
            }
            .font(.caption)
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .font(.caption)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}
