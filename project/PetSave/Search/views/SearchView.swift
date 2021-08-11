/// Copyright (c) 2021 Razeware LLC
/// 
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
/// 
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
/// 
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
/// 
/// This project and source code may use libraries or frameworks that are
/// released under various Open-Source licenses. Use of those libraries and
/// frameworks are governed by their own individual licenses.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import SwiftUI

// Chapter 10: Animation here while data is loading

#warning("Move to it's own file... But where? Inside ViewModels?")
struct FilterAnimals {
  let animals: FetchedResults<AnimalEntity>
  let query: String
  let age: AnimalSearchAge
  let type: AnimalSearchType

  func callAsFunction() -> [AnimalEntity] {
    let ageText = age.rawValue.lowercased()
    let typeText = type.rawValue.lowercased()
    return animals.filter {
      if ageText != "none" {
        return $0.age.rawValue.lowercased() == ageText
      }
      return true
    }
    .filter {
      if typeText != "none" {
        return $0.type?.lowercased() == typeText
      }
      return true
    }
    .filter {
      if query.isEmpty {
        return true
      }
      return $0.name?.contains(query) ?? false
    }
  }
}

struct SearchView: View {
  let navigationTitle = LocalizedStringKey("SEARCH_NAVIGATION_TITLE")

  @ObservedObject var viewModel: SearchViewModel
  @State var searchText = ""

  @FetchRequest(
    sortDescriptors: [NSSortDescriptor(keyPath: \AnimalEntity.timestamp, ascending: true)],
    animation: .default
  )
  private var animals: FetchedResults<AnimalEntity>

  private var filterAnimals: FilterAnimals {
    FilterAnimals(
      animals: animals,
      query: viewModel.searchText,
      age: viewModel.ageSelection,
      type: viewModel.typeSelection
    )
  }

  var searchAnimalsResults: [AnimalEntity] {
    if viewModel.shouldFilter {
      return filterAnimals()
    }
    return []
  }

  var body: some View {
    List {
      ForEach(searchAnimalsResults) { animal in
        NavigationLink(destination: AnimalDetailsView(animal: animal)) {
          AnimalRow(animal: animal)
        }
      }
    }
    .overlay {
      if searchAnimalsResults.isEmpty {
        SuggestionsGrid(suggestions: AnimalSearchType.suggestions) { suggestion in
          viewModel.selectTypeSuggestion(suggestion)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
      }
    }
    .overlay {
      if searchAnimalsResults.isEmpty && !viewModel.searchText.isEmpty {
        VStack {
          Image(systemName: "pawprint.circle.fill")
            .resizable()
            .frame(width: 64, height: 64)
            .padding()
            .foregroundColor(.yellow)
          Text("Sorry, we couldn't find animals with \(viewModel.searchText)")
            .foregroundColor(.secondary)
        }
      }
    }
    .listStyle(.plain)
    .navigationTitle("Find your future pet")
    .searchable(text: $viewModel.searchText)
    .onChange(of: viewModel.searchText) { _ in
      viewModel.search()
    }
    .toolbar {
      ToolbarItem {
        filterMenu
      }
    }
  }

  var filterMenu: some View {
    Menu {
      Section {
        Text("Filter by age")
        Picker("Age", selection: $viewModel.ageSelection) {
          ForEach(AnimalSearchAge.allCases, id: \.self) { age in
            Text(age.rawValue.capitalized)
          }
        }
        .onChange(of: viewModel.ageSelection) { _ in
          viewModel.search()
        }
      }
      Section {
        Text("Filter by type")
        Picker("Type", selection: $viewModel.typeSelection) {
          ForEach(AnimalSearchType.allCases, id: \.self) { type in
            Text(type.rawValue.capitalized)
          }
        }
        .onChange(of: viewModel.typeSelection) { _ in
          viewModel.search()
        }
      }
    } label: {
      Label("Filter", systemImage: "slider.horizontal.3")
    }
  }
}

struct SearchView_Previews: PreviewProvider {
  static var previews: some View {
    let context = PersistenceController.preview.container.viewContext
    NavigationView {
      SearchView(
        viewModel: SearchViewModel(
          animalSearcher: AnimalSearcherMock(),
          context: context
        )
      )
    }

    NavigationView {
      SearchView(
        viewModel: SearchViewModel(
          animalSearcher: AnimalSearcherMock(),
          context: context
        )
      )
    }
    .environment(\.locale, .init(identifier: "es"))
    .previewDisplayName("Spanish Locale")

    // Chapter 12 - Dark mode previews
    NavigationView {
      SearchView(
        viewModel: SearchViewModel(
          animalSearcher: AnimalSearcherMock(),
          context: context
        )
      )
    }
    .preferredColorScheme(.dark)
  }
}
