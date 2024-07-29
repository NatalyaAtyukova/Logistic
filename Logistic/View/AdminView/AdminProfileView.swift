import SwiftUI
import Firebase

struct AdminProfileView: View {
    @State private var nameOrganisation: String = ""
    @State private var adressOrganisation: String = ""
    @State private var innOrganisation: String = ""
    @State private var profileSaved: Bool = false
    @State private var navigateToAdminTab: Bool = false
    @Environment(\.presentationMode) var presentationMode // Добавляем presentationMode для закрытия представления
    
    var body: some View {
        VStack {
            TextField("Наименование организации", text: $nameOrganisation)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            TextField("ИНН", text: $innOrganisation)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            TextField("Адрес", text: $adressOrganisation)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            Button(action: {
                saveProfile()
            }) {
                Text("Сохранить профиль")
            }
            .padding()
            
            NavigationLink(destination: AdminTabView(), isActive: $navigateToAdminTab) {
                EmptyView()
            }
            .frame(width: 0, height: 0)
            .hidden()
        }
    }
    
    func saveProfile() {
        let db = Firestore.firestore()
        
        // Получаем UID текущего пользователя
        guard let adminID = Auth.auth().currentUser?.uid else {
            print("Ошибка: Пользователь не аутентифицирован")
            return
        }
        
        // Данные профиля
        let data: [String: Any] = [
            "adminID": adminID, // Сохраняем UID пользователя
            "nameOrganisation": nameOrganisation,
            "innOrganisation": innOrganisation,
            "adressOrganisation": adressOrganisation
        ]
        
        // Сохраняем данные профиля в базу данных
        db.collection("AdminProfiles").document(adminID).setData(data) { error in
            if let error = error {
                print("Ошибка при сохранении профиля: \(error.localizedDescription)")
            } else {
                print("Профиль успешно сохранен")
                profileSaved = true
                navigateToAdminTab = true
                presentationMode.wrappedValue.dismiss() // Закрываем текущее представление
            }
        }
    }
}



            
            struct AdminProfileView_Previews: PreviewProvider {
                static var previews: some View {
                    AdminProfileView()
                }
            }
    
