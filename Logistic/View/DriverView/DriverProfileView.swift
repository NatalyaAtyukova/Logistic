import SwiftUI

struct DriverProfileView: View {
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var driverLiscense: String = ""
    @State internal var selectedImage: UIImage?
    
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
                
            
// не загружается в circle доделать
            
            TextField("Имя", text: $firstName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            TextField("Фамилия", text: $lastName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            TextField("Номер ВУ", text: $driverLiscense)
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

            NavigationLink(destination: DriverTabView()) {
                Text("Сохранить профиль")
            }
            .padding()
        }
        .padding()
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.originalImage] as? UIImage else { return }
        selectedImage = image

        picker.dismiss(animated: true, completion: nil)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
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
