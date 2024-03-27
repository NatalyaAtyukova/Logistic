import SwiftUI
import Firebase

// окошко самого чата
struct ChatView: View {
    var chatInfo: ChatInfo
    @State private var messageText: String = ""
    @State private var messages: [Message] = []
    let db = Firestore.firestore()
    
    var body: some View {
        VStack {
            Text("Chat for Order Number: \(chatInfo.orderId)")
                .padding()
            
            Text("Recipient City: \(chatInfo.recipientCity)")
                .padding()
            
            Text("Recipient Company: \(chatInfo.recipientCompany)")
                .padding()
            
            Text("Sender City: \(chatInfo.senderCity)")
                .padding()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(messages) { message in
                        MessageView(message: message)
                    }
                }
            }
            .padding(.horizontal)
            
            HStack {
                TextField("Enter message", text: $messageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                Button(action: {
                    sendMessage(messageText: self.messageText, orderId: chatInfo.orderId)
                }) {
                    Text("Send")
                }
                .padding(.horizontal)
            }
            .padding(.bottom)
        }
        .navigationBarTitle("", displayMode: .inline)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading:
                                Button(action: {
            // Add logic here to close the chat
        }) {
            Image(systemName: "chevron.left")
                .foregroundColor(.blue)
        }
        )
        .onAppear {
            loadMessages(forChat: chatInfo.chatId)
        
        }
    }
    
   
    // Функция для загрузки сообщений для конкретного чата с использованием слушателя  //senderID получать надо ли
    func loadMessages(forChat chatId: String) {
        db.collection("Chats").document(chatId).collection("messages")
            .order(by: "timestamp")
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    print("Error fetching messages: \(error)")
                    return
                }
                
                guard let documents = querySnapshot?.documents else {
                    print("No messages")
                    return
                }
                
                let messagesForChat: [Message] = documents.compactMap { document in
                    let data = document.data()
                    guard let text = data["text"] as? String,
                          let senderId = data["senderId"] as? String,
                          let timestamp = data["timestamp"] as? Timestamp else {
                        return nil
                    }
                    
                    return Message(id: document.documentID, text: text, senderId: senderId, timestamp: timestamp.dateValue())
                }
                
                // Обновляем массив сообщений
                self.messages = messagesForChat
            }
    }

    
    func sendMessage(messageText: String, orderId: String) {
        guard let currentUser = Auth.auth().currentUser else {
            print("User is not authenticated.")
            return
        }
        
        let senderId = currentUser.uid
        let timestamp = Timestamp()
        
        db.collection("Chats")
            .whereField("orderId", isEqualTo: orderId)
            .getDocuments { (querySnapshot, error) in
                if let error = error {
                    print("Error getting documents: \(error)")
                } else {
                    guard let document = querySnapshot?.documents.first else {
                        print("Chat document not found.")
                        return
                    }
                    
                    let chatId = document.documentID
                    
                    // Отправляем сообщение в подколлекцию messages этого чата
                    db.collection("Chats")
                        .document(chatId)
                        .collection("messages")
                        .addDocument(data: [
                            "senderId": senderId,
                            "text": messageText,
                            "timestamp": timestamp
                        ]) { error in
                            if let error = error {
                                print("Error adding document: \(error)")
                            } else {
                                print("Message added successfully.")
                                
                                // Очистить текстовое поле после отправки сообщения
                                self.messageText = ""
                            }
                        }
                }
            }
    }
    
}
