import SwiftUI
import Firebase

class DriverProfileViewModel: ObservableObject {
    @Published var firstName: String = ""
    @Published var lastName: String = ""
    @Published var licenseNumber: String = ""
    @Published var phoneNumber: String = "+7"
    @Published var profileSaved: Bool = false
    @Published var navigateToDriverTab: Bool = false

    @Published var firstNameError: String? = nil
    @Published var lastNameError: String? = nil
    @Published var licenseError: String? = nil
    @Published var phoneError: String? = nil

    private let maxPhoneNumberLength = 12
    private let maxLicenseNumberLength = 10

    var userID: String
    var email: String

    init(userID: String, email: String) {
        self.userID = userID
        self.email = email
    }

    // Валидация полей
    func validateFields() -> Bool {
        firstNameError = nil
        lastNameError = nil
        licenseError = nil
        phoneError = nil
        
        let validationResult = Validation.validateDriverProfile(
            firstName: firstName,
            lastName: lastName,
            licenseNumber: licenseNumber,
            phoneNumber: phoneNumber
        )
        
        firstNameError = validationResult["firstName"]
        lastNameError = validationResult["lastName"]
        licenseError = validationResult["licenseNumber"]
        phoneError = validationResult["phoneNumber"]

        return validationResult.isEmpty
    }

    // Ограничение длины телефона и номера лицензии
    func limitTextFieldInput() {
        if phoneNumber.count > maxPhoneNumberLength {
            phoneNumber = String(phoneNumber.prefix(maxPhoneNumberLength))
        }
        if licenseNumber.count > maxLicenseNumberLength {
            licenseNumber = String(licenseNumber.prefix(maxLicenseNumberLength))
        }
    }

    // Сохранение профиля
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
                UserDefaults.standard.set(true, forKey: "isLogged")
                UserDefaults.standard.set(self.userID, forKey: "userId")
                UserDefaults.standard.set("driver", forKey: "userRole")

                DispatchQueue.main.async {
                    self.profileSaved = true
                    self.navigateToDriverTab = true
                }
            }
        }
    }
}
