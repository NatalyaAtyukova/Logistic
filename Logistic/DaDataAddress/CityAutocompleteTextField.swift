//
//  CityAutocompleteTextField.swift
//  Logistic
//
//  Created by Наталья Атюкова on 27.07.2024.
//

import SwiftUI

struct CityAutocompleteTextField: View {
    var title: String
    @Binding var city: String
    @Binding var suggestions: [String]
    @Binding var isShowingSuggestions: Bool
    var onCitySelected: (String) -> Void
    
    var body: some View {
        VStack {
            TextField(title, text: $city, onEditingChanged: { isEditing in
                if isEditing {
                    isShowingSuggestions = true
                } else {
                    isShowingSuggestions = false
                }
            })
            .padding()
            .background(Color.gray.opacity(0.2))
            .cornerRadius(8)
            
            // Отображаем список предложений только если isShowingSuggestions == true
            if isShowingSuggestions && !suggestions.isEmpty {
                List(suggestions, id: \.self) { suggestion in
                    Text(suggestion)
                        .onTapGesture {
                            onCitySelected(suggestion)
                        }
                }
                .frame(maxHeight: 150) // Ограничение высоты списка
            }
        }
    }
}
