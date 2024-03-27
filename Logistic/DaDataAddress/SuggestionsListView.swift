import Foundation
import SwiftUI
import CoreLocation

struct SuggestionsListView: View {
    let suggestions: [DaDataSuggestion]
    let onSelectSuggestion: (DaDataSuggestion) -> Void

    var body: some View {
        List(suggestions, id: \.value) { suggestion in
            Text(suggestion.value)
                .onTapGesture {
                    onSelectSuggestion(suggestion)
                }
        }
        .frame(maxHeight: 200) // Ограничим высоту списка предложений
        .listStyle(PlainListStyle())
    }
}
