//  Copyright © 2019 Koninklijke Philips Nederland N.V.. All rights reserved.

public typealias EncryptedNotificationHandler = (Data) -> Void

public protocol SocketIOService {
    func start(onNotification: @escaping EncryptedNotificationHandler)
    func notify(data: Data)
}