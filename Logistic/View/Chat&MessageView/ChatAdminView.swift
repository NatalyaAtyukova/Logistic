import SwiftUI
import Firebase
import FirebaseFirestore

struct ChatAdminView: View {
    @State private var activeChats: [ChatInfo] = []
    @State private var completedChats: [ChatInfo] = []
    @State private var selectedChat: ChatInfo?
    @State private var isChatViewPresented = false

    @StateObject private var alertManager = AlertManager()

    let db = Firestore.firestore()
    let currentUser = Auth.auth().currentUser

    var body: some View {
        NavigationView {
            VStack {
                if activeChats.isEmpty && completedChats.isEmpty {
                    Text("Нет доступных чатов.")
                        .padding()
                        .foregroundColor(.gray)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            Section(header: Text("Активные чаты")) {
                                ForEach(activeChats, id: \.id) { chat in
                                    ChatCard(chat: chat)
                                        .onTapGesture {
                                            withAnimation {
                                                selectedChat = chat
                                                isChatViewPresented = true
                                            }
                                        }
                                        .frame(maxWidth: .infinity)
                                }
                            }
                            
                            Section(header: Text("Завершенные чаты")) {
                                ForEach(completedChats, id: \.id) { chat in
                                    ChatCard(chat: chat)
                                        .onTapGesture {
                                            withAnimation {
                                                selectedChat = chat
                                                isChatViewPresented = true
                                            }
                                        }
                                        .frame(maxWidth: .infinity)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Чаты администратора")
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
        }
        .sheet(isPresented: $isChatViewPresented) {
            if let selectedChat = selectedChat {
                ChatView(chatInfo: selectedChat)
            }
        }
        .onAppear {
            loadChats()
            startListeningForNewOrders()
        }
    }

    private func loadChats() {
        guard let currentUser = currentUser else {
            alertManager.showError(message: "Пользователь не аутентифицирован.")
            return
        }

        let adminId = currentUser.uid
        print("Загрузка чатов для администратора с ID \(adminId)")

        db.collection("Chats")
            .whereField("participants", arrayContains: adminId)
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    alertManager.showError(message: "Ошибка при получении чатов: \(error.localizedDescription)")
                } else {
                    guard let documents = querySnapshot?.documents else {
                        print("Ошибка: документы пусты")
                        return
                    }

                    let chats = documents.compactMap { document -> ChatInfo? in
                        try? document.data(as: ChatInfo.self)
                    }

                    // Фильтруем чаты по статусу заказа
                    filterChatsByOrderStatus(chats: chats)
                }
            }
    }

    private func filterChatsByOrderStatus(chats: [ChatInfo]) {
        var activeChatsTemp: [ChatInfo] = []
        var completedChatsTemp: [ChatInfo] = []

        let group = DispatchGroup()

        for chat in chats {
            group.enter()
            db.collection("OrdersList")
                .document(chat.orderId)
                .getDocument { documentSnapshot, error in
                    if let document = documentSnapshot, document.exists {
                        let order = try? document.data(as: OrderItem.self)
                        if let order = order {
                            switch order.status {
                            case "Доставлено":
                                completedChatsTemp.append(chat)
                            case "Новый", "В пути":
                                activeChatsTemp.append(chat)
                            default:
                                break
                            }
                        }
                    }
                    group.leave()
                }
        }

        group.notify(queue: .main) {
            self.activeChats = activeChatsTemp
            self.completedChats = completedChatsTemp
        }
    }

    private func startListeningForNewOrders() {
        guard let currentUser = currentUser else {
            alertManager.showError(message: "Пользователь не аутентифицирован.")
            return
        }

        let adminId = currentUser.uid
        print("Начало прослушивания новых заказов для администратора с ID \(adminId)")

        db.collection("OrdersList")
            .whereField("adminID", isEqualTo: adminId)
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
                           let driverId = orderData["driverID"] as? String {
                            // Проверка наличия чата перед созданием
                            checkAndCreateChat(orderId: orderId, recipientAddress: recipientAddress, senderAddress: senderAddress, driverId: driverId, adminId: adminId)
                        } else {
                            alertManager.showError(message: "Недостаточно данных для заказа")
                        }
                    }
                }
            }
    }

    // Проверка существования чата перед его созданием
    private func checkAndCreateChat(orderId: String, recipientAddress: String, senderAddress: String, driverId: String, adminId: String) {
        db.collection("Chats")
            .whereField("orderId", isEqualTo: orderId)
            .getDocuments { (querySnapshot, error) in
                if let error = error {
                    print("Ошибка при проверке существования чата: \(error.localizedDescription)")
                    return
                }

                // Если чат уже существует, ничего не делаем
                if querySnapshot?.documents.isEmpty == false {
                    print("Чат для заказа \(orderId) уже существует")
                    return
                }

                // Чат не существует — создаем новый
                createNewChat(orderId: orderId, recipientAddress: recipientAddress, senderAddress: senderAddress, driverId: driverId, adminId: adminId)
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
                print("Ошибка при создании чата: \(error.localizedDescription)")
                alertManager.showError(message: "Ошибка при создании документа чата: \(error.localizedDescription)")
                return
            }
            print("Чат успешно создан для заказа \(orderId)")
            loadChats()
        }
    }
}
