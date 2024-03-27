//
//  AddressAutocompleteTextField.swift
//  Logistic
//
//  Created by Наталья Атюкова on 07.07.2024.
//

import Foundation
import SwiftUI
import CoreLocation

struct AddressAutocompleteTextField: View {
    let title: String
    @Binding var address: String
    @Binding var coordinate: CLLocationCoordinate2D?
    @Binding var suggestions: [DaDataSuggestion]
    @Binding var isShowingSuggestions: Bool
    let onAddressSelected: (DaDataSuggestion) -> Void

    @State private var isLoading = false

    var body: some View {
        VStack {
            TextField(title, text: $address, onEditingChanged: { isEditing in
                if !isEditing {
                    self.isShowingSuggestions = false
                }
            })
            .padding(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray, lineWidth: 1)
            )
            .onChange(of: address) { newValue in
                if newValue.isEmpty {
                    self.isShowingSuggestions = false
                    self.suggestions = []
                } else {
                    self.isLoading = true
                    // Simulate API call to suggest addresses
                    DaDataService().suggestAddress(query: newValue) { suggestions in
                        DispatchQueue.main.async {
                            self.suggestions = suggestions ?? []
                            self.isLoading = false
                            self.isShowingSuggestions = !self.suggestions.isEmpty
                        }
                    }
                }
            }

            if isLoading {
                ProgressView()
                    .padding()
            }

            if isShowingSuggestions && !isLoading {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(suggestions, id: \.self) { suggestion in
                            Button(action: {
                                self.address = suggestion.value
                                if let lat = Double(suggestion.data.geo_lat ?? ""),
                                   let lon = Double(suggestion.data.geo_lon ?? "") {
                                    self.coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                                }
                                self.isShowingSuggestions = false
                                self.onAddressSelected(suggestion)
                            }) {
                                HStack {
                                    Text(suggestion.value)
                                        .foregroundColor(.blue)
                                        .padding(.vertical, 10)
                                        .padding(.horizontal, 16)
                                    Spacer()
                                }
                            }
                            .background(Color.white)
                            .cornerRadius(8)
                            .padding(.vertical, 4)
                            .shadow(radius: 5)
                        }
                    }
                    .padding(.horizontal, 8)
                }
                .frame(maxHeight: 200) // Ограничение высоты списка для скроллинга
                .background(Color.gray.opacity(0.2)) // Фон ScrollView
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray, lineWidth: 1)
                )
                .shadow(radius: 5)
            }
        }
        .padding(.horizontal)
    }
}
