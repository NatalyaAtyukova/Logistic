//
//  RegisterView.swift
//  Logistic
//
//  Created by Наталья Атюкова on 27.03.2024.
//
import SwiftUI

struct RegisterView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var displayName: String = ""
    @Binding var selectedRole: String // Переменная для хранения выбранной роли

    var body: some View {
        VStack {
            Picker("Выберите роль", selection: $selectedRole) {
                Text("Администратор").tag("admin")
                Text("Водитель").tag("driver")
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()

            TextField("Почта", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            SecureField("Пароль", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            if selectedRole == "admin" {
                TextField("ИНН организации", text: $displayName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
            } else {
                TextField("Номер ВУ", text: $displayName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
            }

            NavigationLink(destination: UserProfileView()) {
                Text("Продолжить")
            }
            .padding()
        }
    }
}
