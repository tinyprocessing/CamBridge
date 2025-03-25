import Combine
import Network
import UIKit

class InterProcessCommunicator {
    private var listener: NWListener?
    private var tempImage = Data()
    private var isCancelled = false
    private let imageSubject = PassthroughSubject<UIImage, Never>()

    var imagePublisher: AnyPublisher<UIImage, Never> {
        imageSubject.eraseToAnyPublisher()
    }

    deinit {
        detachConnection()
    }

    func connect() {
        guard listener == nil else { return }

        do {
            listener = try NWListener(using: .udp, on: Config.port)
            listener?.stateUpdateHandler = { _ in }
            listener?.newConnectionHandler = { [weak self] newConnection in
                self?.receive(on: newConnection)
            }
            listener?.start(queue: .global())
        } catch {}
    }

    private func receive(on connection: NWConnection) {
        connection.start(queue: .global())

        connection.receiveMessage { [weak self] data, _, _, error in
            guard let self = self, !self.isCancelled else {
                connection.cancel()
                return
            }

            if let _ = error {
                connection.cancel()
                return
            }

            guard let data = data else { return }

            if data.count == Config.singleByte && data.first == Config.endOfDataByte {
                if let image = UIImage(data: self.tempImage) {
                    self.imageSubject.send(image)
                }
                self.tempImage = Data()
            } else {
                self.tempImage.append(data)
            }

            self.receive(on: connection)
        }
    }

    func detachConnection() {
        guard listener != nil else { return }
        isCancelled = true
        listener?.cancel()
        listener = nil
    }
}

extension InterProcessCommunicator {
    fileprivate enum Config {
        static let port: NWEndpoint.Port = 5005
        static let singleByte = 1
        static let endOfDataByte = UInt8(ascii: ".")
    }
}
