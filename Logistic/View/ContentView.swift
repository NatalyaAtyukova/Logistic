//
//  ContentView.swift
//  Logistic
//
//  Created by Наталья Атюкова on 27.03.2024.
//
import SwiftUI
import Firebase

struct ContentView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isLogged = false
    @State private var userRole: String = ""
    @State private var selectedRole: String = ""
    @State private var selectedView: AnyView? // Добавляем свойство для хранения выбранного представления
    
    var body: some View {
        NavigationView {
            if isLogged {
                if let selectedView = selectedView {
                    selectedView
                } else {
                    Text("Ошибка: Неизвестная роль пользователя")
                        .foregroundColor(.red)
                        .padding()
                }
            } else {
                VStack(spacing: 20) {
                    Text("Добро пожаловать!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.bottom, 20)
                    
                    TextField("Почта", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    
                    SecureField("Пароль", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    
                    Button(action: {
                        signIn()
                    }) {
                        Text("Вход")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    
                    NavigationLink(destination: RegisterView(selectedRole: $selectedRole)) {
                        Text("Регистрация")
                            .font(.headline)
                            .foregroundColor(.blue)
                    }
                    .padding(.top, 10)
                }
                .padding()
            }
        }
        .navigationTitle("Logistic")
    }
    
    func signIn() {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                print("Ошибка входа в систему: \(error.localizedDescription)")
            } else {
                guard let user = result?.user else {
                    print("Ошибка: UID пользователя не найден")
                    return
                }
                let userId = user.uid
                print("UID текущего пользователя: \(userId)")
                
                let db = Firestore.firestore()
                let adminProfileRef = db.collection("AdminProfiles").document(userId)
                let driverProfileRef = db.collection("DriverProfiles").document(userId)
                
                adminProfileRef.getDocument { adminDocument, adminError in
                    if let adminDocument = adminDocument, adminDocument.exists {
                        self.userRole = "admin"
                        print("Роль пользователя: админ")
                        
                        // Устанавливаем выбранное представление в AdminTabView
                        DispatchQueue.main.async {
                            self.isLogged = true
                            self.selectedView = AnyView(AdminTabView())
                            print("Переход на интерфейс")
                        }
                    } else {
                        driverProfileRef.getDocument { driverDocument, driverError in
                            if let driverDocument = driverDocument, driverDocument.exists {
                                self.userRole = "driver"
                                print("Роль пользователя: водитель")
                                
                                // Устанавливаем выбранное представление в DriverTabView
                                DispatchQueue.main.async {
                                    self.isLogged = true
                                    self.selectedView = AnyView(DriverTabView())
                                    print("Переход на интерфейс")
                                }
                            } else {
                                print("Данные профиля пользователя не найдены")
                            }
                        }
                    }
                }
            }
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

