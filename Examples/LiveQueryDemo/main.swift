//
//  main.swift
//  ParseLiveQuery
//
//  Created by Richard Ross III on 10/22/15.
//  Copyright © 2015 parse. All rights reserved.
//

import Foundation
import Parse
import ParseLiveQuery

Message.registerSubclass()
Room.registerSubclass()

Parse.initializeWithConfiguration(ParseClientConfiguration {
    $0.applicationId = "myAppId"
    $0.server = "http://localhost:1337/parse"
    })

let liveQueryClient = ParseLiveQuery.Client(server: "http://localhost:1337")

class ChatRoomManager {
    private var currentChatRoom: Room?
    private var subscription: Subscription<Message>?

    var connected: Bool { return currentChatRoom != nil }
    var messagesQuery: PFQuery {
        return (Message.query()?
            .whereKey("room_name", equalTo: currentChatRoom!.name!)
            .orderByAscending("createdAt"))!
    }

    func connectToChatRoom(room: String) {
        if connected {
            disconnectFromChatRoom()
        }

        Room.query()?.whereKey("name", equalTo: room).getFirstObjectInBackground().continueWithBlock { task in
            self.currentChatRoom = task.result as? Room
            print("Connected to room \(self.currentChatRoom?.name ?? "null")")

            self.printPriorMessages()
            self.subscribeToUpdates()

            return nil
        }
    }

    func disconnectFromChatRoom() {
        liveQueryClient.unsubscribe(messagesQuery, handler: subscription!)
    }

    func sendMessage(msg: String) {
        let message = Message()
        message.author = PFUser.currentUser()
        message.authorName = message.author?.username
        message.message = msg
        message.room = currentChatRoom
        message.roomName = currentChatRoom?.name

        message.saveInBackground()
    }

    func printPriorMessages() {
        messagesQuery.findObjectsInBackground().continueWithBlock() { task in
            (task.result as? [Message])?.forEach(self.printMessage)

            return nil
        }
    }

    func subscribeToUpdates() {
        subscription = liveQueryClient
            .subscribe(messagesQuery)
            .handle(Event.Created) { _, message in
                self.printMessage(message)
        }
    }

    private func printMessage(message: Message) {
        let createdAt = message.createdAt ?? NSDate()

        print("\(createdAt) \(message.authorName ?? "unknown"): \(message.message ?? "")")
    }
}

class InputManager {
    let stdinChannel = dispatch_io_create(DISPATCH_IO_STREAM, STDIN_FILENO, dispatch_get_main_queue()) { _ in }
    let chatManager: ChatRoomManager

    init(chatManager: ChatRoomManager) {
        self.chatManager = chatManager

        dispatch_io_set_low_water(stdinChannel, 1)
        dispatch_io_read(stdinChannel, 0, Int.max, dispatch_get_main_queue(), handleInput)
    }

    private func handleInput(done: Bool, data: dispatch_data_t?, error: Int32) {
        guard
            let data = data as? NSData,
            let inputString = String(data: data, encoding: NSUTF8StringEncoding)?
                .stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()) else {
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
    String(UTF8String: getpass($0))!
}

let chatManager = ChatRoomManager()
let inputManager = InputManager(chatManager: chatManager)

PFUser.logInWithUsernameInBackground(username, password: password).continueWithBlock { task in
    print("Enter chat room to connect to: ")
    return nil
}

dispatch_main()
