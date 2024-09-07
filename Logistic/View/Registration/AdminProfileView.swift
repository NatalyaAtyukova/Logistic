import SwiftUI
import Firebase

struct AdminProfileView: View {
    @State private var nameOrganisation: String = ""
    @State private var addressOrganisation: String = ""
    @State private var innOrganisation: String = ""
    @State private var phoneNumber: String = "+7"
    @State private var profileSaved: Bool = false
    @State private var navigateToAdminTab: Bool = false
    @Environment(\.presentationMode) var presentationMode

    var userID: String
    var email: String

    // Ошибки валидации
    @State private var nameError: String? = nil
    @State private var addressError: String? = nil
    @State private var innError: String? = nil
    @State private var phoneError: String? = nil

    // Ограничение на количество символов
    private let maxPhoneNumberLength = 12  // +7 и 10 цифр
    private let maxINNLength = 10  // ИНН должен быть из 10 символов

    // Валидация полей с использованием Validation
    func validateFields() -> Bool {
        // Очищаем предыдущие ошибки
        nameError = nil
        addressError = nil
        innError = nil
        phoneError = nil
        
        // Вызываем валидацию и получаем ошибки
        let validationResult = Validation.validateAdminProfile(
            nameOrganisation: nameOrganisation,
            addressOrganisation: addressOrganisation,
            innOrganisation: innOrganisation,
            phoneNumber: phoneNumber
        )
        
        // Обновляем ошибки, если они есть
        nameError = validationResult["nameOrganisation"]
        addressError = validationResult["addressOrganisation"]
        innError = validationResult["innOrganisation"]
        phoneError = validationResult["phoneNumber"]
        
        // Если ошибок нет, возвращаем true
        return validationResult.isEmpty
    }
    
    var body: some View {
        VStack {
            VStack(alignment: .leading) {
                TextField("Наименование организации", text: $nameOrganisation)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .border(nameError != nil ? Color.red : Color.clear, width: 2)
                if let nameError = nameError {
                    Text(nameError)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.leading)
                }
            }

            VStack(alignment: .leading) {
                TextField("ИНН", text: $innOrganisation)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .keyboardType(.numberPad)
                    .onChange(of: innOrganisation) { newValue in
                        if newValue.count > maxINNLength {
                            innOrganisation = String(newValue.prefix(maxINNLength))
                        }
                    }
                    .border(innError != nil ? Color.red : Color.clear, width: 2)
                if let innError = innError {
                    Text(innError)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.leading)
                }
            }

            VStack(alignment: .leading) {
                TextField("Адрес", text: $addressOrganisation)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .border(addressError != nil ? Color.red : Color.clear, width: 2)
                if let addressError = addressError {
                    Text(addressError)
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
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
            
            NavigationLink(destination: AdminTabView(userID: userID), isActive: $navigateToAdminTab) {
                EmptyView()
            }
        }
        .navigationTitle("Профиль Администратора")
    }

    func saveProfile() {
        let db = Firestore.firestore()
        
        let data: [String: Any] = [
            "adminID": userID,
            "email": email,
            "nameOrganisation": nameOrganisation,
            "innOrganisation": innOrganisation,
            "addressOrganisation": addressOrganisation,
            "phoneNumber": Validation.formatPhoneNumber(phoneNumber),
            "role": "admin"
        ]
        
        db.collection("AdminProfiles").document(userID).setData(data) { error in
            if let error = error {
                print("Ошибка при сохранении профиля: \(error.localizedDescription)")
            } else {
                // Сохранение статуса авторизации и роли в UserDefaults
                UserDefaults.standard.set(true, forKey: "isLogged")
                UserDefaults.standard.set(userID, forKey: "userId")
                UserDefaults.standard.set("admin", forKey: "userRole")
                
                profileSaved = true
                navigateToAdminTab = true
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}
