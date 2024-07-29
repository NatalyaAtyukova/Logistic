//
//  AlertManager.swift
//  Logistic
//
//  Created by Наталья Атюкова on 16.05.2024.
//

import SwiftUI

class AlertManager: ObservableObject {
    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published var isError = true // Флаг для отслеживания типа сообщения. По умолчанию установлен на true (ошибка)
    
    func showError(message: String) {
        alertMessage = message
        showAlert = true
        isError = true // Устанавливаем флаг ошибки
    }
    
    func showSuccess(message: String) {
        alertMessage = message
        showAlert = true
        isError = false // Устанавливаем флаг успешного действия
    }
}


struct AlertView: View {
    @StateObject private var alertManager = AlertManager()
    @State private var isError = true // Переменная для отслеживания типа сообщения
    
    var body: some View {
        VStack {
            Button("Show Error") {
                alertManager.showError(message: "Произошла ошибка. Попробуйте еще раз.")
                isError = true // Устанавливаем тип сообщения на "Ошибка"
            }
            Button("Show Success") {
                alertManager.showSuccess(message: "Операция успешно выполнена.")
                isError = false // Устанавливаем тип сообщения на "Успешно"
            }
        }
        .alert(isPresented: $alertManager.showAlert) {
            let title = isError ? "Ошибка" : "Успешно" // Выбираем заголовок в зависимости от типа сообщения
            return Alert(title: Text(title), message: Text(alertManager.alertMessage), dismissButton: .default(Text("OK")))
        }
    }
}

struct AnotherView: View {
    var alertManager: AlertManager
    
    var body: some View {
        Button("Показать ошибку") {
            alertManager.showError(message: "Ошибка из другого представления")
        }
    }
}

