//
//  ZoomControlsView.swift
//  Logistic
//
//  Created by Наталья Атюкова on 18.07.2024.
//

import Foundation
import SwiftUI
import MapKit

struct ZoomControlsView: View {
    var zoomIn: () -> Void
    var zoomOut: () -> Void

    var body: some View {
        VStack {
            Button(action: zoomIn) {
                Image(systemName: "plus.magnifyingglass")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(Circle())
            }
            .padding()

            Button(action: zoomOut) {
                Image(systemName: "minus.magnifyingglass")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(Circle())
            }
            .padding()
        }
    }
}
