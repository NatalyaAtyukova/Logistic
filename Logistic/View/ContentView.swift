//
//  ContentView.swift
//  Logistic
//
//  Created by Наталья Атюкова on 27.03.2024.
//
import SwiftUI

struct ContentView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isLogged = false
    @State private var selectedRole: String = "" // Убираем выбор роли из ContentView

    var firebaseManager = FirebaseManager.shared

    var body: some View {
        NavigationView {
            if isLogged {
                Button("Sign Out") {
                    // Выход из учетной записи
                    firebaseManager.signOut { success in
                        if success {
                            isLogged = false
                        } else {
                            // Возможно, здесь нужно добавить обработку ошибки
                        }
                    }
                }
                .padding()

            } else {
                VStack {
                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                    SecureField("Password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()

                    Button("Sign In") {
                        // Вход в учетную запись
                        isLogged = true // Временная заглушка, так как логику регистрации с ролью переносим

                    }
                    .padding()

                    NavigationLink(destination: RegisterView(selectedRole: $selectedRole)) {
                        Text("Go to Register")
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Logistic")
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

