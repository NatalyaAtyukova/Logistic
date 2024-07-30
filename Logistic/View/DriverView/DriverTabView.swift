import SwiftUI
import Firebase
import MapKit
import CoreLocation
import FirebaseFirestore


//driverID

struct DriverTabView: View {
    @StateObject private var alertManager = AlertManager()
    @StateObject private var locationManager = LocationManager()
    @State private var orders: [OrderItem] = []
    @State private var driverLocations: [DriverLocation] = []

    var body: some View {
        TabView {
            FindOrderView(alertManager: alertManager)
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("Список моих заказов")
                }
            ActiveOrders(alertManager: alertManager, orders: $orders, driverLocations: $driverLocations, locationManager: locationManager)
                .tabItem {
                    Image(systemName: "doc.text")
                    Text("Заказы в работе и карта")
                }
            ChatDriverView(alertManager: alertManager)
                .tabItem {
                    Image(systemName: "message")
                    Text("Чат")
                }
        }
        .navigationBarTitle("Панель водителя")
        .onAppear {
            locationManager.requestLocationPermission()
            locationManager.startUpdatingLocation()
            fetchDriverLocations()
        }
    }

    func fetchDriverLocations() {
        let db = Firestore.firestore()
        db.collection("DriverLocations").addSnapshotListener { (snapshot, error) in
            if let error = error {
                print("Error fetching driver locations: \(error.localizedDescription)")
                return
            }

            var fetchedDriverLocations: [DriverLocation] = []

            for document in snapshot!.documents {
                let data = document.data()
                if let driverID = data["driverID"] as? String,
                   let latitude = data["latitude"] as? Double,
                   let longitude = data["longitude"] as? Double,
                   let timestamp = data["timestamp"] as? Timestamp {

                    let location = DriverLocation(id: document.documentID, driverID: driverID, latitude: latitude, longitude: longitude, timestamp: timestamp)
                    fetchedDriverLocations.append(location)
                }
            }

            DispatchQueue.main.async {
                self.driverLocations = fetchedDriverLocations
            }
        }
    }
}
import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct FindOrderView: View {
    @State private var senderCity: String = ""
    @State private var recipientCity: String = ""
    @State private var orders: [OrderItem] = []
    @State private var isShowingOrdersList = false
    @State private var senderCitySuggestions: [String] = []
    @State private var recipientCitySuggestions: [String] = []
    @State private var isShowingSenderCitySuggestions = false
    @State private var isShowingRecipientCitySuggestions = false
    
    @ObservedObject var alertManager: AlertManager
    var currentUser = Auth.auth().currentUser
    
    var body: some View {
        NavigationView {
            VStack {
                CityAutocompleteTextField(
                    title: "Город отправления или область",
                    city: $senderCity,
                    suggestions: $senderCitySuggestions,
                    isShowingSuggestions: $isShowingSenderCitySuggestions,
                    onCitySelected: { selectedCity in
                        self.senderCity = selectedCity
                        self.isShowingSenderCitySuggestions = false
                        fetchRecipientCitySuggestions(for: selectedCity)
                    }
                )
                
                CityAutocompleteTextField(
                    title: "Город назначения или область",
                    city: $recipientCity,
                    suggestions: $recipientCitySuggestions,
                    isShowingSuggestions: $isShowingRecipientCitySuggestions,
                    onCitySelected: { selectedCity in
                        self.recipientCity = selectedCity
                        self.isShowingRecipientCitySuggestions = false
                    }
                )
                
                Button(action: {
                    searchOrders()
                }) {
                    Text("Найти заказы")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(15)
                }
                
                if let currentUser = currentUser {
                    NavigationLink(destination: FindListView(alertManager: alertManager, currentUser: currentUser, orders: orders), isActive: $isShowingOrdersList) {
                        EmptyView()
                    }
                    .hidden()
                }
            }
            .padding()
            .navigationBarTitle("Поиск заказов")
            .alert(isPresented: $alertManager.showAlert) {
                Alert(title: Text("Сообщение"),
                      message: Text(alertManager.alertMessage),
                      dismissButton: .default(Text("OK")) {
                    alertManager.showAlert = false
                })
            }
            .onAppear {
                fetchSenderCitySuggestions()
            }
        }
    }
    
    private func searchOrders() {
        let db = Firestore.firestore()
        
        print("Searching for orders with senderCity: \(senderCity) and recipientCity: \(recipientCity)")
        
        db.collection("OrdersList")
            .getDocuments { (querySnapshot, error) in
                if let error = error {
                    alertManager.showError(message: "Ошибка при поиске заказов: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = querySnapshot?.documents else {
                    alertManager.showError(message: "Заказы не найдены")
                    return
                }
                
                let orders = documents.compactMap { queryDocumentSnapshot -> OrderItem? in
                    let data = queryDocumentSnapshot.data()
                    
                    guard
                        let id = data["id"] as? String,
                        let adminID = data["adminID"] as? String,
                        let cargoType = data["cargoType"] as? String,
                        let cargoWeight = data["cargoWeight"] as? String,
                        let deliveryDeadlineTimestamp = data["deliveryDeadline"] as? Timestamp,
                        let driverName = data["driverName"] as? String,
                        let orderInfo = data["orderInfo"] as? String,
                        let recipientAddress = data["recipientAddress"] as? String,
                        let recipientCompany = data["recipientCompany"] as? String,
                        let recipientLatitude = data["recipientLatitude"] as? Double,
                        let recipientLongitude = data["recipientLongitude"] as? Double,
                        let senderAddress = data["senderAddress"] as? String,
                        let senderLatitude = data["senderLatitude"] as? Double,
                        let senderLongitude = data["senderLongitude"] as? Double,
                        let status = data["status"] as? String
                    else {
                        return nil
                    }
                    
                    let deliveryDeadline = deliveryDeadlineTimestamp.dateValue()
                    
                    let orderItem = OrderItem(
                        id: id,
                        adminID: adminID,
                        cargoType: cargoType,
                        cargoWeight: cargoWeight,
                        deliveryDeadline: deliveryDeadline,
                        driverName: driverName,
                        orderInfo: orderInfo,
                        recipientAddress: recipientAddress,
                        recipientCompany: recipientCompany,
                        recipientLatitude: recipientLatitude,
                        recipientLongitude: recipientLongitude,
                        senderAddress: senderAddress,
                        senderLatitude: senderLatitude,
                        senderLongitude: senderLongitude,
                        status: status
                    )
                    
                    let senderCityMatches = senderAddress.lowercased().contains(senderCity.lowercased())
                    let recipientCityMatches = recipientAddress.lowercased().contains(recipientCity.lowercased())
                    
                    return senderCityMatches && recipientCityMatches ? orderItem : nil
                }
                
                print("Found \(orders.count) orders matching criteria")
                
                self.orders = orders
                self.isShowingOrdersList = true
            }
    }
    
    private func fetchSenderCitySuggestions() {
        let db = Firestore.firestore()
        
        db.collection("OrdersList").getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error fetching city suggestions: \(error.localizedDescription)")
                return
            }
            
            guard let documents = querySnapshot?.documents else {
                print("No documents found for city suggestions")
                return
            }
            
            let senderCities = Set(documents.compactMap { $0.data()["senderAddress"] as? String }.flatMap { extractCitiesAndRegions(from: $0) })
            
            self.senderCitySuggestions = Array(senderCities)
        }
    }
    
    private func fetchRecipientCitySuggestions(for senderCity: String) {
        let db = Firestore.firestore()
        
        db.collection("OrdersList")
            .getDocuments { (querySnapshot, error) in
                if let error = error {
                    print("Error fetching recipient city suggestions: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = querySnapshot?.documents else {
                    print("No documents found for recipient city suggestions")
                    return
                }
                
                let recipientCities = Set(documents.compactMap { $0.data()["recipientAddress"] as? String }.flatMap { extractCitiesAndRegions(from: $0) })
                
                self.recipientCitySuggestions = Array(recipientCities)
            }
    }
    
    private func extractCitiesAndRegions(from address: String) -> [String] {
        let components = address.split(separator: ",")
        return components.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    }
}



