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

    // Ограничение ввода по символам
    private let maxPhoneNumberLength = 12  // +7 и 10 цифр
    private let maxLicenseNumberLength = 10 // Водительское удостоверение - 10 символов

    // Валидация полей
    func validateFields() -> Bool {
        firstNameError = nil
        lastNameError = nil
        licenseError = nil
        phoneError = nil
        
        var isValid = true

        if !Validation.isValidName(firstName) {
            firstNameError = "Имя должно содержать только русские буквы"
            isValid = false
        }

        if !Validation.isValidName(lastName) {
            lastNameError = "Фамилия должна содержать только русские буквы"
            isValid = false
        }

        if !Validation.isNotEmpty(licenseNumber) || licenseNumber.count != maxLicenseNumberLength {
            licenseError = "Номер водительского удостоверения должен содержать 10 символов"
            isValid = false
        }

        if !Validation.isValidPhoneNumber(phoneNumber) || phoneNumber.count != maxPhoneNumberLength {
            phoneError = "Номер телефона должен содержать 12 символов и начинаться с +7"
            isValid = false
        }

        return isValid
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
            
            NavigationLink(destination: DriverTabView(), isActive: $navigateToDriverTab) {
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
            "phoneNumber": phoneNumber,
            "role": "driver"
        ]
        
        db.collection("DriverProfiles").document(userID).setData(data) { error in
            if let error = error {
                print("Ошибка при сохранении профиля: \(error.localizedDescription)")
            } else {
                profileSaved = true
                navigateToDriverTab = true
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}
