import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

struct RegisterView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    
    @Binding var selectedRole: String
    @State private var isRegistrationComplete: Bool = false
    @State private var authUserID: String? = nil  // Для хранения идентификатора пользователя
    @State private var shouldNavigateToProfile: Bool = false  // Для отслеживания перехода на профиль

    // Ошибки валидации
    @State private var emailError: String? = nil
    @State private var passwordError: String? = nil
    @State private var generalError: String? = nil

    var body: some View {
        NavigationView {
            VStack {
                Picker("Выберите роль", selection: $selectedRole) {
                    Text("Организация").tag("admin")
                    Text("Водитель").tag("driver")
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()

                // Email Field
                VStack(alignment: .leading) {
                    TextField("Почта", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .border(emailError != nil ? Color.red : Color.clear, width: 2)
                    
                    if let emailError = emailError {
                        Text(emailError)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.leading)
                    }
                }
                
                // Password Field
                VStack(alignment: .leading) {
                    SecureField("Пароль", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                        .border(passwordError != nil ? Color.red : Color.clear, width: 2)
                    
                    if let passwordError = passwordError {
                        Text(passwordError)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.leading)
                    }
                }

                if let generalError = generalError {
                    Text(generalError)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.leading)
                }
                
                Button(action: {
                    // Валидация перед регистрацией
                    if validateFields() {
                        registerNewUser(email: email, password: password, role: selectedRole)
                    }
                }) {
                    Text("Зарегистрироваться и продолжить")
                }
                .disabled(selectedRole.isEmpty || isRegistrationComplete)
                .padding()
                
                // Условный переход на нужный экран профиля в зависимости от роли
                NavigationLink(
                    destination: selectedRole == "admin" ? AnyView(AdminProfileView(userID: authUserID ?? "", email: email)) : AnyView(DriverProfileView(userID: authUserID ?? "", email: email)),
                    isActive: $shouldNavigateToProfile
                ) {
                    EmptyView()
                }
            }
            .navigationBarTitle("Регистрация")
        }
    }

    // Валидация полей
    func validateFields() -> Bool {
        emailError = nil
        passwordError = nil
        generalError = nil

        var isValid = true

        if !Validation.isValidEmail(email) {
            emailError = "Неверный формат email"
            isValid = false
        }

        if !Validation.isValidPassword(password) {
            passwordError = "Пароль должен быть не менее 6 символов"
            isValid = false
        }

        if selectedRole.isEmpty {
            generalError = "Выберите роль"
            isValid = false
        }

        return isValid
    }
    
    func registerNewUser(email: String, password: String, role: String) {
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                generalError = "Ошибка при регистрации: \(error.localizedDescription)"
                return
            }
            
            if let user = authResult?.user {
                authUserID = user.uid  // Сохраняем идентификатор пользователя для дальнейшего использования
                let db = Firestore.firestore()
                let userData = [
                    "email": user.email ?? "",
                    "role": role
                ]
                
                // Определяем коллекцию в зависимости от роли
                let collection = role == "admin" ? "AdminProfiles" : "DriverProfiles"
                
                // Сохранение данных пользователя в соответствующей коллекции
                db.collection(collection).document(user.uid).setData(userData) { error in
                    if let error = error {
                        generalError = "Ошибка при сохранении данных: \(error.localizedDescription)"
                    } else {
                        DispatchQueue.main.async {
                            isRegistrationComplete = true
                            shouldNavigateToProfile = true  // Переход на экран профиля после успешной регистрации
                        }
                    }
                }
            }
        }
    }
}
