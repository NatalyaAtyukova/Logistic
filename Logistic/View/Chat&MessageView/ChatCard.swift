//
//  ChatCard.swift
//  Logistic
//
//  Created by Наталья Атюкова on 27.08.2024.
//

import Foundation
import SwiftUI

// Карточка для чатов с улучшенной визуализацией
struct ChatCard: View {
    let chat: ChatInfo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center) {
                // Используем иконку машины вместо корзинки
                Image(systemName: "message.fill")
                    .foregroundColor(.green)
                    .padding(8)
                    .background(Color(.systemGreen).opacity(0.1))
                    .clipShape(Circle())
                
                VStack(alignment: .leading) {
                    Text("Заказ #\(chat.orderId)")
                        .font(.headline)
                    Text("Получатель: \(chat.recipientAddress)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text("Отправитель: \(chat.senderAddress)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)  // Гарантируем, что HStack растягивается по ширине
            .padding()
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
        .frame(maxWidth: .infinity)  // Гарантируем, что карточка растягивается по ширине
    }
}
