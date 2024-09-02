import SwiftUI
import Firebase
import FirebaseFirestore

struct ChatDriverView: View {
    @State private var activeChats: [ChatInfo] = []
    @State private var completedChats: [ChatInfo] = []
    @State private var selectedChat: ChatInfo?
    @State private var isChatViewPresented = false
    
    @ObservedObject var alertManager: AlertManager
    
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
            .navigationTitle("Чат водителя")
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

        let driverId = currentUser.uid

        db.collection("Chats")
            .whereField("participants", arrayContains: driverId)
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

        let driverId = currentUser.uid

        db.collection("OrdersList")
            .whereField("driverID", isEqualTo: driverId)
            .addSnapshotListener { querySnapshot, error in
                guard let snapshot = querySnapshot else {
                    alertManager.showError(message: "Ошибка при прослушивании заказов: \(error?.localizedDescription ?? "Неизвестная ошибка")")
                    return
                }

                snapshot.documentChanges.forEach { change in
                    if change.type == .added {
                        guard let order = try? change.document.data(as: OrderItem.self) else {
                            alertManager.showError(message: "Ошибка при получении данных заказа")
                            return
                        }

                        // Проверяем наличие чата для данного заказа
                        if !self.activeChats.contains(where: { $0.orderId == order.id }) {
                            checkAndCreateChatForOrder(order: order)
                        }
                    }
                }
            }
    }

    private func checkAndCreateChatForOrder(order: OrderItem) {
        db.collection("Chats")
            .whereField("orderId", isEqualTo: order.id)
            .getDocuments { (querySnapshot, error) in
                if let error = error {
                    print("Ошибка при проверке существования чата: \(error.localizedDescription)")
                    return
                }

                // Если чат для заказа не найден, создаем новый
                if querySnapshot?.documents.isEmpty == true {
                    createNewChat(orderId: order.id, recipientAddress: order.recipientAddress, senderAddress: order.senderAddress, participants: [order.adminID, currentUser?.uid ?? ""])
                }
            }
    }

    private func createNewChat(orderId: String, recipientAddress: String, senderAddress: String, participants: [String]) {
        let newChatId = UUID().uuidString
        let newChat = ChatInfo(id: newChatId, orderId: orderId, recipientAddress: recipientAddress, senderAddress: senderAddress, participants: participants)
        
        do {
            try db.collection("Chats").document(newChatId).setData(from: newChat) { error in
                if let error = error {
                    print("Ошибка при создании чата: \(error.localizedDescription)")
                    return
                }
                // Обновляем чаты после успешного создания
                loadChats()
            }
        } catch {
            print("Ошибка при сохранении данных чата: \(error.localizedDescription)")
        }
    }
}
