import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = AuthViewModel()

    var body: some View {
        NavigationView {
            if viewModel.isLogged {
                if let selectedView = viewModel.selectedView {
                    selectedView
                } else {
                    Text("Ошибка: Неизвестная роль пользователя")
                        .foregroundColor(.red)
                        .padding()
                }
            } else {
                VStack(spacing: 20) {
                    Text("Добро пожаловать!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.bottom, 20)

                    TextField("Почта", text: $viewModel.email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)

                    SecureField("Пароль", text: $viewModel.password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)

                    Button(action: {
                        viewModel.signIn()
                    }) {
                        Text("Вход")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)

                    // Убедитесь, что RegisterView не принимает параметров
                    NavigationLink(destination: RegisterView()) {
                        Text("Регистрация")
                            .font(.headline)
                            .foregroundColor(.blue)
                    }
                    .padding(.top, 10)

                    Button(action: {
                        viewModel.showResetPassword = true
                    }) {
                        Text("Забыли пароль?")
                            .font(.headline)
                            .foregroundColor(.blue)
                            .padding(.top, 5)
                    }

                    NavigationLink(destination: ResetPasswordView(), isActive: $viewModel.showResetPassword) {
                        EmptyView()
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Logistic")
        .onAppear {
            viewModel.checkIfLogged()
        }
    }
}
