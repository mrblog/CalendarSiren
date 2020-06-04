//
//  EventStore.swift
//  CalendarSiren
//
//  Created by David Beckemeyer on 6/1/20.
//  Copyright © 2020 telEvolution. All rights reserved.
//

import Cocoa
import EventKit

private let _singletonSharedInstance = EventStore()

class EventStore {

    let eventStore = EKEventStore ()
    
    class var sharedInstance : EventStore {
        return _singletonSharedInstance
    }
    
   func requestAccess() {
        switch EKEventStore.authorizationStatus(for: .event) {
        case .authorized:
            print("Access granted")
            
        case .denied:
            print("Access denied")
            
        case .notDetermined:
            eventStore.requestAccess(to: .event, completion: {
                (granted, error) in
                
                if granted {
                    print("granted \(granted)")
                    
                }else {
                    print("error \(String(describing: error))")
                }
                
            })
        default:
            print("Case default")
        }
    }
}
