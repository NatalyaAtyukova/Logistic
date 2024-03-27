
import SwiftUI

struct AdminView: View {
    @State private var nameOrganisation: String = ""
    @State private var adressOrganisation: String = ""
    
    
    var body: some View {
        VStack {
            
            TextField("Наименование организации", text: $nameOrganisation)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            TextField("Адрес", text: $adressOrganisation)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            
            Button("Сохранить профиль") {
                // Add logic to save profile here
            }
            .padding()
            
        }
    }
}
            
            
            struct AdminView_Previews: PreviewProvider {
                static var previews: some View {
                    AdminView()
                }
            }
    