struct FindListView: View {
    @ObservedObject var alertManager: AlertManager
    var currentUser: UserInfo
    var orders: [OrderItem]
    
    var body: some View {
        VStack {
            if orders.isEmpty {
                Text("Заказы не найдены")
                    .foregroundColor(.red)
                    .padding()
            } else {
                List(orders.filter { $0.status == "Новый" }) { order in
                    VStack(alignment: .leading) {
                        Text("Откуда: \(getCityName(from: order.senderAddress))")
                        Text("Куда: \(getCityName(from: order.recipientAddress))")
                        Text("Компания-получатель: \(order.recipientCompany)")
                        Text("Тип груза: \(order.cargoType)")
                        Text("Информация о заказе: \(order.orderInfo)")
                        Text("Вес груза: \(order.cargoWeight)")
                        Text("Крайний срок доставки: \(formatDate(order.deliveryDeadline))")
                        
                        Button("Взять в работу") {
                            takeOrder(orderID: order.id)
                        }
                    }
                }
            }
        }
        .navigationBarTitle("Поиск заказа")
        .alert(isPresented: $alertManager.showAlert) {
            Alert(title: Text("Сообщение"),
                  message: Text(alertManager.alertMessage),
                  dismissButton: .default(Text("OK")) {
                      alertManager.showAlert = false
                  })
        }
        .onAppear {
            print("Displaying orders: \(orders)")
        }
    }
    
