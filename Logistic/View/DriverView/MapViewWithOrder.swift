import SwiftUI
import MapKit

struct MapViewWithOrder: View {
    var order: OrderItem
    @Binding var isPresented: Bool
    @Binding var region: MKCoordinateRegion // Binding для передачи региона

    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Spacer()

                    Button(action: {
                        isPresented = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                            .imageScale(.large)
                            .padding()
                    }
                }

                VStack(alignment: .leading) {
                    Text("Откуда: \(order.senderAddress)")
                        .font(.headline)
                        .padding(.bottom, 2)
                    Text("Куда: \(order.recipientAddress)")
                        .font(.subheadline)
                        .padding(.bottom, 10)
                }
                .padding(.horizontal)

                // MapViewWithRoute, передаем Binding для region
                MapViewWithRoute(order: order, region: $region)
                    .edgesIgnoringSafeArea(.bottom)
            }
            .navigationBarHidden(true)
        }
    }
}
