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
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.gray)
            
            ZStack(alignment: .leading) {
                if text.isEmpty {
                    Text(title)
                        .foregroundColor(.gray.opacity(0.5))
                        .padding(.horizontal, 8)
                }
                
                TextField("", text: $text)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 10)
                    .background(Color.clear)
                    .overlay(
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(error != nil ? .red : .gray)
                            .padding(.top, 35) // Отодвигаем линию вниз
                    )
                    .keyboardType(keyboardType)
                    .onChange(of: text) { newValue in
                        text = Validation.limitText(newValue, limit: limit)
                        onChange(text)
                    }
            }
            
            if let error = error {
                Text(error)
                    .font(.system(size: 12))
                    .foregroundColor(.red)
                    .padding(.top, 4)
            }
        }
        .padding(.horizontal)
    }
}
