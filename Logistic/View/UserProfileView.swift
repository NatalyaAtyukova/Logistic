import SwiftUI
import Firebase
import FirebaseFirestore

struct UserProfileView: View {
    @State private var email: String = ""
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var licenseNumber: String = ""
    @State private var nameOrganisation: String = ""
    @State private var addressOrganisation: String = ""
    @State private var innOrganisation: String = ""
    @State private var phoneNumber: String = ""
    @State private var errorMessage: String? = nil
    @State private var successMessage: String? = nil
    @State private var isEditing: Bool = false
    @State private var errors: [String: String] = [:]

    let userID: String
    let role: String

    var body: some View {
        VStack {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Профиль")
                        .font(.largeTitle)
                        .padding(.bottom, 20)

                    if isEditing {
                        profileEditingView
                    } else {
                        profileViewingView
                    }

                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .padding()
                    }

                    if let successMessage = successMessage {
                        Text(successMessage)
                            .foregroundColor(.green)
                            .padding()
                    }
                }
                .padding(.horizontal)
            }

            // Buttons are fixed at the bottom
            VStack {
                if isEditing {
                    HStack {
                        Button(action: {
                            isEditing.toggle()
                        }) {
                            Text("Отмена")
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.gray)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }

                        Button(action: {
                            saveProfileChanges()
                        }) {
                            Text("Сохранить")
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    .padding()
                } else {
                    Button(action: {
                        isEditing.toggle()
                    }) {
                        Text(isEditing ? "Отмена" : "Редактировать")
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .font(.headline)
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            loadUserProfile()
        }
    }

    var profileEditingView: some View {
        VStack(alignment: .leading, spacing: 15) {
            profileField(title: "Почта", value: email, editable: false)

            if role == "driver" {
                CustomTextField(
                    title: "Имя",
                    text: $firstName,
                    error: errors["firstName"],
                    limit: 50,
                    onChange: { newValue in
                        firstName = Validation.limitText(newValue, limit: 50)
                        validateFields()
                    }
                )

                CustomTextField(
                    title: "Фамилия",
                    text: $lastName,
                    error: errors["lastName"],
                    limit: 50,
                    onChange: { newValue in
                        lastName = Validation.limitText(newValue, limit: 50)
                        validateFields()
                    }
                )

                CustomTextField(
                    title: "Номер водительского удостоверения",
                    text: $licenseNumber,
                    error: errors["licenseNumber"],
                    limit: 10,
                    keyboardType: .numberPad, onChange: { newValue in
                        licenseNumber = Validation.limitText(newValue, limit: 10)
                        validateFields()
                    }
                )
            } else if role == "admin" {
                CustomTextField(
                    title: "Название организации",
                    text: $nameOrganisation,
                    error: errors["nameOrganisation"],
                    limit: 50,
                    onChange: { newValue in
                        nameOrganisation = Validation.limitText(newValue, limit: 50)
                        validateFields()
                    }
                )

                CustomTextField(
                    title: "Адрес организации",
                    text: $addressOrganisation,
                    error: errors["addressOrganisation"],
                    limit: 100,
                    onChange: { newValue in
                        addressOrganisation = Validation.limitText(newValue, limit: 100)
                        validateFields()
                    }
                )

                CustomTextField(
                    title: "ИНН организации",
                    text: $innOrganisation,
                    error: errors["innOrganisation"],
                    limit: 12,
                    keyboardType: .numberPad, onChange: { newValue in
                        innOrganisation = Validation.limitText(newValue, limit: 12)
                        validateFields()
                    }
                )
            }

            CustomTextField(
                title: "Телефон",
                text: $phoneNumber,
                error: errors["phoneNumber"],
                limit: 12,
                keyboardType: .phonePad, onChange: { newValue in
                    phoneNumber = Validation.formatPhoneNumber(newValue)
                    validateFields()
                }
            )
        }
    }

    var profileViewingView: some View {
        VStack(alignment: .leading, spacing: 15) {
            profileField(title: "Почта", value: email)

            if role == "driver" {
                profileField(title: "Имя", value: firstName)
                profileField(title: "Фамилия", value: lastName)
                profileField(title: "Номер водительского удостоверения", value: licenseNumber)
            } else if role == "admin" {
                profileField(title: "Название организации", value: nameOrganisation)
                profileField(title: "Адрес организации", value: addressOrganisation)
                profileField(title: "ИНН организации", value: innOrganisation)
            }

            profileField(title: "Телефон", value: phoneNumber)
        }
    }

    func profileField(title: String, value: String, editable: Bool = true) -> some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundColor(.black)
                .frame(width: 150, alignment: .leading)
            
            Spacer()
            
            Text(value.isEmpty ? "Не указано" : value)
                .foregroundColor(editable ? .primary : .secondary)
                .multilineTextAlignment(.trailing)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.white))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray, lineWidth: 1)
        )
        .padding(.horizontal)
    }

    func loadUserProfile() {
        let db = Firestore.firestore()
        let userCollection = getUserCollection(role: role)

        db.collection(userCollection).document(userID).getDocument { document, error in
            if let document = document, document.exists {
                let data = document.data()
                self.email = data?["email"] as? String ?? ""
                self.phoneNumber = data?["phoneNumber"] as? String ?? ""

                if role == "driver" {
                    self.firstName = data?["firstName"] as? String ?? ""
                    self.lastName = data?["lastName"] as? String ?? ""
                    self.licenseNumber = data?["licenseNumber"] as? String ?? ""
                } else if role == "admin" {
                    self.nameOrganisation = data?["nameOrganisation"] as? String ?? ""
                    self.addressOrganisation = data?["addressOrganisation"] as? String ?? ""
                    self.innOrganisation = data?["innOrganisation"] as? String ?? ""
                }
            } else {
                errorMessage = "Ошибка загрузки данных пользователя."
            }
        }
    }

    func getUserCollection(role: String) -> String {
        switch role {
        case "admin":
            return "AdminProfiles"
        case "driver":
            return "DriverProfiles"
        default:
            return "UnknownRoleProfiles"
        }
    }

    func validateFields() {
        if role == "driver" {
            errors = Validation.validateDriverProfile(
                firstName: firstName,
                lastName: lastName,
                licenseNumber: licenseNumber,
                phoneNumber: phoneNumber
            )
        } else if role == "admin" {
            errors = Validation.validateAdminProfile(
                nameOrganisation: nameOrganisation,
                addressOrganisation: addressOrganisation,
                innOrganisation: innOrganisation,
                phoneNumber: phoneNumber
            )
        }
        
        errorMessage = errors.isEmpty ? nil : "Проверьте корректность введенных данных."
    }

    func saveProfileChanges() {
        validateFields()

        if !errors.isEmpty {
            errorMessage = "Пожалуйста, исправьте ошибки и попробуйте снова."
            return
        }

        let db = Firestore.firestore()
        let userCollection = getUserCollection(role: role)

        var data: [String: Any] = [
            "email": self.email,
            "phoneNumber": Validation.formatPhoneNumber(self.phoneNumber)
        ]

        if role == "driver" {
            data["firstName"] = self.firstName
            data["lastName"] = self.lastName
            data["licenseNumber"] = self.licenseNumber
        } else if role == "admin" {
            data["nameOrganisation"] = self.nameOrganisation
            data["addressOrganisation"] = self.addressOrganisation
            data["innOrganisation"] = self.innOrganisation
        }

        db.collection(userCollection).document(userID).setData(data) { error in
            if let error = error {
                errorMessage = "Ошибка при сохранении: \(error.localizedDescription)"
            } else {
                successMessage = "Изменения успешно сохранены."
                isEditing = false
            }
        }
    }
}


struct CustomTextField: View {
    let title: String
    @Binding var text: String
    let error: String?
    let limit: Int
    let keyboardType: UIKeyboardType
    let onChange: (String) -> Void

    init(
        title: String,
        text: Binding<String>,
        error: String?,
        limit: Int,
        keyboardType: UIKeyboardType = .default,
        onChange: @escaping (String) -> Void
    ) {
        self.title = title
        _text = text
        self.error = error
        self.limit = limit
        self.keyboardType = keyboardType
        self.onChange = onChange
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline)
                .foregroundColor(.black)
                .padding(.bottom, 2)
            
            TextField(title, text: $text, onEditingChanged: { _ in }, onCommit: {})
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.vertical, 5)
                .keyboardType(keyboardType)
                .onChange(of: text) { newValue in
                    text = Validation.limitText(newValue, limit: limit)
                    onChange(text)
                }
                .background(Color.white)
                .cornerRadius(5)
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(error != nil ? Color.red : Color.gray, lineWidth: 1)
                )
            
            if let error = error {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
        .padding(.horizontal)
    }
}
