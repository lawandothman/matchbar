import SwiftUI

struct DashboardView: View {
    let store: MatchStore
    @State private var tab: DashboardTab = .matches
    @State private var launchAtLogin = LaunchAtLogin.isEnabled
    @State private var selectedTeam: String?
    @State private var selectedGroup: String?
    @State private var selectedFixtureID: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()

            VStack(alignment: .leading, spacing: 0) {
                if let fixtureID = selectedFixtureID {
                    MatchDetailView(store: store, fixtureID: fixtureID) {
                        selectedFixtureID = nil
                    }
                } else {
                    mainContent
                }
            }
            .frame(maxWidth: .infinity, minHeight: 460, alignment: .top)

            Divider()
            footer
        }
        .frame(width: 460)
        .onAppear { store.refreshNow() }
    }

    @ViewBuilder
    private var mainContent: some View {
        VStack(alignment: .leading, spacing: 0) {
                tabPicker
                switch tab {
                case .matches:
                    if store.sections.isEmpty {
                        emptyState
                    } else {
                        if let summary = filterSummary {
                            MatchFilterSummary(text: summary) {
                                selectedTeam = nil
                                selectedGroup = nil
                            }
                            .padding(.horizontal, 12)
                            .padding(.top, 8)
                        }

                        if visibleSections.isEmpty {
                            Text("No matches for this filter")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                        } else {
                            fixtureList
                        }
                    }
                case .groups:
                    StandingsView(standings: store.standings)
                }
        }
    }

    private var tabPicker: some View {
        Picker("", selection: $tab) {
            Text("Matches").tag(DashboardTab.matches)
            Text("Groups").tag(DashboardTab.groups)
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .controlSize(.small)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .overlay(alignment: .trailing) {
            if tab == .matches {
                MatchFilterMenu(
                    teams: store.allTeams,
                    groups: store.groupLabels,
                    selectedTeam: $selectedTeam,
                    selectedGroup: $selectedGroup
                )
                .padding(.trailing, 12)
                .padding(.top, 8)
            }
        }
    }

    private var filterSummary: String? {
        var parts: [String] = []
        if let tla = selectedTeam,
           let team = store.allTeams.first(where: { $0.tla == tla }) {
            parts.append([team.flag, team.displayName].compactMap { $0 }.joined(separator: " "))
        }
        if let group = selectedGroup {
            parts.append(group)
        }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
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

    private var visibleSections: [FixtureDaySection] {
        store.sections.compactMap { section in
            let fixtures = section.fixtures.filter(passesFilters)
            guard !fixtures.isEmpty else { return nil }
            return FixtureDaySection(day: section.day, fixtures: fixtures)
        }
    }

    private func passesFilters(_ fixture: Fixture) -> Bool {
        if let team = selectedTeam,
           fixture.homeTeam.tla != team, fixture.awayTeam.tla != team {
            return false
        }
        if let group = selectedGroup, fixture.group != group {
            return false
        }
        return true
    }

    private var fixtureList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(visibleSections) { section in
                        VStack(alignment: .leading, spacing: 0) {
                            Text(section.title)
                                .font(.system(size: 10, weight: .semibold))
                                .textCase(.uppercase)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 12)
                                .padding(.top, 10)
                                .padding(.bottom, 2)

                            ForEach(section.fixtures) { fixture in
                                FixtureRowButton(fixture: fixture) {
                                    selectedFixtureID = fixture.id
                                }
                                .padding(.horizontal, 4)
                            }
                        }
                        .id(section.id)
                    }
                }
                .padding(.bottom, 8)
            }
            .frame(maxHeight: 500)
            .onAppear { scrollToToday(proxy) }
            .onChange(of: store.sections.count) { _, _ in scrollToToday(proxy) }
            .onChange(of: selectedTeam) { _, _ in scrollToToday(proxy) }
            .onChange(of: selectedGroup) { _, _ in scrollToToday(proxy) }
        }
    }

    private func scrollToToday(_ proxy: ScrollViewProxy) {
        let startOfToday = Calendar.current.startOfDay(for: Date())
        guard let id = visibleSections.first(where: { $0.day >= startOfToday })?.id
            ?? visibleSections.last?.id
        else { return }
        DispatchQueue.main.async {
            proxy.scrollTo(id, anchor: .top)
        }
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
            if let aged = store.restoredSavedAt {
                Text("Last seen \(aged, format: .dateTime.hour().minute())")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else if let error = store.lastError, !store.fixtures.isEmpty {
                Text(error)
                    .font(.caption2)
                    .foregroundStyle(.red)
            } else if let updated = store.lastUpdated {
                Text("Updated \(updated, format: .dateTime.hour().minute())")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            settingsMenu
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

    private var settingsMenu: some View {
        Menu {
            Toggle("Launch at login", isOn: $launchAtLogin)
            Button("Check for updates") {
                UpdateManager.checkForUpdates()
            }
        } label: {
            Image(systemName: "gearshape")
                .font(.system(size: 11))
        }
        .menuIndicator(.hidden)
        .fixedSize()
        .onChange(of: launchAtLogin) { _, enabled in
            if !LaunchAtLogin.set(enabled) {
                launchAtLogin = LaunchAtLogin.isEnabled
            }
        }
    }
}
