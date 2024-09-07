import SwiftUI
import Firebase

struct DriverProfileView: View {
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var licenseNumber: String = ""
    @State private var phoneNumber: String = "+7"
    @State private var profileSaved: Bool = false
    @State private var navigateToDriverTab: Bool = false
    @Environment(\.presentationMode) var presentationMode
    
    var userID: String
    var email: String
    
    // Ошибки валидации
    @State private var firstNameError: String? = nil
    @State private var lastNameError: String? = nil
    @State private var licenseError: String? = nil
    @State private var phoneError: String? = nil
    
    // Ограничение на количество символов
    private let maxPhoneNumberLength = 12  // +7 и 10 цифр
    private let maxLicenseNumberLength = 10 // Водительское удостоверение - 10 символов
    
    // Валидация полей с использованием Validation
    func validateFields() -> Bool {
        // Очищаем предыдущие ошибки
        firstNameError = nil
        lastNameError = nil
        licenseError = nil
        phoneError = nil
        
        // Вызываем валидацию и получаем ошибки
        let validationResult = Validation.validateDriverProfile(
            firstName: firstName,
            lastName: lastName,
            licenseNumber: licenseNumber,
            phoneNumber: phoneNumber
        )
        
        // Обновляем ошибки, если они есть
        firstNameError = validationResult["firstName"]
        lastNameError = validationResult["lastName"]
        licenseError = validationResult["licenseNumber"]
        phoneError = validationResult["phoneNumber"]
        
        // Если ошибок нет, возвращаем true
        return validationResult.isEmpty
    }
    
    var body: some View {
        VStack {
            VStack(alignment: .leading) {
                TextField("Имя", text: $firstName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .border(firstNameError != nil ? Color.red : Color.clear, width: 2)
                if let firstNameError = firstNameError {
                    Text(firstNameError)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.leading)
                }
            }
            
            VStack(alignment: .leading) {
                TextField("Фамилия", text: $lastName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .border(lastNameError != nil ? Color.red : Color.clear, width: 2)
                if let lastNameError = lastNameError {
                    Text(lastNameError)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.leading)
                }
            }
            
            VStack(alignment: .leading) {
                TextField("Номер водительского удостоверения", text: $licenseNumber)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .keyboardType(.numberPad)
                    .onChange(of: licenseNumber) { newValue in
                        if newValue.count > maxLicenseNumberLength {
                            licenseNumber = String(newValue.prefix(maxLicenseNumberLength))
                        }
                    }
                    .border(licenseError != nil ? Color.red : Color.clear, width: 2)
                if let licenseError = licenseError {
                    Text(licenseError)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.leading)
                }
            }
            
            VStack(alignment: .leading) {
                TextField("Телефон", text: $phoneNumber)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .keyboardType(.phonePad)
                    .onChange(of: phoneNumber) { newValue in
                        if newValue.count > maxPhoneNumberLength {
                            phoneNumber = String(newValue.prefix(maxPhoneNumberLength))
                        }
                    }
                    .border(phoneError != nil ? Color.red : Color.clear, width: 2)
                if let phoneError = phoneError {
                    Text(phoneError)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.leading)
                }
            }
            
            Button(action: {
                if validateFields() {
                    saveProfile()
                } else {
                    print("Заполните все поля корректно")
                }
            }) {
                Text("Сохранить профиль")
            }
            .padding()
            
            NavigationLink(destination: DriverTabView(userID: userID), isActive: $navigateToDriverTab) {
                EmptyView()
            }
        }
        .navigationTitle("Профиль Водителя")
    }
    
    func saveProfile() {
        let db = Firestore.firestore()
        
        let data: [String: Any] = [
            "driverID": userID,
            "email": email,
            "firstName": firstName,
            "lastName": lastName,
            "licenseNumber": licenseNumber,
            "phoneNumber": Validation.formatPhoneNumber(phoneNumber),
            "role": "driver"
        ]
        
        db.collection("DriverProfiles").document(userID).setData(data) { error in
            if let error = error {
                print("Ошибка при сохранении профиля: \(error.localizedDescription)")
            } else {
                // Сохранение статуса авторизации и роли в UserDefaults
                UserDefaults.standard.set(true, forKey: "isLogged")
                UserDefaults.standard.set(userID, forKey: "userId")
                UserDefaults.standard.set("driver", forKey: "userRole")
                
                profileSaved = true
                navigateToDriverTab = true
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}