    func takeOrder(orderID: String) {
        let db = Firestore.firestore()
        
        db.collection("DriverProfiles").document(currentUser.uid).getDocument { (document, error) in
            if let document = document, document.exists {
                let driverData = document.data()
                
                if let firstName = driverData?["firstName"] as? String,
                   let lastName = driverData?["lastName"] as? String {
                    
                    let driverName = "\(firstName) \(lastName)"
                    
                    db.collection("OrdersList").document(orderID).updateData([
                        "driverID": currentUser.uid,
                        "driverName": driverName,
                        "status": "В пути"
                    ]) { error in
                        if let error = error {
                            alertManager.showError(message: "Ошибка при взятии заказа в работу: \(error.localizedDescription)")
                        } else {
                            alertManager.showSuccess(message: "Заказ успешно взят в работу")
                        }
                    }
                } else {
                    alertManager.showError(message: "Не удалось получить имя водителя")
                }
            } else {
                alertManager.showError(message: "Документ водителя не найден")
            }
        }
    }
    
    func getCityName(from address: String) -> String {
        let components = address.split(separator: ",")
        return components.first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? address
    }
}

func formatDate(_ date: Date) -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.locale = Locale(identifier: "ru_RU")
    dateFormatter.dateStyle = .medium
    dateFormatter.timeStyle = .short
    return dateFormatter.string(from: date)
}


struct ActiveOrders: View {
    @ObservedObject var alertManager: AlertManager
    @Binding var orders: [OrderItem]
    @Binding var driverLocations: [DriverLocation]
    @ObservedObject var locationManager: LocationManager

    @State private var selectedOrder: OrderItem?
    @State private var showingActionSheet = false
    @State private var showingOrderOnMap = false

