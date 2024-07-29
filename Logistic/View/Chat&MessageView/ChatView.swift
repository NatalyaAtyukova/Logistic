import SwiftUI
import Firebase

// Окошко самого чата
struct ChatView: View {
    var chatInfo: ChatInfo
    @State private var messageText: String = ""
    @State private var messages: [Message] = []
    let db = Firestore.firestore()
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack {
            HStack {
                Button(action: {
                    self.presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.blue)
                }
                .padding(.leading)
                
                VStack(alignment: .leading) {
                    Text("Chat for Order ID: \(chatInfo.orderId)")
                        .font(.headline)
                    Text("Recipient Address: \(chatInfo.recipientAddress)")
                        .font(.subheadline)
                    Text("Sender Address: \(chatInfo.senderAddress)")
                        .font(.subheadline)
                }
                .padding()
                
                Spacer()
            }
            
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(messages) { message in
                        MessageView(message: message)
                            .frame(maxWidth: .infinity, alignment: message.senderId == Auth.auth().currentUser?.uid ? .trailing : .leading)
                    }
                }
            }
            .padding(.horizontal)
            
            HStack {
                TextField("Enter message", text: $messageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                    .frame(minHeight: 45)
                
                Button(action: {
                    sendMessage(messageText: self.messageText, chatId: chatInfo.id)
                }) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(8)
                }
                .padding(.horizontal)
            }
            .padding(.bottom)
        }
        .navigationBarTitle("", displayMode: .inline)
        .onAppear {
            loadMessages(forChat: chatInfo.id)
        }
    }
    
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
                    
                    return Message(id: document.documentID, text: text, senderId: senderId, timestamp: timestamp.dateValue(), chatId: chatId)
                }
                
                self.messages = messagesForChat
            }
    }
    
    func sendMessage(messageText: String, chatId: String) {
        guard let currentUser = Auth.auth().currentUser else {
            print("User is not authenticated.")
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
                print("Error adding document: \(error)")
            } else {
                print("Message added successfully.")
                self.messageText = ""
            }
        }
    }
}

struct MessageView: View {
    var message: Message
    
    var body: some View {
        HStack {
            if message.senderId == Auth.auth().currentUser?.uid {
                Spacer()
                Text(message.text)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .frame(maxWidth: 250, alignment: .trailing)
            } else {
                Text(message.text)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.black)
                    .cornerRadius(10)
                    .frame(maxWidth: 250, alignment: .leading)
                Spacer()
            }
        }
        .padding(.horizontal)
    }
}
