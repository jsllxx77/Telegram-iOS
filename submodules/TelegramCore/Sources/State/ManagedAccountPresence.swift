import Foundation
import TelegramApi
import Postbox
import SwiftSignalKit
import MtProtoKit

private typealias SignalKitTimer = SwiftSignalKit.Timer


public struct AccountPresenceNetworkPolicy: Equatable {
    public var sendOnlinePackets: Bool
    public var sendOfflinePacketAfterOnline: Bool

    public init(sendOnlinePackets: Bool, sendOfflinePacketAfterOnline: Bool) {
        self.sendOnlinePackets = sendOnlinePackets
        self.sendOfflinePacketAfterOnline = sendOfflinePacketAfterOnline
    }
}

private final class AccountPresenceManagerImpl {
    private let queue: Queue
    private let network: Network
    let isPerformingUpdate = ValuePromise<Bool>(false, ignoreRepeated: true)
    
    private var shouldKeepOnlinePresenceDisposable: Disposable?
    private var networkPolicyDisposable: Disposable?
    private let currentRequestDisposable = MetaDisposable()
    private var onlineTimer: SignalKitTimer?
    
    private var wasOnline: Bool = false
    private var didSendOnlinePacket: Bool = false
    private var networkPolicy = AccountPresenceNetworkPolicy(sendOnlinePackets: true, sendOfflinePacketAfterOnline: false)
    
    init(queue: Queue, shouldKeepOnlinePresence: Signal<Bool, NoError>, networkPolicy: Signal<AccountPresenceNetworkPolicy, NoError>, network: Network) {
        self.queue = queue
        self.network = network

        self.networkPolicyDisposable = (networkPolicy
        |> distinctUntilChanged
        |> deliverOn(self.queue)).start(next: { [weak self] value in
            guard let `self` = self else {
                return
            }
            let previousPolicy = self.networkPolicy
            self.networkPolicy = value
            if self.wasOnline {
                if !value.sendOnlinePackets {
                    self.updatePresence(false)
                } else if !previousPolicy.sendOnlinePackets {
                    self.updatePresence(true)
                }
            }
        })
        
        self.shouldKeepOnlinePresenceDisposable = (shouldKeepOnlinePresence
        |> distinctUntilChanged
        |> deliverOn(self.queue)).start(next: { [weak self] value in
            guard let `self` = self else {
                return
            }
            if self.wasOnline != value {
                self.wasOnline = value
                self.updatePresence(value)
            }
        })
    }
    
    deinit {
        assert(self.queue.isCurrent())
        self.shouldKeepOnlinePresenceDisposable?.dispose()
        self.networkPolicyDisposable?.dispose()
        self.currentRequestDisposable.dispose()
        self.onlineTimer?.invalidate()
    }
    
    private func updatePresence(_ isOnline: Bool) {
        let request: Signal<Api.Bool, MTRpcError>
        if isOnline {
            if !self.networkPolicy.sendOnlinePackets {
                self.onlineTimer?.invalidate()
                self.onlineTimer = nil
                self.currentRequestDisposable.set(nil)
                self.isPerformingUpdate.set(false)
                return
            }
            let timer = SignalKitTimer(timeout: 30.0, repeat: false, completion: { [weak self] in
                guard let strongSelf = self else {
                    return
                }
                strongSelf.updatePresence(true)
            }, queue: self.queue)
            self.onlineTimer = timer
            timer.start()
            request = self.network.request(Api.functions.account.updateStatus(offline: .boolFalse))
        } else {
            self.onlineTimer?.invalidate()
            self.onlineTimer = nil
            if !self.networkPolicy.sendOfflinePacketAfterOnline || !self.didSendOnlinePacket {
                self.currentRequestDisposable.set(nil)
                self.isPerformingUpdate.set(false)
                return
            }
            self.didSendOnlinePacket = false
            request = self.network.request(Api.functions.account.updateStatus(offline: .boolTrue))
        }
        self.isPerformingUpdate.set(true)
        self.currentRequestDisposable.set((request
        |> `catch` { _ -> Signal<Api.Bool, NoError> in
            return .single(.boolFalse)
        }
        |> deliverOn(self.queue)).start(next: { [weak self] result in
            guard let strongSelf = self else {
                return
            }
            if isOnline, case .boolTrue = result {
                strongSelf.didSendOnlinePacket = true
            }
        }, completed: { [weak self] in
            guard let strongSelf = self else {
                return
            }
            strongSelf.isPerformingUpdate.set(false)
        }))
    }
}

final class AccountPresenceManager {
    private let queue = Queue()
    private let impl: QueueLocalObject<AccountPresenceManagerImpl>
    
    init(shouldKeepOnlinePresence: Signal<Bool, NoError>, networkPolicy: Signal<AccountPresenceNetworkPolicy, NoError>, network: Network) {
        let queue = self.queue
        self.impl = QueueLocalObject(queue: self.queue, generate: {
            return AccountPresenceManagerImpl(queue: queue, shouldKeepOnlinePresence: shouldKeepOnlinePresence, networkPolicy: networkPolicy, network: network)
        })
    }
    
    func isPerformingUpdate() -> Signal<Bool, NoError> {
        return Signal { subscriber in
            let disposable = MetaDisposable()
            self.impl.with { impl in
                disposable.set(impl.isPerformingUpdate.get().start(next: { value in
                    subscriber.putNext(value)
                }))
            }
            return disposable
        }
    }
}