    var body: some View {
        NavigationView {
            VStack {
                // Карта с заказами
                MapDriverView(orders: $orders, driverLocations: $driverLocations, region: $locationManager.region)
                    .frame(height: 300) // Высота карты
                    .padding(.bottom, 10)
                
                // Список заказов
                List {
                    ForEach(orders) { order in
                        OrderRow(order: order,
                                 onSelect: {
                                    self.selectedOrder = order
                                    self.showingOrderOnMap = true
                                 },
                                 onActions: {
                                    self.selectedOrder = order
                                    self.showingActionSheet = true
                                 })
                    }
                }
                .listStyle(InsetGroupedListStyle()) // Современный стиль списка
                .onAppear {
                    fetchOrders()
                }
            }
            .navigationBarTitle("Мои заказы")
            .alert(isPresented: $alertManager.showAlert) {
                Alert(title: Text("Сообщение"),
                      message: Text(alertManager.alertMessage),
                      dismissButton: .default(Text("OK")) {
                          alertManager.showAlert = false
                      })
            }
            .actionSheet(isPresented: $showingActionSheet) {
                ActionSheet(
                    title: Text("Выберите действие"),
                    message: Text("Выберите действие для заказа: \(selectedOrder?.orderInfo ?? "")"),
                    buttons: [
                        .destructive(Text("Отменить заказ")) {
                            if let selectedOrder = selectedOrder {
                                cancelOrder(selectedOrder)
                            }
                        },
                        .default(Text("Завершить доставку")) {
                            if let selectedOrder = selectedOrder {
                                completeOrder(selectedOrder)
                            }
                        },
                        .cancel()
                    ]
                )
            }
            .sheet(isPresented: $showingOrderOnMap) {
                if let selectedOrder = selectedOrder {
                    MapViewWithOrder(order: selectedOrder, region: $locationManager.region)
                }
            }
        }
    }

    func fetchOrders() {
        getDriversOrders(alertManager: alertManager) { fetchedOrders, error in
            if let error = error {
                alertManager.showError(message: "Ошибка при получении заказов: \(error.localizedDescription)")
                return
            }

            if let fetchedOrders = fetchedOrders {
                self.orders = fetchedOrders
            }
        }
    }

    func cancelOrder(_ order: OrderItem) {
        let db = Firestore.firestore()

        db.collection("OrdersList").document(order.id).updateData([
            "status": "Отменен водителем",
            "driverID": "",
            "driverName": "Не нашли водителя"
        ]) { error in
            if let error = error {
                alertManager.showError(message: "Ошибка при отмене заказа: \(error.localizedDescription)")
            } else {
                alertManager.showSuccess(message: "Заказ успешно отменен")
            }
        }
    }

    func completeOrder(_ order: OrderItem) {
        let db = Firestore.firestore()
        
        db.collection("OrdersList").document(order.id).updateData([
            "status": "Доставлено"
        ]) { error in
            if let error = error {
                alertManager.showError(message: "Ошибка при завершении заказа: \(error.localizedDescription)")
            } else {
                alertManager.showSuccess(message: "Заказ успешно завершен")
            }
        }
    }
}

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
                Spacer()
                Button(action: {
                    onSelect()
                }) {
                    Text("Выбрать")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                Spacer()
                Button(action: {
                    onActions()
                }) {
                    Text("Действия")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(radius: 5)
    }
}

struct MapViewWithOrder: View {
    var order: OrderItem
    @Binding var region: MKCoordinateRegion

    var body: some View {
        Map(coordinateRegion: $region, showsUserLocation: true, annotationItems: [order]) { order in
            MapPin(coordinate: CLLocationCoordinate2D(latitude: order.senderLatitude, longitude: order.senderLongitude), tint: .blue)
        }
        .onAppear {
            let coordinate = CLLocationCoordinate2D(latitude: order.senderLatitude, longitude: order.senderLongitude)
            region = MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
        }
    }
}

