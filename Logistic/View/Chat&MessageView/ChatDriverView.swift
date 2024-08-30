import SwiftUI
import Firebase
import MapKit
import CoreLocation
import FirebaseFirestore

struct ChatDriverView: View {
    @State private var existingChats: [ChatInfo] = []
    @State private var selectedChat: ChatInfo?
    @State private var isChatViewPresented = false
    
    @ObservedObject var alertManager: AlertManager
    
    let db = Firestore.firestore()
    let currentUser = Auth.auth().currentUser
    
    var body: some View {
        NavigationView {
            VStack {
                if existingChats.isEmpty {
                    Text("Нет доступных чатов.")
                        .padding()
                        .foregroundColor(.gray)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(existingChats, id: \.id) { chat in
                                ChatCard(chat: chat)
                                    .onTapGesture {
                                        withAnimation {
                                            selectedChat = chat
                                            isChatViewPresented = true
                                        }
                                    }
                                    .frame(maxWidth: .infinity)  // Задаем максимальную ширину для каждого элемента
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Чат водителя")
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
        }
        .sheet(isPresented: $isChatViewPresented) {
            if let selectedChat = selectedChat {
                ChatView(chatInfo: selectedChat)
            }
        }
        .onAppear {
            loadExistingChats()
            startListeningForNewOrders()
        }
    }
    
    
    private func createNewChat(orderId: String, recipientAddress: String, senderAddress: String, driverId: String, adminId: String) {
        print("Создание нового чата для заказа \(orderId)")
        let chatId = UUID().uuidString.uppercased()
        let chatData: [String: Any] = [
            "id": chatId,
            "orderId": orderId,
            "recipientAddress": recipientAddress,
            "senderAddress": senderAddress,
            "participants": [adminId, driverId]
        ]
        
        db.collection("Chats").document(chatId).setData(chatData) { error in
            if let error = error {
                print("Ошибка при создании документа чата: \(error.localizedDescription)")
                alertManager.showError(message: "Ошибка при создании документа чата: \(error.localizedDescription)")
                return
            }
            print("Чат успешно создан для заказа \(orderId)")
            loadExistingChats()
        }
    }
    
    private func loadExistingChats() {
        guard let currentUser = currentUser else {
            alertManager.showError(message: "Пользователь не аутентифицирован.")
            return
        }
        
        let driverId = currentUser.uid
        print("Загрузка чатов для водителя с ID \(driverId)")
        
        db.collection("Chats")
            .whereField("participants", arrayContains: driverId)
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    print("Ошибка при получении чатов: \(error.localizedDescription)")
                    alertManager.showError(message: "Ошибка при получении чатов: \(error.localizedDescription)")
                } else {
                    guard let documents = querySnapshot?.documents else {
                        print("Ошибка: документы пусты")
                        return
                    }
                    existingChats = documents.compactMap { document in
                        let data = document.data()
                        guard let orderId = data["orderId"] as? String,
                              let recipientAddress = data["recipientAddress"] as? String,
                              let senderAddress = data["senderAddress"] as? String,
                              let chatId = data["id"] as? String else {
                            return nil
                        }
                        return ChatInfo(id: chatId, orderId: orderId, recipientAddress: recipientAddress, senderAddress: senderAddress, participants: [])
                    }
                }
            }
    }
    
    private func startListeningForNewOrders() {
        guard let currentUser = currentUser else {
            alertManager.showError(message: "Пользователь не аутентифицирован.")
            return
        }
        
        let driverId = currentUser.uid
        print("Начало прослушивания новых заказов для водителя с ID \(driverId)")
        
        db.collection("OrdersList")
            .whereField("driverID", isEqualTo: driverId)
            .whereField("status", isEqualTo: "В пути")
            .addSnapshotListener { querySnapshot, error in
                guard let snapshot = querySnapshot else {
                    alertManager.showError(message: "Ошибка при прослушивании заказов: \(error?.localizedDescription ?? "Неизвестная ошибка")")
                    return
                }
                
                snapshot.documentChanges.forEach { change in
                    if change.type == .added {
                        let orderData = change.document.data()
                        if let orderId = orderData["id"] as? String,
                           let recipientAddress = orderData["recipientAddress"] as? String,
                           let senderAddress = orderData["senderAddress"] as? String,
                           let adminId = orderData["adminID"] as? String {
                            if existingChats.contains(where: { $0.orderId == orderId }) {
                                print("Чат для заказа \(orderId) уже существует")
                            } else {
                                print("Создание нового чата для нового заказа \(orderId)")
                                createNewChat(orderId: orderId, recipientAddress: recipientAddress, senderAddress: senderAddress, driverId: driverId, adminId: adminId)
                            }
                        } else {
                            alertManager.showError(message: "Недостаточно данных для заказа")
                        }
                    }
                }
            }
    }
}
