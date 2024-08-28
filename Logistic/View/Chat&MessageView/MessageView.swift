import Foundation
import SwiftUI
import Firebase

struct MessageView: View {
    var message: Message
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if message.senderId != Auth.auth().currentUser?.uid {
                // Аватар отправителя
                Image(systemName: "person.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .background(Color.gray.opacity(0.2))
                    .clipShape(Circle())
                    .padding(.leading)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(message.text)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .foregroundColor(.black)
                        .cornerRadius(12)
                        .frame(maxWidth: 250, alignment: .leading)
                    
                    Text(message.timestamp, style: .time)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.leading, 10)
                }
                .padding(.trailing)
                
                Spacer()
            } else {
                Spacer()
                
                VStack(alignment: .trailing, spacing: 6) {
                    Text(message.text)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .frame(maxWidth: 250, alignment: .trailing)
                    
                    Text(message.timestamp, style: .time)
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.trailing, 10)
                }
                .padding(.leading)
                
                // Аватар текущего пользователя (или его иконка)
                Image(systemName: "person.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .background(Color.blue.opacity(0.2))
                    .clipShape(Circle())
                    .padding(.trailing)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
    }
}