func getDriversOrders(alertManager: AlertManager, completion: @escaping ([OrderItem]?, Error?) -> Void) {
    let db = Firestore.firestore()

    if let currentUser = Auth.auth().currentUser {
        db.collection("OrdersList")
            .whereField("driverID", isEqualTo: currentUser.uid)
            .whereField("status", isEqualTo: "В пути") // Добавлен фильтр по статусу "В пути"
            .getDocuments { (snapshot, error) in
                if let error = error {
                    alertManager.showError(message: "Ошибка при получении заказов: \(error.localizedDescription)")
                    completion(nil, error)
                    return
                }

                var fetchedOrders: [OrderItem] = []

                for document in snapshot!.documents {
                    let orderData = document.data()

                    // Извлечение данных и проверка наличия всех необходимых полей
                    guard
                        let id = orderData["id"] as? String,
                        let adminID = orderData["adminID"] as? String,
                        let cargoType = orderData["cargoType"] as? String,
                        let cargoWeight = orderData["cargoWeight"] as? String,
                        let deliveryDeadlineTimestamp = orderData["deliveryDeadline"] as? Timestamp,
                        let driverName = orderData["driverName"] as? String,
                        let orderInfo = orderData["orderInfo"] as? String,
                        let recipientAddress = orderData["recipientAddress"] as? String,
                        let recipientCompany = orderData["recipientCompany"] as? String,
                        let recipientLatitude = orderData["recipientLatitude"] as? Double,
                        let recipientLongitude = orderData["recipientLongitude"] as? Double,
                        let senderAddress = orderData["senderAddress"] as? String,
                        let senderLatitude = orderData["senderLatitude"] as? Double,
                        let senderLongitude = orderData["senderLongitude"] as? Double,
                        let status = orderData["status"] as? String
                    else {
                        // Пропустить запись, если какое-то из полей отсутствует или неверного типа
                        continue
                    }

                    // Преобразование Timestamp в Date
                    let deliveryDeadline: Date
                    if let timestamp = deliveryDeadlineTimestamp as? Timestamp {
                        deliveryDeadline = timestamp.dateValue()
                    } else {
                        // В случае ошибки извлечения даты
                        continue
                    }

                    let order = OrderItem(
                        id: id,
                        adminID: adminID,
                        cargoType: cargoType,
                        cargoWeight: cargoWeight,
                        deliveryDeadline: deliveryDeadline,
                        driverName: driverName,
                        orderInfo: orderInfo,
                        recipientAddress: recipientAddress,
                        recipientCompany: recipientCompany,
                        recipientLatitude: recipientLatitude,
                        recipientLongitude: recipientLongitude,
                        senderAddress: senderAddress,
                        senderLatitude: senderLatitude,
                        senderLongitude: senderLongitude,
                        status: status
                    )

                    fetchedOrders.append(order)
                }

                DispatchQueue.main.async {
                    completion(fetchedOrders, nil)
                }
            }
    }
}
struct ChatDriverView: View {
    @State private var existingChats: [ChatInfo] = []
    @State private var selectedChat: ChatInfo?
    @State private var isChatViewPresented = false
    
    @ObservedObject var alertManager: AlertManager
    
    let db = Firestore.firestore()
    let currentUser = Auth.auth().currentUser
    
    var body: some View {
        NavigationView {
            VStack {
                if existingChats.isEmpty {
                    Text("Нет доступных чатов.")
                        .padding()
                } else {
                    List(existingChats, id: \.id) { chat in
                        VStack(alignment: .leading) {
                            Text("Идентификатор заказа: \(chat.orderId)")
                            Text("Адрес получателя: \(chat.recipientAddress)")
                            Text("Адрес отправителя: \(chat.senderAddress)")
                        }
                        .onTapGesture {
                            selectedChat = chat
                            isChatViewPresented = true
                        }
                    }
                }
            }
            .navigationTitle("Чат водителя")
        }
        .sheet(isPresented: $isChatViewPresented) {
            if let selectedChat = selectedChat {
                ChatView(chatInfo: selectedChat)
            }
        }
        .onAppear {
            loadExistingChats()
            startListeningForNewOrders()
        }
    }
    
    private func createNewChat(orderId: String, recipientAddress: String, senderAddress: String, driverId: String, adminId: String) {
        print("Создание нового чата для заказа \(orderId)")
        let chatId = UUID().uuidString.uppercased() // Создаем идентификатор в формате UUID
        let chatData: [String: Any] = [
            "id": chatId,
            "orderId": orderId,
            "recipientAddress": recipientAddress,
            "senderAddress": senderAddress,
            "participants": [adminId, driverId] // Добавляем участников
        ]
        
        db.collection("Chats").document(chatId).setData(chatData) { error in
            if let error = error {
                print("Ошибка при создании документа чата: \(error.localizedDescription)")
                alertManager.showError(message: "Ошибка при создании документа чата: \(error.localizedDescription)")
                return
            }
            print("Чат успешно создан для заказа \(orderId)")
            loadExistingChats()
        }
    }
    
