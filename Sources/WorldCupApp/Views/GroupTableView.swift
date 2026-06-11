import SwiftUI

struct GroupTableView: View {
    let standing: GroupStanding

    var body: some View {
        VStack(spacing: 3) {
            HStack(spacing: 4) {
                Text(standing.label)
                    .font(.system(size: 11, weight: .bold))
                    .frame(maxWidth: .infinity, alignment: .leading)

                Group {
                    Text("P").frame(width: 18, alignment: .trailing)
                    Text("W").frame(width: 18, alignment: .trailing)
                    Text("D").frame(width: 18, alignment: .trailing)
                    Text("L").frame(width: 18, alignment: .trailing)
                    Text("GD").frame(width: 26, alignment: .trailing)
                    Text("Pts").frame(width: 24, alignment: .trailing)
                }
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
            }
            .padding(.leading, 16)

            ForEach(standing.table) { row in
                StandingRowView(row: row)
            }
        }
    }
}
