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
                    Text("P").frame(width: 20, alignment: .trailing)
                    Text("W").frame(width: 20, alignment: .trailing)
                    Text("D").frame(width: 20, alignment: .trailing)
                    Text("L").frame(width: 20, alignment: .trailing)
                    Text("GD").frame(width: 30, alignment: .trailing)
                    Text("Pts").frame(width: 28, alignment: .trailing)
                }
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
            }
            .padding(.leading, 18)

            ForEach(standing.table) { row in
                StandingRowView(row: row)
            }
        }
    }
}
