import SwiftUI

struct MenuBarLabel: View {
    let store: MatchStore

    var body: some View {
        if let live = store.liveFixtures.first {
            let extra = store.liveFixtures.count - 1
            Text("\(live.homeTeam.shortName) \(live.score.display) \(live.awayTeam.shortName)\(extra > 0 ? " +\(extra)" : "")")
                .monospacedDigit()
        } else {
            Image(systemName: "soccerball")
        }
    }
}
