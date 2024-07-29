import SwiftUI
import Firebase
import FirebaseFirestore
import MapKit
import CoreLocation


struct AdminTabView: View {
    @StateObject private var alertManager = AlertManager()
    @StateObject private var locationManager = LocationManager()
    @State private var driverLocations: [DriverLocation] = []
    @State private var currentOrder: OrderItem?
    @State private var region: MKCoordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 5.0, longitudeDelta: 5.0)
    )
    @State private var isInitialRegionSet: Bool = false

    var body: some View {
        TabView {
            NavigationView {
                OrdersListView(selectedOrder: $currentOrder, alertManager: alertManager)
            }
            .tabItem {
                Image(systemName: "list.bullet")
                Text("Список заказов")
            }

            AddOrderView(alertManager: alertManager)
                .tabItem {
                    Image(systemName: "plus")
                    Text("Добавить заказ")
                }

            ChatAdminView()
                .tabItem {
                    Image(systemName: "message")
                    Text("Чат")
                }

            if let order = currentOrder {
                VStack {
                    ZStack(alignment: .topTrailing) {
                        MapAdminView(driverLocations: $driverLocations, order: order, region: $region, isInitialRegionSet: $isInitialRegionSet)
                            .edgesIgnoringSafeArea(.all)

                        VStack {
                            Spacer()
                            ZoomControlsView(zoomIn: zoomIn, zoomOut: zoomOut)
                                .padding(.top, 50)
                                .padding(.trailing, 10)
                        }
                    }

                    Text("Заказ №\(order.id), \(order.senderAddress) -> \(order.recipientAddress)")
                        .padding()
                }
                .tabItem {
                    Image(systemName: "map")
                    Text("Карта")
                }
                .onAppear {
                    centerMapOnOrder(order)
                }
            } else {
                Text("Выберите заказ для отображения на карте")
                    .tabItem {
                        Image(systemName: "map")
                        Text("Карта")
                    }
            }
        }
        .navigationBarTitle("Панель организации")
        .onAppear {
            locationManager.requestLocationPermission()
            locationManager.startUpdatingLocation()
            fetchDriverLocations()
        }
    }

    private func zoomIn() {
        let span = MKCoordinateSpan(latitudeDelta: region.span.latitudeDelta / 2, longitudeDelta: region.span.longitudeDelta / 2)
        region.span = span
    }

    private func zoomOut() {
        let span = MKCoordinateSpan(latitudeDelta: region.span.latitudeDelta * 2, longitudeDelta: region.span.longitudeDelta * 2)
        region.span = span
    }

    private func centerMapOnOrder(_ order: OrderItem) {
        let senderLocation = CLLocation(latitude: order.senderLatitude, longitude: order.senderLongitude)
        let recipientLocation = CLLocation(latitude: order.recipientLatitude, longitude: order.recipientLongitude)

        var minLat = min(order.senderLatitude, order.recipientLatitude)
        var maxLat = max(order.senderLatitude, order.recipientLatitude)
        var minLon = min(order.senderLongitude, order.recipientLongitude)
        var maxLon = max(order.senderLongitude, order.recipientLongitude)

        for driverLocation in driverLocations {
            minLat = min(minLat, driverLocation.latitude)
            maxLat = max(maxLat, driverLocation.latitude)
            minLon = min(minLon, driverLocation.longitude)
            maxLon = max(maxLon, driverLocation.longitude)
        }

        let centerLat = (minLat + maxLat) / 2
        let centerLon = (minLon + maxLon) / 2

        let latDelta = (maxLat - minLat) * 1.2
        let lonDelta = (maxLon - minLon) * 1.2

        region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon),
            span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
        )
    }


    private func fetchDriverLocations() {
        let db = Firestore.firestore()
        db.collection("DriverLocations").getDocuments { (snapshot, error) in
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
                if let order = self.currentOrder {
                    self.centerMapOnOrder(order)
                }
            }
        }
    }
}



func generateReadableOrderId(for date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyyMMdd"
    let dateString = formatter.string(from: date)
    // Уникальный номер можно получить из базы данных или использовать счетчик
    // Здесь для примера будем использовать случайный номер от 1 до 999
    let uniqueNumber = Int.random(in: 1...999)
    return "\(dateString)-\(String(format: "%03d", uniqueNumber))"
}

