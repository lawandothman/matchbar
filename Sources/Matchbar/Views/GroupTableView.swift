import SwiftUI

struct GroupTableView: View {
    let standing: GroupStanding

    var body: some View {
        VStack(spacing: 3) {
            HStack(spacing: 4) {
                Text(standing.label)
                    .font(.system(size: 12, weight: .bold))
                    .frame(maxWidth: .infinity, alignment: .leading)

                Group {
                    Text("P").frame(width: 18, alignment: .trailing)
                    Text("W").frame(width: 18, alignment: .trailing)
                    Text("D").frame(width: 18, alignment: .trailing)
                    Text("L").frame(width: 18, alignment: .trailing)
                    Text("GF").frame(width: 18, alignment: .trailing)
                    Text("GA").frame(width: 18, alignment: .trailing)
                    Text("GD").frame(width: 24, alignment: .trailing)
                    Text("Pts").frame(width: 22, alignment: .trailing)
                }
                .font(.system(size: 10))
                .foregroundStyle(.secondary)

                Color.clear.frame(width: 53, height: 1)
            }
            .padding(.leading, 24)

            ForEach(standing.table) { row in
                StandingRowView(row: row)
            }
        }
    }
}
