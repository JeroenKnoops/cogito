import Foundation
import SocketIO

public protocol NotificationHandler {
    func on(notification: String)
    func on(error: Error)
}

public enum NotificationError: Error, Equatable {
    case setupFailed
    case unknown(data: [Any])
    case serverError(message: String)

    public static func == (lhs: NotificationError, rhs: NotificationError) -> Bool {
        switch (lhs, rhs) {
        case (.setupFailed, .setupFailed): return true
        case (.serverError(let lhsMessage), .serverError(let rhsMessage)): return lhsMessage == rhsMessage
        default: return false
        }
    }
}

public typealias CompletionHandler = (Error?) -> Void

public struct TelepathImpl: Telepath {
    let queuing: QueuingService
    let socketIOService: SocketIOService

    public init(serviceUrl: URL) {
        queuing = QueuingServiceClient(url: serviceUrl)
        socketIOService = SocketIOServiceClient {
            return SocketManager(socketURL: serviceUrl, config: [/*.log(true)*/])
        }
    }

    public func connect(channel: ChannelID, key: ChannelKey, appName: String,
                        notificationHandler: NotificationHandler? = nil) -> SecureChannel {
        return SecureChannel(
            queuing: queuing, socketIOService: socketIOService,
            notificationHandler: notificationHandler,
            id: channel, key: key, appName: appName)
    }
}

public typealias ChannelID = String
