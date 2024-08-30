import SwiftUI
import Firebase
import FirebaseFirestore

struct ChatAdminView: View {
    @State private var activeChats: [ChatInfo] = [] // Чаты по активным заказам
    @State private var completedChats: [ChatInfo] = [] // Чаты по завершенным заказам
    @State private var selectedChat: ChatInfo?
    @State private var isChatViewPresented = false
    let db = Firestore.firestore()
    let currentUser = Auth.auth().currentUser
    @StateObject private var alertManager = AlertManager()

    var body: some View {
        NavigationView {
            VStack {
                if activeChats.isEmpty {
                    Text("Нет доступных чатов по активным заказам.")
                        .padding()
                        .foregroundColor(.gray)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(activeChats, id: \.id) { chat in
                                ChatCard(chat: chat)
                                    .onTapGesture {
                                        withAnimation {
                                            selectedChat = chat
                                            isChatViewPresented = true
                                        }
                                    }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Чат организации")
            .navigationBarItems(trailing: NavigationLink("Завершенные заказы", destination: CompletedOrdersView(chats: completedChats, onChatSelect: { chat in
                self.selectedChat = chat
                self.isChatViewPresented = true
            })))
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

    private func loadExistingChats() {
        guard let currentUser = currentUser else {
            alertManager.showError(message: "Пользователь не аутентифицирован.")
            return
        }
        
        let adminId = currentUser.uid

        db.collection("Chats")
            .whereField("participants", arrayContains: adminId)
            .getDocuments { (querySnapshot, error) in
                if let error = error {
                    alertManager.showError(message: "Ошибка при получении чатов: \(error.localizedDescription)")
                } else {
                    let chats = querySnapshot?.documents.compactMap { document in
                        try? document.data(as: ChatInfo.self)
                    } ?? []
                    
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
                            if order.status == "Доставлено" {
                                completedChatsTemp.append(chat) // Чат по завершенному заказу
                            } else if order.status == "Новый" || order.status == "В пути" {
                                activeChatsTemp.append(chat) // Чат по активному заказу
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

        db.collection("OrdersList")
            .whereField("adminID", isEqualTo: adminId)
            .addSnapshotListener { querySnapshot, error in
                guard let snapshot = querySnapshot else {
                    alertManager.showError(message: "Ошибка при прослушивании заказов: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }

                snapshot.documentChanges.forEach { change in
                    if change.type == .added {
                        guard let order = try? change.document.data(as: OrderItem.self) else {
                            alertManager.showError(message: "Ошибка при получении данных заказа")
                            return
                        }

                        createChatForOrder(order: order)
                    }
                }
            }
    }

    private func createChatForOrder(order: OrderItem) {
        guard let currentUser = currentUser else {
            alertManager.showError(message: "Пользователь не аутентифицирован.")
            return
        }
        
        let adminId = currentUser.uid
        let driverId = order.driverName
        let participants = [adminId, driverId]

        db.collection("Chats")
            .whereField("orderId", isEqualTo: order.id)
            .getDocuments { (querySnapshot, error) in
                if let error = error {
                    alertManager.showError(message: "Ошибка при проверке существования чата: \(error.localizedDescription)")
                    return
                }

                if let documents = querySnapshot?.documents, !documents.isEmpty {
                    alertManager.showError(message: "Чат для заказа \(order.id) уже существует.")
                } else {
                    createNewChat(orderId: order.id, recipientAddress: order.recipientAddress, senderAddress: order.senderAddress, participants: participants)
                }
            }
    }

    private func createNewChat(orderId: String, recipientAddress: String, senderAddress: String, participants: [String]) {
        let newChatId = UUID().uuidString
        let newChat = ChatInfo(id: newChatId, orderId: orderId, recipientAddress: recipientAddress, senderAddress: senderAddress, participants: participants)
        
        do {
            try db.collection("Chats").document(newChatId).setData(from: newChat) { error in
                if let error = error {
                    alertManager.showError(message: "Ошибка при создании документа чата: \(error.localizedDescription)")
                    return
                }
                // Обновляем список чатов после успешного создания
                loadExistingChats()
            }
        } catch {
            alertManager.showError(message: "Ошибка при сохранении документа чата: \(error.localizedDescription)")
        }
    }
}

