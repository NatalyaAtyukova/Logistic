import SwiftUI

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
