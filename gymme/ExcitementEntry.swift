//
//  ExcitementEntry.swift
//  gymme
//
//  Created by Salah Eddin Alshaal on 25/06/16.
//  Copyright © 2016 Salah Eddin Alshaal. All rights reserved.
//

import Foundation

class ExcitementEntry: AnyObject {
    
    var venueId: Int
    var userId: Int
    var excitementLevel: Int
    var timeStamp: NSDate
    
    init(venue: Int, user: Int, level: Int, timeStamp: NSDate){
        venueId = venue
        userId = user
        excitementLevel = level
        self.timeStamp = timeStamp
    }
}