//
//  Room.swift
//  ParseLiveQuery
//
//  Created by Richard Ross III on 10/27/15.
//  Copyright © 2015 parse. All rights reserved.
//

import Foundation
import Parse

class Room: PFObject, PFSubclassing {
    @NSManaged var name: String?

    static func parseClassName() -> String {
        return "Room"
    }
}
