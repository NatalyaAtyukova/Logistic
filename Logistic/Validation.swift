//
//  Validation.swift
//  Logistic
//
//  Created by Наталья Атюкова on 19.08.2024.
//

import Foundation

struct Validation {
    
    // Валидация email
    static func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    // Валидация пароля (например, минимум 6 символов)
    static func isValidPassword(_ password: String) -> Bool {
        return password.count >= 6
    }
    
    // Валидация номера телефона (+7 и не более 12 символов)
    static func isValidPhoneNumber(_ phoneNumber: String) -> Bool {
        let phoneRegex = "^\\+7\\d{10}$" // Формат номера: +7 и 10 цифр
        let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        return phonePredicate.evaluate(with: phoneNumber) && phoneNumber.count == 12
    }
    
    // Ограничение длины текста (например, для номера телефона)
    static func limitText(_ text: String, limit: Int) -> String {
        return String(text.prefix(limit))
    }

    // Валидация имени и фамилии (только русские буквы)
    static func isValidName(_ name: String) -> Bool {
        let nameRegex = "^[А-Яа-яЁё\\s-]+$" // Разрешены только русские буквы, пробелы и дефисы
        let namePredicate = NSPredicate(format: "SELF MATCHES %@", nameRegex)
        return namePredicate.evaluate(with: name)
    }
    
    // Валидация ИНН (10 цифр)
    static func isValidINN(_ inn: String) -> Bool {
        let innRegex = "^\\d{10}$" // ИНН состоит из 10 цифр
        let innPredicate = NSPredicate(format: "SELF MATCHES %@", innRegex)
        return innPredicate.evaluate(with: inn)
    }

    // Проверка на пустоту
    static func isNotEmpty(_ text: String) -> Bool {
        return !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // Форматирование и добавление +7 к номеру телефона
    static func formatPhoneNumber(_ phoneNumber: String) -> String {
        var cleanedPhoneNumber = phoneNumber
        if cleanedPhoneNumber.starts(with: "8") {
            cleanedPhoneNumber = String(cleanedPhoneNumber.dropFirst())
        }
        if !cleanedPhoneNumber.starts(with: "+7") {
            cleanedPhoneNumber = "+7" + cleanedPhoneNumber
        }
        return limitText(cleanedPhoneNumber, limit: 12) // Ограничиваем до 12 символов
    }
}
