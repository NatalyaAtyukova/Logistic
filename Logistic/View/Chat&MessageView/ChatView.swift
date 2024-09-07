import SwiftUI
import Firebase
import UserNotifications

// Окошко самого чата
struct ChatView: View {
    var chatInfo: ChatInfo
    @State private var messageText: String = ""
    @State private var messages: [Message] = []
    let db = Firestore.firestore()
    @Environment(\.presentationMode) var presentationMode
    @State private var textEditorHeight: CGFloat = 80 // Увеличенная начальная высота для TextEditor
    
    var body: some View {
        VStack {
            // Header
            HStack {
                Button(action: {
                    self.presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.blue)
                        .font(.title2)
                }
                .padding(.leading)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Чат для заказа #: \(chatInfo.orderId)")
                        .font(.headline)
                        .fontWeight(.bold)
                    Text("Получатель: \(chatInfo.recipientAddress)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text("Отправитель: \(chatInfo.senderAddress)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding()
                
                Spacer()
            }
            .background(Color(UIColor.systemBackground))
            
            // Messages List
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(messages) { message in
                        MessageView(message: message)
                            .frame(maxWidth: .infinity, alignment: message.senderId == Auth.auth().currentUser?.uid ? .trailing : .leading)
                            .padding(.horizontal)
                    }
                }
                .padding(.bottom, textEditorHeight + 20) // Make room for the message input field
            }
            
            // Input Field
            HStack(alignment: .bottom) {
                TextEditor(text: $messageText)
                    .padding(12)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(8) // Сделаем обводку менее выраженной
                    .frame(minHeight: textEditorHeight, maxHeight: textEditorHeight) // Высота TextEditor
                    .fixedSize(horizontal: false, vertical: true) // Allow height to expand
                    .background(
                        GeometryReader { geo in
                            Color.clear
                                .onChange(of: geo.size.height) { newHeight in
                                    // Обновляем высоту TextEditor только если она увеличивается
                                    if newHeight > textEditorHeight {
                                        textEditorHeight = newHeight
                                    }
                                }
                        }
                    )
                
                Button(action: {
                    sendMessage(messageText: self.messageText, chatId: chatInfo.id)
                }) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .clipShape(Circle())
                }
                .padding(.leading, 8)
            }
            .padding(.horizontal)
            .padding(.bottom, 10)
        }
        .navigationBarTitle("", displayMode: .inline)
        .onAppear {
            loadMessages(forChat: chatInfo.id)
            requestNotificationPermission()
        }
    }
    
    func loadMessages(forChat chatId: String) {
        db.collection("Chats").document(chatId).collection("messages")
            .order(by: "timestamp")
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    print("Ошибка получения сообщений: \(error)")
                    return
                }
                
                guard let documents = querySnapshot?.documents else {
                    print("Нет сообщений")
                    return
                }
                
                let messagesForChat: [Message] = documents.compactMap { document in
                    let data = document.data()
                    guard let text = data["text"] as? String,
                          let senderId = data["senderId"] as? String,
                          let timestamp = data["timestamp"] as? Timestamp else {
                        return nil
                    }
                    
                    let message = Message(id: document.documentID, text: text, senderId: senderId, timestamp: timestamp.dateValue(), chatId: chatId)
                    
                    // Отправляем локальное уведомление для нового сообщения, если отправитель не текущий пользователь
                    sendLocalNotification(for: message)
                    
                    return message
                }
                
                self.messages = messagesForChat
            }
    }
    
    func sendMessage(messageText: String, chatId: String) {
        guard let currentUser = Auth.auth().currentUser else {
            print("Пользователь не аутентифицирован")
            return
        }
        
        let senderId = currentUser.uid
        let timestamp = Timestamp()
        
        db.collection("Chats").document(chatId).collection("messages").addDocument(data: [
            "senderId": senderId,
            "text": messageText,
            "timestamp": timestamp
        ]) { error in
            if let error = error {
                print("Ошибка при отправке сообщения: \(error)")
            } else {
                print("Сообщение отправлено")
                self.messageText = ""
            }
        }
    }
    
    // Функция для отправки локального уведомления
    func sendLocalNotification(for message: Message) {
        guard message.senderId != Auth.auth().currentUser?.uid else {
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "Новое сообщение"
        content.body = message.text
        content.sound = UNNotificationSound.default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Ошибка отправки локального уведомления: \(error.localizedDescription)")
            }
        }
    }
    
    // Запрос на разрешение отправки уведомлений
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Ошибка запроса разрешений на уведомления: \(error.localizedDescription)")
            } else if granted {
                print("Разрешения на уведомления получены")
            } else {
                print("Разрешения на уведомления не предоставлены")
            }
        }
    }
}
