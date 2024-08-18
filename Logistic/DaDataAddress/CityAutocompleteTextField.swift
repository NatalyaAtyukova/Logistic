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
                self.isShowingSuggestions = true
            }, onCommit: {
                self.isShowingSuggestions = false
            })
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .padding()
            
            if isShowingSuggestions {
                List {
                    ForEach(suggestions.filter {
                        $0.lowercased().contains(city.lowercased())
                    }, id: \.self) { suggestion in
                        Text(suggestion)
                            .onTapGesture {
                                self.onCitySelected(suggestion)
                            }
                    }
                }
                .frame(maxHeight: 200)
            }
        }
    }
}

