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
import ParseLiveQuery

Message.registerSubclass()
Room.registerSubclass()

Parse.initialize(with: ParseClientConfiguration {
    $0.applicationId = "myAppId"
    $0.clientKey = "myClientKey"
    $0.server = "http://localhost:1337/parse"
    })

let liveQueryClient = ParseLiveQuery.Client()

class ChatRoomManager {
    fileprivate var currentChatRoom: Room?
    fileprivate var subscription: Subscription<Message>?

    var connected: Bool { return currentChatRoom != nil }
    var messagesQuery: PFQuery<PFObject> {
        return (Message.query()?
            .whereKey("roomName", equalTo: currentChatRoom!.name!)
            .order(byAscending: "createdAt"))!
    }

    func connectToChatRoom(_ room: String) {
        if connected {
            disconnectFromChatRoom()
        }

        Room.query()?.whereKey("name", equalTo: room).getFirstObjectInBackground() { task, error in
            self.currentChatRoom = task as? Room
            print("Connected to room \(self.currentChatRoom?.name ?? "null")")

            self.printPriorMessages()
            self.subscribeToUpdates()
        }
    }

    func disconnectFromChatRoom() {
        liveQueryClient.unsubscribe(messagesQuery, handler: subscription!)
    }

    func sendMessage(_ msg: String) {
        let message = Message()
        message.author = PFUser.current()
        message.authorName = message.author?.username
        message.message = msg
        message.room = currentChatRoom
        message.roomName = currentChatRoom?.name

        message.saveInBackground()
    }

    func printPriorMessages() {
        messagesQuery.findObjectsInBackground() { task, error in
            (task as? [Message])?.forEach(self.printMessage)
        }
    }

    func subscribeToUpdates() {
        subscription = liveQueryClient.subscribe(messagesQuery).handle(Event.created)  { _, message in
            self.printMessage(message)
        }
    }

    fileprivate func printMessage(_ message: Message) {
        let createdAt = message.createdAt ?? Date()

        print("\(createdAt) \(message.authorName ?? "unknown"): \(message.message ?? "")")
    }
}

class InputManager {
    let stdinChannel = DispatchIO(type: .stream, fileDescriptor: STDIN_FILENO, queue: .main, cleanupHandler: { _ in })
    let chatManager: ChatRoomManager

    init(chatManager: ChatRoomManager) {
        self.chatManager = chatManager

        stdinChannel.setLimit(lowWater: 1)
        stdinChannel.read(offset: 0, length: Int.max, queue: DispatchQueue.main, ioHandler: handleInput)
    }

    fileprivate func handleInput(_ done: Bool, data: DispatchData?, error: Int32) {
        guard
            let stringC: String? = data?.withUnsafeBytes(body: {(b: UnsafePointer<UInt8>) -> String? in
                return String(cString: b)
            }) ,
            let inputString = stringC?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) else {
                    NSLog("something went wrong")
                    return
        }

        if chatManager.connected {
            chatManager.sendMessage(inputString)
        } else {
            chatManager.connectToChatRoom(inputString)
        }
    }
}

print("Enter username: ")

let username = readLine()!
let password = "Enter password for \(username): ".withCString {
    String(validatingUTF8: getpass($0))!
}

let chatManager = ChatRoomManager()
let inputManager = InputManager(chatManager: chatManager)

PFUser.logInWithUsername(inBackground: username, password: password, block: { task, error in
    if error == nil {
        print("Enter chat room to connect to: ")
    } else {
        NSLog("Loging error: \(error)")
    }
})

dispatchMain()
