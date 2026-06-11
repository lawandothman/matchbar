import SwiftUI

struct MenuBarLabel: View {
    let store: MatchStore

    var body: some View {
        if let live = store.liveFixtures.first {
            let extra = store.liveFixtures.count - 1
            let home = live.homeTeam.flag ?? live.homeTeam.code
            let away = live.awayTeam.flag ?? live.awayTeam.code
            Text("\(home) \(live.score.display) \(away)\(extra > 0 ? " +\(extra)" : "")")
                .monospacedDigit()
        } else {
            Image(systemName: "soccerball")
        }
    }
}
