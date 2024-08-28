import SwiftUI
import Firebase
import MapKit
import CoreLocation
import FirebaseFirestore


struct OrderRow: View {
    var order: OrderItem
    var onSelect: () -> Void
    var onActions: () -> Void

    var body: some View {
        VStack(alignment: .leading) {
            Text("Откуда: \(order.senderAddress)")
                .font(.headline)
            Text("Куда: \(order.recipientAddress)")
                .font(.subheadline)
            Text("Компания-получатель: \(order.recipientCompany)")
            Text("Тип груза: \(order.cargoType)")
            Text("Информация о заказе: \(order.orderInfo)")
            Text("Вес груза: \(order.cargoWeight)")
            Text("Крайний срок доставки: \(formatDate(order.deliveryDeadline))")

            HStack {
                Button(action: {
                    onSelect()
                }) {
                    Text("Посмотреть на карте")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())

                Button(action: {
                    onActions()
                }) {
                    Text("Действия")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 10).stroke(Color.gray, lineWidth: 1))
        .padding([.top, .horizontal])
    }
}
