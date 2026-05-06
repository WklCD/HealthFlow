import SwiftUI
import SwiftData

struct AchievementView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: AchievementViewModel?

    let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ScrollView {
            if let badges = viewModel?.allBadges() {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(badges, id: \.0.rawValue) { definition, earned in
                        VStack(spacing: 8) {
                            Image(systemName: definition.iconName)
                                .font(.system(size: 30))
                                .foregroundStyle(earned ? .yellow : .gray.opacity(0.4))
                            Text(definition.title)
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(earned ? Color.yellow.opacity(0.1) : Color.gray.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay {
                            if !earned {
                                Image(systemName: "lock.fill")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .offset(y: -30)
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("成就徽章")
        .task {
            let vm = AchievementViewModel()
            vm.checkAndAwardBadges(modelContext: modelContext)
            viewModel = vm
        }
    }
}