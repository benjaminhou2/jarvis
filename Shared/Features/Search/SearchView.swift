import SwiftUI
import CoreData
import Combine

struct SearchView: View {
    @Environment(\.managedObjectContext) private var context
    @State private var keyword: String = ""
    @State private var results: [CDTask] = []
    @State private var selectedTag: String? = nil
    @State private var chips: [String] = []
    @State private var searchCancellable: AnyCancellable?

    var body: some View {
        NavigationStack {
            VStack(spacing: 8) {
                TextField("搜索标题或备注（可输入 #标签）", text: $keyword)
                    .textFieldStyle(.roundedBorder)
                // 标签 Chips
                if !chips.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack { ForEach(chips, id: \.self) { tag in
                            Button(action: { toggleTag(tag) }) {
                                Text("#\(tag)")
                                    .padding(.horizontal, 10).padding(.vertical, 6)
                                    .background((selectedTag == tag) ? Color.accentColor.opacity(0.2) : Color.gray.opacity(0.15))
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        } }
                    }
                }
                List(results) { t in
                    NavigationLink { TaskDetailView(task: t) } label: { Text(t.title) }
                }
                Spacer()
            }
            .padding()
            .navigationTitle("搜索")
            .onAppear(perform: setupSearchDebouncer)
            .onChange(of: keyword) { _ in parseChips() }
        }
    }

    private func setupSearchDebouncer() {
        searchCancellable = $keyword
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { _ in
                runSearch()
            }
    }

    private func runSearch() {
        do { results = try TaskRepository(context: context).search(keyword: keyword, tag: selectedTag) } catch { results = [] }
    }

    private func parseChips() { chips = Array(Set(TagExtractor.extract(from: keyword))) }
    private func toggleTag(_ tag: String) { selectedTag = (selectedTag == tag ? nil : tag); runSearch() }
}