    private func loadExistingChats() {
        guard let currentUser = currentUser else {
            alertManager.showError(message: "Пользователь не аутентифицирован.")
            return
        }
        
        let driverId = currentUser.uid
        print("Загрузка чатов для водителя с ID \(driverId)")
        
        db.collection("Chats")
            .whereField("participants", arrayContains: driverId)
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    print("Ошибка при получении чатов: \(error.localizedDescription)")
                    alertManager.showError(message: "Ошибка при получении чатов: \(error.localizedDescription)")
                } else {
                    guard let documents = querySnapshot?.documents else {
                        print("Ошибка: документы пусты")
                        return
                    }
                    print("Количество документов: \(documents.count)")
                    
                    existingChats = documents.compactMap { document in
                        let data = document.data()
                        guard let orderId = data["orderId"] as? String,
                              let recipientAddress = data["recipientAddress"] as? String,
                              let senderAddress = data["senderAddress"] as? String,
                              let chatId = data["id"] as? String,
                              let participants = data["participants"] as? [String] else {
                            print("Ошибка: недостаточно данных для документа чата \(document.documentID)")
                            return nil
                        }
                        return ChatInfo(id: chatId, orderId: orderId, recipientAddress: recipientAddress, senderAddress: senderAddress, participants: participants)
                    }
                    print("Найдено \(existingChats.count) чатов для водителя")
                }
            }
    }
    
    private func startListeningForNewOrders() {
        guard let currentUser = currentUser else {
            alertManager.showError(message: "Пользователь не аутентифицирован.")
            return
        }
        
        let driverId = currentUser.uid
        print("Начало прослушивания новых заказов для водителя с ID \(driverId)")
        
        db.collection("OrdersList")
            .whereField("driverID", isEqualTo: driverId)
            .whereField("status", isEqualTo: "В пути")
            .addSnapshotListener { querySnapshot, error in
                guard let snapshot = querySnapshot else {
                    alertManager.showError(message: "Ошибка при прослушивании заказов: \(error?.localizedDescription ?? "Неизвестная ошибка")")
                    return
                }
                
                snapshot.documentChanges.forEach { change in
                    if change.type == .added {
                        let orderData = change.document.data()
                        if let orderId = orderData["id"] as? String,
                           let recipientAddress = orderData["recipientAddress"] as? String,
                           let senderAddress = orderData["senderAddress"] as? String,
                           let adminId = orderData["adminID"] as? String {
                            if existingChats.contains(where: { $0.orderId == orderId }) {
                                print("Чат для заказа \(orderId) уже существует")
                            } else {
                                print("Создание нового чата для нового заказа \(orderId)")
                                createNewChat(orderId: orderId, recipientAddress: recipientAddress, senderAddress: senderAddress, driverId: driverId, adminId: adminId)
                            }
                        } else {
                            alertManager.showError(message: "Недостаточно данных для заказа")
                        }
                    }
                }
            }
    }
}


//Map

struct MapDriverView: UIViewRepresentable {
    @Binding var orders: [OrderItem]
    @Binding var driverLocations: [DriverLocation]
    @Binding var region: MKCoordinateRegion

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.removeAnnotations(mapView.annotations)
        mapView.removeOverlays(mapView.overlays)