struct OrdersListView: View {
    @State private var orders: [OrderItem] = []
    @Binding var selectedOrder: OrderItem?
    @ObservedObject var alertManager: AlertManager
    @State private var selectedStatus: String = "Все"
    @State private var editingOrder: OrderItem? = nil

    var body: some View {
        NavigationView {
            VStack {
                // Picker для фильтрации по статусу
                Picker("Статус", selection: $selectedStatus) {
                    Text("Все").tag("Все")
                    Text("Новый").tag("Новый")
                    Text("В пути").tag("В пути")
                    Text("Доставлено").tag("Доставлено")
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()

                if filteredOrders.isEmpty {
                    Text("Нет доступных заказов")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    List(filteredOrders) { order in
                        VStack(alignment: .leading, spacing: 10) {
                            // Детали заказа
                            Group {
                                HStack {
                                    Text("Заказ #: ")
                                    Spacer()
                                    Text("\(order.id)")
                                }
                                HStack {
                                    Text("Тип груза: ")
                                    Spacer()
                                    Text("\(order.cargoType)")
                                }
                                HStack {
                                    Text("Вес груза: ")
                                    Spacer()
                                    Text("\(order.cargoWeight)")
                                }
                                HStack {
                                    Text("Крайний срок доставки: ")
                                    Spacer()
                                    Text("\(formatDate(order.deliveryDeadline))")
                                }
                                HStack {
                                    Text("Информация о заказе: ")
                                    Spacer()
                                    Text("\(order.orderInfo)")
                                }
                                HStack {
                                    Text("Компания-получатель: ")
                                    Spacer()
                                    Text("\(order.recipientCompany)")
                                }
                                HStack {
                                    Text("Откуда: ")
                                    Spacer()
                                    Text("\(order.senderAddress)")
                                }
                                HStack {
                                    Text("Куда: ")
                                    Spacer()
                                    Text("\(order.recipientAddress)")
                                }
                                HStack {
                                    Text("Водитель: ")
                                    Spacer()
                                    Text("\(order.driverName)")
                                }
                                HStack {
                                    Text("Статус: ")
                                    Spacer()
                                    Text("\(order.status)")
                                }
                            }

                            // Кнопки выбора и редактирования заказа
                            HStack {
                                Button(action: {
                                    self.selectedOrder = order
                                }) {
                                    Text("Выбрать")
                                        .foregroundColor(.white)
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(Color.blue)
                                        .cornerRadius(8)
                                }
                                .buttonStyle(PlainButtonStyle()) // Добавлено

                                Button(action: {
                                    self.editingOrder = order
                                }) {
                                    Text("Редактировать")
                                        .foregroundColor(.white)
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(Color.green)
                                        .cornerRadius(8)
                                }
                                .buttonStyle(PlainButtonStyle()) // Добавлено
                            }
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 10).stroke(Color.gray, lineWidth: 1))
                        .padding([.top, .horizontal])
                    }
                }
                Spacer()
            }
            .navigationBarTitle("Список опубликованных заказов")
            .onAppear {
                getOrders()
            }
            .sheet(item: self.$editingOrder) { order in
                EditOrderView(order: self.$editingOrder, alertManager: self.alertManager)
            }
            .alert(isPresented: $alertManager.showAlert) {
                let title = alertManager.isError ? "Ошибка" : "Успешно"
                return Alert(title: Text(title), message: Text(alertManager.alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }

    var filteredOrders: [OrderItem] {
        if selectedStatus == "Все" {
            return orders
        } else {
            return orders.filter { $0.status == selectedStatus }
        }
    }

    func getOrders() {
        let db = Firestore.firestore()

        if let currentUser = Auth.auth().currentUser {
            db.collection("OrdersList")
                .whereField("adminID", isEqualTo: currentUser.uid)
                .addSnapshotListener { (snapshot, error) in
                    if let error = error {
                        alertManager.showError(message: "Ошибка при получении заказов: \(error.localizedDescription)")
                        return
                    }

                    guard let documents = snapshot?.documents else {
                        print("No documents in snapshot")
                        return
                    }

                    self.orders = documents.compactMap { document in
                        do {
                            let order = try document.data(as: OrderItem.self)
                            return order
                        } catch {
                            print("Error decoding order: \(error)")
                            return nil
                        }
                    }
                }
        }
    }

    // Функция для форматирования даты
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}


    struct AddOrderView: View {
        @State private var showingAlert = false
        @State private var alertMessage = ""
        @State private var cargoType = ""
        @State private var deliveryDeadline = Date()
        @State private var orderInfo = ""
        @State private var cargoWeight = ""
        @State private var recipientCompany = ""
        @State private var senderAddress = ""
        @State private var recipientAddress = ""
        @State private var selectedCargoType = "Обычный"
        @State private var selectedStatus = "Новый"
        @State private var driverName = "Не нашли водителя"
        
        @State private var senderCoordinate: CLLocationCoordinate2D?
        @State private var recipientCoordinate: CLLocationCoordinate2D?
        @State private var senderSuggestions: [DaDataSuggestion] = []
        @State private var recipientSuggestions: [DaDataSuggestion] = []
        @State private var isShowingSenderSuggestions = false
        @State private var isShowingRecipientSuggestions = false
        
        let cargoTypes = ["Обычный", "Хрупкий", "Опасный"]
        let statuses = ["Новый", "В пути", "Доставлено"]
        
        var currentUser = Auth.auth().currentUser
        var alertManager: AlertManager
        @Environment(\.presentationMode) var presentationMode
        
        var body: some View {
            NavigationView {
                Form {
                    Section(header: Text("Информация о заказе")) {
                        Picker("Тип груза", selection: $selectedCargoType) {
                            ForEach(cargoTypes, id: \.self) {
                                Text($0)
                            }
                        }
                        
                        DatePicker("Крайний срок доставки", selection: $deliveryDeadline, displayedComponents: .date)
                        
                        TextField("Информация о заказе", text: $orderInfo)
                        
                        TextField("Вес груза", text: $cargoWeight)
                        
                        TextField("Компания-получатель", text: $recipientCompany)
                    }
                    
                    Section(header: Text("Адреса")) {
                        AddressAutocompleteTextField(
                            title: "Откуда",
                            address: $senderAddress,
                            coordinate: $senderCoordinate,
                            suggestions: $senderSuggestions,
                            isShowingSuggestions: $isShowingSenderSuggestions,
                            onAddressSelected: { suggestion in
                                self.senderAddress = suggestion.value
                                if let lat = Double(suggestion.data.geo_lat ?? ""), let lon = Double(suggestion.data.geo_lon ?? "") {
                                    self.senderCoordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                                } else {
                                    print("Invalid coordinates received")
                                }
                                self.isShowingSenderSuggestions = false
                            }
                        )
                        
                        AddressAutocompleteTextField(
                            title: "Куда",
                            address: $recipientAddress,
                            coordinate: $recipientCoordinate,
                            suggestions: $recipientSuggestions,
                            isShowingSuggestions: $isShowingRecipientSuggestions,
                            onAddressSelected: { suggestion in
                                self.recipientAddress = suggestion.value
                                if let lat = Double(suggestion.data.geo_lat ?? ""), let lon = Double(suggestion.data.geo_lon ?? "") {
                                    self.recipientCoordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                                } else {
                                    print("Invalid coordinates received")
                                }
                                self.isShowingRecipientSuggestions = false
                            }
                        )
                    }
                    
                    Section(header: Text("Другая информация")) {
                        Picker("Статус", selection: $selectedStatus) {
                            ForEach(statuses, id: \.self) {
                                Text($0)
                            }
                        }
                        
                        TextField("Водитель", text: $driverName)
                            .disabled(true)
                            .foregroundColor(.gray)
                    }
                    
                    Section {
                        Button(action: {
                            addOrder()
                        }) {
                            Text("Добавить заказ")
                        }
                        .foregroundColor(.blue)
                    }
                }
                .navigationBarTitle("Добавить заказ")
                .alert(isPresented: $showingAlert) {
                    Alert(title: Text("Заказ добавлен"), message: Text(alertMessage), dismissButton: .default(Text("OK")) {
                        self.presentationMode.wrappedValue.dismiss()
                    })
                }
            }
        }
        
        
        func addOrder() {
            let db = Firestore.firestore()
            
            guard let senderCoordinate = senderCoordinate, let recipientCoordinate = recipientCoordinate else {
                alertManager.showError(message: "Необходимо выбрать адрес отправления и получения.")
                return
            }
            
            if let currentUser = currentUser {
                let newOrderId = generateReadableOrderId(for: Date()) // Генерация удобочитаемого id
                
                db.collection("OrdersList").document(newOrderId).setData([
                    "id": newOrderId, // Добавляем удобочитаемый id в документ
                    "cargoType": selectedCargoType,
                    "deliveryDeadline": deliveryDeadline,
                    "orderInfo": orderInfo,
                    "cargoWeight": cargoWeight,
                    "recipientCompany": recipientCompany,
                    "senderAddress": senderAddress,
                    "recipientAddress": recipientAddress,
                    "senderLatitude": senderCoordinate.latitude,
                    "senderLongitude": senderCoordinate.longitude,
                    "recipientLatitude": recipientCoordinate.latitude,
                    "recipientLongitude": recipientCoordinate.longitude,
                    "status": selectedStatus,
                    "driverName": driverName,
                    "adminID": currentUser.uid
                ]) { error in
                    if let error = error {
                        alertManager.showError(message: "Ошибка при добавлении заказа: \(error.localizedDescription)")
                    } else {
                        self.alertMessage = "Заказ успешно добавлен!"
                        self.showingAlert = true
                        clearFields()
                    }
                }
            } else {
                alertManager.showError(message: "Ошибка: пользователь не авторизован.")
            }
        }

        
        func clearFields() {
            selectedCargoType = "Обычный"
            deliveryDeadline = Date()
            orderInfo = ""
            cargoWeight = ""
            recipientCompany = ""
            senderAddress = ""
            recipientAddress = ""
            senderCoordinate = nil
            recipientCoordinate = nil
            selectedStatus = "Новый"
            driverName = "Не нашли водителя"
        }
    }


struct EditOrderView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var order: OrderItem?
    @State private var cargoType = ""
    @State private var cargoWeight = ""
    @State private var deliveryDeadline = Date()
    @State private var orderInfo = ""
    @State private var recipientCompany = ""
    @State private var senderAddress = ""
    @State private var recipientAddress = ""
    @State private var driverName = ""
    @State private var status = ""
    
    @State private var senderCoordinate: CLLocationCoordinate2D?
    @State private var recipientCoordinate: CLLocationCoordinate2D?
    @State private var senderSuggestions: [DaDataSuggestion] = []
    @State private var recipientSuggestions: [DaDataSuggestion] = []
    @State private var isShowingSenderSuggestions = false
    @State private var isShowingRecipientSuggestions = false
    
    let cargoTypes = ["Обычный", "Хрупкий", "Опасный"]
    let statuses = ["Новый", "В пути", "Доставлено"]
    
    var alertManager: AlertManager
    
    var body: some View {
        Form {
            Section(header: Text("Информация о заказе")) {
                Picker("Тип груза", selection: $cargoType) {
                    ForEach(cargoTypes, id: \.self) { cargoType in
                        Text(cargoType)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                
                TextField("Вес груза", text: $cargoWeight)
                DatePicker("Крайний срок доставки", selection: $deliveryDeadline, displayedComponents: .date)
                TextField("Информация о заказе", text: $orderInfo)
                TextField("Компания-получатель", text: $recipientCompany)
            }
            
            Section(header: Text("Адреса")) {
                AddressAutocompleteTextField(
                    title: "Откуда",
                    address: $senderAddress,
                    coordinate: $senderCoordinate,
                    suggestions: $senderSuggestions,
                    isShowingSuggestions: $isShowingSenderSuggestions,
                    onAddressSelected: { suggestion in
                        self.senderAddress = suggestion.value
                        if let lat = Double(suggestion.data.geo_lat ?? ""), let lon = Double(suggestion.data.geo_lon ?? "") {
                            self.senderCoordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                        } else {
                            print("Invalid coordinates received")
                        }
                        self.isShowingSenderSuggestions = false
                    }
                )
                
                AddressAutocompleteTextField(
                    title: "Куда",
                    address: $recipientAddress,
                    coordinate: $recipientCoordinate,
                    suggestions: $recipientSuggestions,
                    isShowingSuggestions: $isShowingRecipientSuggestions,
                    onAddressSelected: { suggestion in
                        self.recipientAddress = suggestion.value
                        if let lat = Double(suggestion.data.geo_lat ?? ""), let lon = Double(suggestion.data.geo_lon ?? "") {
                            self.recipientCoordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                        } else {
                            print("Invalid coordinates received")
                        }
                        self.isShowingRecipientSuggestions = false
                    }
                )
            }
            
            Section(header: Text("Дополнительная информация")) {
                TextField("Имя водителя", text: $driverName)
                    .disabled(true)
                    .foregroundColor(.gray)
            }
            
            Section(header: Text("Статус заказа")) {
                Picker("Статус", selection: $status) {
                    ForEach(statuses, id: \.self) { status in
                        Text(status)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            Section {
                Button(action: {
                    saveChanges(alertManager: alertManager)
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Сохранить изменения")
                }
                .foregroundColor(.blue)
            }
        }
        .navigationBarTitle("Редактировать заказ")
        .onAppear {
            if let currentOrder = order {
                cargoType = currentOrder.cargoType
                cargoWeight = currentOrder.cargoWeight
                deliveryDeadline = currentOrder.deliveryDeadline
                orderInfo = currentOrder.orderInfo
                recipientCompany = currentOrder.recipientCompany
                senderAddress = currentOrder.senderAddress
                recipientAddress = currentOrder.recipientAddress
                driverName = currentOrder.driverName
                status = currentOrder.status
                senderCoordinate = CLLocationCoordinate2D(latitude: currentOrder.senderLatitude, longitude: currentOrder.senderLongitude)
                recipientCoordinate = CLLocationCoordinate2D(latitude: currentOrder.recipientLatitude, longitude: currentOrder.recipientLongitude)
            }
        }
    }
    
    func saveChanges(alertManager: AlertManager) {
        if let currentOrder = order {
            let db = Firestore.firestore()
            let orderRef = db.collection("OrdersList").document(currentOrder.id)
            
            orderRef.updateData([
                "cargoType": cargoType,
                "cargoWeight": cargoWeight,
                "deliveryDeadline": deliveryDeadline,
                "orderInfo": orderInfo,
                "recipientCompany": recipientCompany,
                "senderAddress": senderAddress,
                "recipientAddress": recipientAddress,
                "driverName": driverName,
                "status": status,
                "senderLatitude": senderCoordinate?.latitude ?? 0.0,
                "senderLongitude": senderCoordinate?.longitude ?? 0.0,
                "recipientLatitude": recipientCoordinate?.latitude ?? 0.0,
                "recipientLongitude": recipientCoordinate?.longitude ?? 0.0
            ]) { error in
                if let error = error {
                    alertManager.showError(message: "Ошибка при обновлении документа: \(error.localizedDescription)")
                } else {
                    alertManager.showSuccess(message: "Документ успешно обновлен")
                }
            }
        }
    }
}



struct ChatAdminView: View {
    @State private var existingChats: [ChatInfo] = []
    @State private var selectedChat: ChatInfo?
    @State private var isChatViewPresented = false
    let db = Firestore.firestore()
    let currentUser = Auth.auth().currentUser
    @StateObject private var alertManager = AlertManager()
    
    var body: some View {
        NavigationView {
            VStack {
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
            .navigationTitle("Чат организации")
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
    
    private func loadExistingChats() {
        guard let currentUser = currentUser else {
            alertManager.showError(message: "Пользователь не аутентифицирован.")
            return
        }
        
        let adminId = currentUser.uid
        
        db.collection("Chats")
            .whereField("participants", arrayContains: adminId)
            .getDocuments { (querySnapshot, error) in
                if let error = error {
                    alertManager.showError(message: "Ошибка при получении чатов: \(error.localizedDescription)")
                } else {
                    existingChats = querySnapshot?.documents.compactMap { document in
                        try? document.data(as: ChatInfo.self)
                    } ?? []
                }
            }
    }
    
    private func startListeningForNewOrders() {
        guard let currentUser = currentUser else {
            alertManager.showError(message: "Пользователь не аутентифицирован.")
            return
        }
        
        let adminId = currentUser.uid
        
        db.collection("OrdersList")
            .whereField("adminID", isEqualTo: adminId)
            .addSnapshotListener { querySnapshot, error in
                guard let snapshot = querySnapshot else {
                    alertManager.showError(message: "Ошибка при прослушивании заказов: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                snapshot.documentChanges.forEach { change in
                    if change.type == .added {
                        guard let order = try? change.document.data(as: OrderItem.self) else {
                            alertManager.showError(message: "Ошибка при получении данных заказа")
                            return
                        }
                        
                        // Создаем чат для нового заказа
                        createChatForOrder(order: order)
                    }
                }
            }
    }
    
    private func createChatForOrder(order: OrderItem) {
        guard let currentUser = currentUser else {
            alertManager.showError(message: "Пользователь не аутентифицирован.")
            return
        }
        
        let adminId = currentUser.uid
        let driverId = order.driverName // Убедитесь, что driverName является уникальным идентификатором водителя
        let participants = [adminId, driverId]
        
        // Проверяем, существует ли чат для данного заказа в базе данных
        db.collection("Chats")
            .whereField("orderId", isEqualTo: order.id)
            .getDocuments { (querySnapshot, error) in
                if let error = error {
                    alertManager.showError(message: "Ошибка при проверке существования чата: \(error.localizedDescription)")
                    return
                }
                
                if let documents = querySnapshot?.documents, !documents.isEmpty {
                    alertManager.showError(message: "Чат для заказа \(order.id) уже существует.")
                } else {
                    // Создаем новый чат
                    createNewChat(orderId: order.id, recipientAddress: order.recipientAddress, senderAddress: order.senderAddress, participants: participants)
                }
            }
    }

    private func createNewChat(orderId: String, recipientAddress: String, senderAddress: String, participants: [String]) {
        let newChatId = UUID().uuidString
        let newChat = ChatInfo(id: newChatId, orderId: orderId, recipientAddress: recipientAddress, senderAddress: senderAddress, participants: participants)
        
        do {
            try db.collection("Chats").document(newChatId).setData(from: newChat) { error in
                if let error = error {
                    alertManager.showError(message: "Ошибка при создании документа чата: \(error.localizedDescription)")
                    return
                }
                // Обновляем список чатов после успешного создания
                loadExistingChats()
            }
        } catch {
            alertManager.showError(message: "Ошибка при сохранении документа чата: \(error.localizedDescription)")
        }
    }
}


//MapKit and CoreLocation

struct MapAdminView: UIViewRepresentable {
    @Binding var driverLocations: [DriverLocation]
    var order: OrderItem
    @Binding var region: MKCoordinateRegion
    @Binding var isInitialRegionSet: Bool

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.removeAnnotations(mapView.annotations)
        mapView.removeOverlays(mapView.overlays)

        // Add annotations for drivers
        let driverAnnotations = driverLocations.map { location -> MKPointAnnotation in
            let annotation = MKPointAnnotation()
            annotation.title = "Водитель"
            annotation.subtitle = "Координаты: \(location.latitude), \(location.longitude)"
            annotation.coordinate = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
            return annotation
        }

        // Add annotations for sender and recipient
        let senderAnnotation = MKPointAnnotation()
        senderAnnotation.title = "Отправление"
        senderAnnotation.coordinate = CLLocationCoordinate2D(latitude: order.senderLatitude, longitude: order.senderLongitude)

        let recipientAnnotation = MKPointAnnotation()
        recipientAnnotation.title = "Получение"
        recipientAnnotation.coordinate = CLLocationCoordinate2D(latitude: order.recipientLatitude, longitude: order.recipientLongitude)

        mapView.addAnnotations(driverAnnotations + [senderAnnotation, recipientAnnotation])

        // Show all annotations
        let annotations = driverAnnotations + [senderAnnotation, recipientAnnotation]
        mapView.showAnnotations(annotations, animated: true)

        // Build route
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: senderAnnotation.coordinate))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: recipientAnnotation.coordinate))
        request.transportType = .automobile

        let directions = MKDirections(request: request)
        directions.calculate { response, error in
            if let error = error {
                print("Error calculating directions: \(error.localizedDescription)")
                return
            }

            guard let route = response?.routes.first else { return }
            mapView.addOverlay(route.polyline)
            
            DispatchQueue.main.async {
                // Set the map's visible region to fit the route only if it's the first time
                if !isInitialRegionSet {
                    mapView.setVisibleMapRect(route.polyline.boundingMapRect, edgePadding: UIEdgeInsets(top: 50, left: 50, bottom: 50, right: 50), animated: true)
                    isInitialRegionSet = true
                    region = mapView.region
                }
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapAdminView

        init(_ parent: MapAdminView) {
            self.parent = parent
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
