/**
 * Copyright (c) 2016-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

import Foundation
import Parse
import BoltsSwift
import SocketRocket

/**
 This is the 'advanced' view of live query subscriptions. It allows you to customize your subscriptions
 to a live query server, have connections to multiple servers, cleanly handle disconnect and reconnect.
 */
@objc(PFLiveQueryClient)
open class Client: NSObject {
    let host: URL
    let applicationId: String
    let clientKey: String?

    var socket: SRWebSocket?
    public var userDisconnected = false

    // This allows us to easily plug in another request ID generation scheme, or more easily change the request id type
    // if needed (technically this could be a string).
    let requestIdGenerator: () -> RequestId
    var subscriptions = [SubscriptionRecord]()

    let queue = DispatchQueue(label: "com.parse.livequery", attributes: [])

    /**
     Creates a Client which automatically attempts to connect to the custom parse-server URL set in Parse.currentConfiguration().
     */
    public override convenience init() {
        self.init(server: Parse.validatedCurrentConfiguration().server)
    }

    /**
     Creates a client which will connect to a specific server with an optional application id and client key

     - parameter server:        The server to connect to
     - parameter applicationId: The application id to use
     - parameter clientKey:     The client key to use
     */
    public init(server: String, applicationId: String? = nil, clientKey: String? = nil) {
        guard let cmpts = URLComponents(string: server) else {
            fatalError("Server should be a valid URL.")
        }
        var components = cmpts
        components.scheme = components.scheme == "https" ? "wss" : "ws"

        // Simple incrementing generator - can't use ++, that operator is deprecated!
        var currentRequestId = 0
        requestIdGenerator = {
            currentRequestId += 1
            return RequestId(value: currentRequestId)
        }

        self.applicationId = applicationId ?? Parse.validatedCurrentConfiguration().applicationId!
        self.clientKey = clientKey ?? Parse.validatedCurrentConfiguration().clientKey

        self.host = components.url!
    }
}

extension Client {
    // Swift is lame and doesn't allow storage to directly be in extensions.
    // So we create an inner struct to wrap it up.
    fileprivate class Storage {
        private static var __once: () = {
                sharedStorage = Storage()
            }()
        static var onceToken: Int = 0
        static var sharedStorage: Storage!
        static var shared: Storage {
            _ = Storage.__once
            return sharedStorage
        }

        let queue: DispatchQueue = DispatchQueue(label: "com.parse.livequery.client.storage", attributes: [])
        var client: Client?
    }

    /// Gets or sets shared live query client to be used for default subscriptions
    @objc(sharedClient)
    public static var shared: Client! {
        get {
            let storage = Storage.shared
            var client: Client?
            storage.queue.sync {
                client = storage.client
                if client == nil {
                    let configuration = Parse.validatedCurrentConfiguration()
                    client = Client(
                        server: configuration.server,
                        applicationId: configuration.applicationId,
                        clientKey: configuration.clientKey
                    )
                    storage.client = client
                }
            }
            return client
        }
        set {
            let storage = Storage.shared
            storage.queue.sync {
                storage.client = newValue
            }
        }
    }
}

extension Client {
    /**
     Registers a query for live updates, using the default subscription handler

     - parameter query:        The query to register for updates.
     - parameter subclassType: The subclass of PFObject to be used as the type of the Subscription.
     This parameter can be automatically inferred from context most of the time

     - returns: The subscription that has just been registered
     */
    public func subscribe<T>(
        _ query: PFQuery<T>,
        subclassType: T.Type = T.self
        ) -> Subscription<T> where T: PFObject {
        return subscribe(query, handler: Subscription<T>())
    }

    /**
     Registers a query for live updates, using a custom subscription handler

     - parameter query:   The query to register for updates.
     - parameter handler: A custom subscription handler.

     - returns: Your subscription handler, for easy chaining.
    */
    public func subscribe<T>(
        _ query: PFQuery<T.PFObjectSubclass>,
        handler: T
        ) -> T where T: SubscriptionHandling {
        let subscriptionRecord = SubscriptionRecord(
            query: query,
            requestId: requestIdGenerator(),
            handler: handler
        )
        subscriptions.append(subscriptionRecord)
        
        if socket?.readyState == .OPEN {
            _ = sendOperationAsync(.subscribe(requestId: subscriptionRecord.requestId, query: query as! PFQuery<PFObject>,
            sessionToken: PFUser.current()?.sessionToken))
        } else if socket == nil || socket?.readyState != .CONNECTING {
            if !userDisconnected {
                reconnect()
            } else {
                debugPrint("Warning: The client was explicitly disconnected! You must explicitly call .reconnect() in order to process your subscriptions.")
            }
        }
        
        return handler
    }

    /**
     Unsubscribes all current subscriptions for a given query.

     - parameter query: The query to unsubscribe from.
     */
    @objc(unsubscribeFromQuery:)
    public func unsubscribe(_ query: PFQuery<PFObject>) {
        unsubscribe { $0.query == query }
    }

    /**
     Unsubscribes from a specific query-handler pair.

     - parameter query:   The query to unsubscribe from.
     - parameter handler: The specific handler to unsubscribe from.
     */
    public func unsubscribe<T>(_ query: PFQuery<T.PFObjectSubclass>, handler: T) where T: SubscriptionHandling {
        unsubscribe { $0.query == query && $0.subscriptionHandler === handler }
    }

    func unsubscribe(matching matcher: @escaping (SubscriptionRecord) -> Bool) {
        subscriptions.filter {
            matcher($0)
            }.forEach {
                _ = sendOperationAsync(.unsubscribe(requestId: $0.requestId))
        }
    }
    
}

extension Client {
    /**
     Reconnects this client to the server.

     This will disconnect and resubscribe all existing subscriptions. This is not required to be called the first time
     you use the client, and should usually only be called when an error occurs.
     */
    public func reconnect() {
        socket?.close()
        socket = {
            let socket: SRWebSocket = SRWebSocket(url: host)
            socket.delegate = self
            socket.delegateDispatchQueue = queue
            socket.open()
            userDisconnected = false
            return socket
        }()
    }

    /**
     Explicitly disconnects this client from the server.

     This does not remove any subscriptions - if you `reconnect()` your existing subscriptions will be restored.
     Use this if you wish to dispose of the live query client.
     */
    public func disconnect() {
        guard let socket = socket
            else {
                return
        }
        socket.close()
        self.socket = nil
        userDisconnected = true
    }
}
