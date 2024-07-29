import SwiftUI
import Firebase

struct DriverProfileView: View {
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var driverLicense: String = ""
    @State internal var selectedImage: UIImage?
    @State private var profileSaved: Bool = false
    @State private var navigateToDriverTab: Bool = false
    @Environment(\.presentationMode) var presentationMode // Добавляем presentationMode для закрытия представления
    
    var body: some View {
        VStack {
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    .shadow(radius: 5)
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .clipShape(Circle())
                    .frame(width: 100, height: 100)
                    .padding()
            }
            
            TextField("Имя", text: $firstName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            TextField("Фамилия", text: $lastName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            TextField("Номер ВУ", text: $driverLicense)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            Button("Выбрать фото") {
                let picker = UIImagePickerController()
                picker.allowsEditing = false
                picker.sourceType = .photoLibrary
                picker.delegate = makeCoordinator()
                UIApplication.shared.windows.first?.rootViewController?.present(picker, animated: true, completion: nil)
            }
            .padding()
            
            Button("Сохранить профиль") {
                saveProfile()
            }
            .padding()
            
            NavigationLink(destination: DriverTabView(), isActive: $navigateToDriverTab) {
                EmptyView()
            }
            .frame(width: 0, height: 0)
            .hidden()
        }
        .padding()
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }
    
    func saveProfile() {
        let db = Firestore.firestore()
        guard let driverID = Auth.auth().currentUser?.uid else {
            print("Ошибка: Пользователь не аутентифицирован")
            return
        }
        
        let data: [String: Any] = [
            "driverID": driverID,
            "firstName": firstName,
            "lastName": lastName,
            "driverLicense": driverLicense
            // Можно также добавить обработку изображения, если требуется сохранить его
        ]
        
        db.collection("DriverProfiles").document(driverID).setData(data) { error in
            if let error = error {
                print("Ошибка при сохранении профиля: \(error.localizedDescription)")
            } else {
                print("Профиль успешно сохранен")
                profileSaved = true
                navigateToDriverTab = true
                presentationMode.wrappedValue.dismiss() // Закрываем текущее представление
            }
        }
    }
}

class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    var parent: DriverProfileView

    init(parent: DriverProfileView) {
        self.parent = parent
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.originalImage] as? UIImage else { return }
        parent.selectedImage = image

        picker.dismiss(animated: true, completion: nil)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}



struct DriverProfileView_Previews: PreviewProvider {
    static var previews: some View {
        DriverProfileView()
    }
}
