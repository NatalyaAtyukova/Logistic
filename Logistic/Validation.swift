import Foundation

struct Validation {

    static func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    static func isValidPassword(_ password: String) -> Bool {
        return password.count >= 6 && password.count <= 20
    }
    
    static func isValidPhoneNumber(_ phoneNumber: String) -> Bool {
        let phoneRegex = "^\\+7\\d{10}$"
        let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        return phonePredicate.evaluate(with: phoneNumber)
    }
    
        static func isValidName(_ name: String) -> Bool {
            let nameRegex = "^[А-Яа-яЁё\\s-]{1,50}$"
            let namePredicate = NSPredicate(format: "SELF MATCHES %@", nameRegex)
            return namePredicate.evaluate(with: name)
        }
        
        static func isValidLicenseNumber(_ licenseNumber: String) -> Bool {
            let licenseRegex = "^[0-9]{10}$"
            let licensePredicate = NSPredicate(format: "SELF MATCHES %@", licenseRegex)
            return licensePredicate.evaluate(with: licenseNumber)
        }
        
        static func isNotEmpty(_ text: String) -> Bool {
            return !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        
        static func limitText(_ text: String, limit: Int) -> String {
            return String(text.prefix(limit))
        }
        
        static func formatPhoneNumber(_ phoneNumber: String) -> String {
            var cleanedPhoneNumber = phoneNumber
            if cleanedPhoneNumber.starts(with: "8") {
                cleanedPhoneNumber = String(cleanedPhoneNumber.dropFirst())
            }
            if !cleanedPhoneNumber.starts(with: "+7") {
                cleanedPhoneNumber = "+7" + cleanedPhoneNumber
            }
            return limitText(cleanedPhoneNumber, limit: 12)
        }
    
    // Функция валидации для профиля водителя
    static func validateDriverProfile(firstName: String, lastName: String, licenseNumber: String, phoneNumber: String) -> [String: String] {
        var errors: [String: String] = [:]
        
        if !isNotEmpty(firstName) || !isValidName(firstName) {
            errors["firstName"] = "Имя должно содержать только буквы и быть не длиннее 50 символов."
        }
        
        if !isNotEmpty(lastName) || !isValidName(lastName) {
            errors["lastName"] = "Фамилия должна содержать только буквы и быть не длиннее 50 символов."
        }
        
        if !isNotEmpty(licenseNumber) || !isValidLicenseNumber(licenseNumber) {
            errors["licenseNumber"] = "Номер водительского удостоверения должен содержать 10 цифр."
        }
        
        if !isValidPhoneNumber(phoneNumber) {
            errors["phoneNumber"] = "Номер телефона должен начинаться с +7 и содержать 12 символов."
        }
        
        return errors
    }
    
    // Функция валидации для профиля администратора
    static func validateAdminProfile(nameOrganisation: String, addressOrganisation: String, innOrganisation: String, phoneNumber: String) -> [String: String] {
        var errors: [String: String] = [:]
        
        if !isNotEmpty(nameOrganisation) {
            errors["nameOrganisation"] = "Название организации не может быть пустым."
        }
        
        if !isNotEmpty(addressOrganisation) {
            errors["addressOrganisation"] = "Адрес организации не может быть пустым."
        }
        
        if !isNotEmpty(innOrganisation) || !isValidInn(innOrganisation) {
            errors["innOrganisation"] = "ИНН должен содержать 10 или 12 цифр."
        }
        
        if !isValidPhoneNumber(phoneNumber) {
            errors["phoneNumber"] = "Номер телефона должен начинаться с +7 и содержать 12 символов."
        }
        
        return errors
    }
    
    // Проверка корректности ИНН организации
    static func isValidInn(_ inn: String) -> Bool {
        let innRegex = "^\\d{10}|\\d{12}$"
        let innPredicate = NSPredicate(format: "SELF MATCHES %@", innRegex)
        return innPredicate.evaluate(with: inn)
    }
}
