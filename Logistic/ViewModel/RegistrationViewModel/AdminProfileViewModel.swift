import SwiftUI
import Firebase

class AdminProfileViewModel: ObservableObject {
    @Published var nameOrganisation: String = ""
    @Published var addressOrganisation: String = ""
    @Published var innOrganisation: String = ""
    @Published var phoneNumber: String = "+7"
    @Published var profileSaved: Bool = false
    @Published var navigateToAdminTab: Bool = false
    
    @Published var nameError: String? = nil
    @Published var addressError: String? = nil
    @Published var innError: String? = nil
    @Published var phoneError: String? = nil

    private let maxPhoneNumberLength = 12
    private let maxINNLength = 10

    var userID: String
    var email: String

    init(userID: String, email: String) {
        self.userID = userID
        self.email = email
    }

    // Валидация полей
    func validateFields() -> Bool {
        nameError = nil
        addressError = nil
        innError = nil
        phoneError = nil
        
        let validationResult = Validation.validateAdminProfile(
            nameOrganisation: nameOrganisation,
            addressOrganisation: addressOrganisation,
            innOrganisation: innOrganisation,
            phoneNumber: phoneNumber
        )
        
        nameError = validationResult["nameOrganisation"]
        addressError = validationResult["addressOrganisation"]
        innError = validationResult["innOrganisation"]
        phoneError = validationResult["phoneNumber"]

        return validationResult.isEmpty
    }

    // Ограничение длины телефона и ИНН
    func limitTextFieldInput() {
        if phoneNumber.count > maxPhoneNumberLength {
            phoneNumber = String(phoneNumber.prefix(maxPhoneNumberLength))
        }
        if innOrganisation.count > maxINNLength {
            innOrganisation = String(innOrganisation.prefix(maxINNLength))
        }
    }

    // Сохранение профиля
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
                UserDefaults.standard.set(true, forKey: "isLogged")
                UserDefaults.standard.set(self.userID, forKey: "userId")
                UserDefaults.standard.set("admin", forKey: "userRole")

                DispatchQueue.main.async {
                    self.profileSaved = true
                    self.navigateToAdminTab = true
                }
            }
        }
    }
}
