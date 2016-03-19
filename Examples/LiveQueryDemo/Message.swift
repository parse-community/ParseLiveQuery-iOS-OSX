//
//  Message.swift
//  ParseLiveQuery
//
//  Created by Richard Ross III on 10/27/15.
//  Copyright © 2015 parse. All rights reserved.
//

import Foundation
import Parse

class Message: PFObject, PFSubclassing {
    @NSManaged var author: PFUser?
    @NSManaged var authorName: String?
    @NSManaged var message: String?
    @NSManaged var room: PFObject?
    @NSManaged var roomName: String?

    class func parseClassName() -> String {
        return "Message"
    }
}
