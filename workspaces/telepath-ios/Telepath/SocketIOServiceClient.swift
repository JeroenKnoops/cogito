import SocketIO
import base64url

class SocketIOServiceClient: SocketIOService {
    var socket: SocketIOClient?
    var pendingNotifications = [String]()
    var setupComplete = false
    var channelID: ChannelID!
    var notificationHandler: EncryptedNotificationHandler!
    var errorHandler: ErrorHandler?
    var completion: CompletionHandler?
    let socketManagerFactoryMethod: () -> SocketManager
    var started: Bool { return setupComplete }

    lazy var socketManager: SocketManager = {
        return socketManagerFactoryMethod()
    }()

    init(socketManagerFactoryMethod: @escaping () -> SocketManager) {
        self.socketManagerFactoryMethod = socketManagerFactoryMethod
    }

    deinit {
        self.socket?.removeAllHandlers()
        self.socket?.disconnect()
    }

    func start(channelID: ChannelID,
               onNotification: @escaping EncryptedNotificationHandler,
               onError: ErrorHandler?,
               completion: CompletionHandler?) {
        let socket = socketManager.defaultSocket
        self.socket = socket
        self.channelID = channelID
        self.notificationHandler = onNotification
        self.errorHandler = onError
        self.completion = completion
        socket.on(clientEvent: .connect) { [weak self] _, _ in self?.onConnect() }
        socket.on("notification") { [weak self] data, _ in self?.onNotification(data) }
        socket.on(clientEvent: .error) { [weak self] data, _ in
            guard let self = self else { return }
            let error = data[0] as? Error ?? NotificationError.unknown(data: data)
            if let completion = self.completion, !self.started {
                completion(error)
                self.completion = nil
            } else {
                self.errorHandler?(error)
            }
        }
        socket.on("server error") { [weak self] data, _ in
            let message = data[0] as? String ?? "unknown server error"
            let error = NotificationError.serverError(message: message)
            self?.errorHandler?(error)
        }
        socket.connect()
    }

    func onConnect() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.socket?
                .emitWithAck("identify", self.channelID)
                .timingOut(after: 30) { [weak self] items in
                    if items.count > 0 && items[0] as? String == SocketAckStatus.noAck.rawValue {
                        self?.completion?(NotificationError.setupFailed)
                    } else {
                        self?.sendPendingNotifications()
                        self?.completion?(nil)
                    }
            }
        }
    }

    func onNotification(_ data: [Any]) {
        if let encoded = data[0] as? Data,
            let base64 = String(data: encoded, encoding: .utf8),
            let message = Data(base64urlEncoded: base64) {
            self.notificationHandler(message)
        }
    }

    func sendPendingNotifications() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            for message in self.pendingNotifications {
                self.socket?.emit("notification", message)
            }
            self.pendingNotifications = []
            self.setupComplete = true
        }
    }

    func notify(data: Data) {
        let encodedData = data.base64urlEncodedString()
        if setupComplete {
            socket?.emit("notification", encodedData)
        } else {
            pendingNotifications.append(encodedData)
        }
    }
}
