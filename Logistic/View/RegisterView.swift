//
//  RegisterView.swift
//  Logistic
//
//  Created by Наталья Атюкова on 27.03.2024.
//
import SwiftUI
import FirebaseAuth
import FirebaseDatabase



struct RegisterView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    
    @Binding var selectedRole: String // Переменная для хранения выбранной роли
    @State private var isRegistrationComplete: Bool = false // Флаг для отслеживания завершения регистрации
    
    var body: some View {
        NavigationView {
            VStack {
                Picker("Выберите роль", selection: $selectedRole) {
                    Text("Организация").tag("admin")
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
                
                Button(action: {
                    registerNewUser(email: email, password: password, role: selectedRole)
                    isRegistrationComplete = true // Устанавливаем флаг, чтобы активировать NavigationLink
                }) {
                    Text("Зарегистрироваться и продолжить")
                }
                .disabled(selectedRole.isEmpty || isRegistrationComplete) // Деактивируем кнопку, если роль не выбрана или регистрация уже завершена
                .padding()
                
                NavigationLink(
                    destination: selectedRole == "admin" ? AnyView(AdminProfileView()) : AnyView(DriverProfileView()),
                    isActive: $isRegistrationComplete
                ) {
                    EmptyView()
                }
            }
            .navigationBarTitle("Регистрация") // Добавляем заголовок навигации здесь
        }
    }
}



func registerNewUser(email: String, password: String, role: String) {
    Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
        if let error = error {
            print("Ошибка при регистрации пользователя: \(error.localizedDescription)")
            return
        }
        
        // Пользователь успешно зарегистрирован, добавляем информацию в базу данных
        if let user = authResult?.user {
            let userData = ["email": user.email, "role": role]
            Database.database().reference().child("users").child(user.uid).setValue(userData)
        }
    }
}

struct RegisterView_Previews: PreviewProvider {
    static var previews: some View {
        RegisterView(selectedRole: .constant("admin")) // Передаем значение для selectedRole
    }
}