        // Добавление заказов в качестве аннотаций на карте
        let orderAnnotations = orders.flatMap { order -> [MKPointAnnotation] in
            var annotations: [MKPointAnnotation] = []
            
            let senderAnnotation = MKPointAnnotation()
            senderAnnotation.title = "Отправление"
            senderAnnotation.subtitle = "\(order.senderAddress)"
            senderAnnotation.coordinate = CLLocationCoordinate2D(latitude: order.senderLatitude, longitude: order.senderLongitude)
            annotations.append(senderAnnotation)
            
            let recipientAnnotation = MKPointAnnotation()
            recipientAnnotation.title = "Получение"
            recipientAnnotation.subtitle = "\(order.recipientAddress)"
            recipientAnnotation.coordinate = CLLocationCoordinate2D(latitude: order.recipientLatitude, longitude: order.recipientLongitude)
            annotations.append(recipientAnnotation)
            
            return annotations
        }
        mapView.addAnnotations(orderAnnotations)

        // Устанавливаем регион, чтобы охватить все аннотации
        if !orderAnnotations.isEmpty {
            var minLat = orderAnnotations.map { $0.coordinate.latitude }.min()!
            var maxLat = orderAnnotations.map { $0.coordinate.latitude }.max()!
            var minLon = orderAnnotations.map { $0.coordinate.longitude }.min()!
            var maxLon = orderAnnotations.map { $0.coordinate.longitude }.max()!

            let span = MKCoordinateSpan(latitudeDelta: (maxLat - minLat) * 1.5, longitudeDelta: (maxLon - minLon) * 1.5)
            let center = CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2, longitude: (minLon + maxLon) / 2)
            let region = MKCoordinateRegion(center: center, span: span)
            mapView.setRegion(region, animated: true)
        }

        // Рисуем маршруты между отправлением и получением
        for order in orders {
            let sourceLocation = CLLocationCoordinate2D(latitude: order.senderLatitude, longitude: order.senderLongitude)
            let destinationLocation = CLLocationCoordinate2D(latitude: order.recipientLatitude, longitude: order.recipientLongitude)

            context.coordinator.drawRoute(from: sourceLocation, to: destinationLocation, on: mapView)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapDriverView

        init(_ parent: MapDriverView) {
            self.parent = parent
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            let identifier = "OrderAnnotation"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKPinAnnotationView

            if annotationView == nil {
                annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
            } else {
                annotationView?.annotation = annotation
            }

            return annotationView
        }

        func drawRoute(from source: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D, on mapView: MKMapView) {
            let sourcePlacemark = MKPlacemark(coordinate: source)
            let destinationPlacemark = MKPlacemark(coordinate: destination)

            let directionRequest = MKDirections.Request()
            directionRequest.source = MKMapItem(placemark: sourcePlacemark)
            directionRequest.destination = MKMapItem(placemark: destinationPlacemark)
            directionRequest.transportType = .automobile

            let directions = MKDirections(request: directionRequest)
            directions.calculate { response, error in
                guard let response = response, error == nil else {
                    print("Error calculating directions: \(String(describing: error))")
                    return
                }

                let route = response.routes.first!
                mapView.addOverlay(route.polyline, level: .aboveRoads)
            }
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = .blue
                renderer.lineWidth = 4.0
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}


//запись в бд геолокации
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var lastKnownLocation: CLLocation?
    @Published var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func requestLocationPermission() {
        manager.requestAlwaysAuthorization()
    }

    func startUpdatingLocation() {
        manager.startUpdatingLocation()
    }

    func stopUpdatingLocation() {
        manager.stopUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        lastKnownLocation = location
        region = MKCoordinateRegion(center: location.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
        saveLocationToFirestore(location: location)
    }

    func saveLocationToFirestore(location: CLLocation) {
        guard let userID = Auth.auth().currentUser?.uid else { return }

        let db = Firestore.firestore()
        db.collection("DriverLocations").document(userID).setData([
            "driverID": userID,
            "latitude": location.coordinate.latitude,
            "longitude": location.coordinate.longitude,
            "timestamp": Timestamp(date: Date())
        ]) { error in
            if let error = error {
                print("Ошибка при сохранении геопозиции: \(error.localizedDescription)")
            } else {
                print("Геопозиция успешно сохранена")
            }
        }
    }
}





//
//struct DriverTabView_Previews: PreviewProvider {
//    static var previews: some View {
//        DriverTabView()
//    }
//}




