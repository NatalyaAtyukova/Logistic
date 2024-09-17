//
//  FirebaseModel.swift
//  Logistic
//
//  Created by Наталья Атюкова on 07.07.2024.
//

import SwiftUI
import Firebase
import FirebaseFirestore
import MapKit
import CoreLocation



struct OrderItem: Identifiable, Codable {
    var id: String
    var adminID: String
    var cargoType: String
    var cargoWeight: String
    var deliveryDeadline: Date
    var driverName: String
    var orderInfo: String
    var recipientAddress: String
    var recipientCompany: String
    var recipientLatitude: Double
    var recipientLongitude: Double
    var senderAddress: String
    var senderLatitude: Double
    var senderLongitude: Double
    var status: String
    
}

// Структура для представления сообщения в чате
struct Message: Identifiable, Codable {
    let id: String
    let text: String
    let senderId: String
    let timestamp: Date
    let chatId: String
}

// Структура для представления информации о чате
struct ChatInfo: Identifiable, Codable {
    var id: String
    var orderId: String
    var recipientAddress: String
    var senderAddress: String
    var participants: [String]
}


// Структура для представления местоположения водителя
struct DriverLocation: Identifiable, Codable {
    var id: String? // ID документа из Firestore
    var driverID: String // ID водителя
    var latitude: Double
    var longitude: Double
    var timestamp: Timestamp // Поле с типом Firestore.Timestamp
    
    // Форматированный вывод времени из timestamp
    var formattedTimestamp: String {
        formatDate(timestamp.dateValue())
    }

    // Преобразование даты в строку
    private func formatDate(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        return dateFormatter.string(from: date)
    }
    
}
