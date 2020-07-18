//
//  AppDelegate.swift
//  CalendarSiren
//
//  Created by David Beckemeyer on 5/29/20.
//  Copyright © 2020 telEvolution. All rights reserved.
//

import Cocoa
import AVFoundation
import CoreAudioKit
import EventKit

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    let statusItem = NSStatusBar.system.statusItem(withLength:NSStatusItem.squareLength)
    let popover = NSPopover()
    var audioPlayer : AVAudioPlayer?
    var savedVolume : Float = 0
    var nextEventTimer : Timer?
    var dailyTimer : Timer?
    var firstEventDate : Date?
    var firstEvent : EKEvent?
    var selectedCalendar : String?
    var stopTimerDate : Date?
    var stopTimer : Timer?
    var skipToDate : Date?
    let kSelectedCalendarKey = "selectedCalendar"
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        savedVolume = NSSound.systemVolume
        print("saved volume: \(savedVolume)")
        
        EventStore.sharedInstance.requestAccess()
        
        selectedCalendar = UserDefaults.standard.object(forKey:kSelectedCalendarKey) as? String
        if let button = statusItem.button {
            button.image = NSImage(named:NSImage.Name("StatusBarButtonImage"))
            button.action = #selector(togglePopover(_:))
        }
        let frame = CGRect(origin: .zero, size: CGSize(width: 400, height: 400))
        let viewController = PopupViewController()
        viewController.view.frame = frame
        
        popover.contentViewController = viewController

        constructMenu()

        NotificationCenter.default.addObserver(self, selector: #selector(storeChanged(notification:)), name: .EKEventStoreChanged, object: EventStore.sharedInstance.eventStore)

        if (selectedCalendar != nil) {
            loadFirstEvent()
        }
        
        /*
        let sources = EventStore.sharedInstance.eventStore.sources
        for source in sources{
            print(source.title)
            for calendar in source.calendars(for: .event){
                print(calendar.title)
            }
        }
         */
        /*
        NSSound.systemVolume = 1.0
        print("new volume: \(NSSound.systemVolume)")
        playSound(file: "siren1", ext: "wav")
        showPopover(sender: selectedCalendar)
         */
      
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
        stopSound()
    }

    func constructMenu() {
        let menu = NSMenu()
        
        menu.addItem(NSMenuItem(title: "Settings", action: #selector(AppDelegate.togglePopover(_:)), keyEquivalent: "S"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit Siren", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusItem.menu = menu
    }

    @objc func togglePopover(_ sender: Any?) {
        if popover.isShown {
            closePopover(sender: sender)
        } else {
            showPopover(sender: sender)
        }
    }
    
    func showPopover(sender: Any?) {
        if let button = statusItem.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
        }
    }
    
    func closePopover(sender: Any?) {
        popover.performClose(sender)
        stopSound()
    }

    @objc func fireEvent(_ timer: Timer ) {
        print("fireEvent!!")
        guard let event = timer.userInfo as? EKEvent else { return }
        let formatter2 = DateFormatter()
        formatter2.timeStyle = .short
        formatter2.dateStyle = .medium
        print("Timer fired on event: \(formatter2.string(from: event.startDate)) \(event.title!)")
        if (skipToDate != nil && event.startDate < skipToDate!) {
            DispatchQueue.main.async {
                self.loadFirstEvent()
            }
            return
        }
        if (NSSound.systemVolume < 1.0) {
            savedVolume = NSSound.systemVolume
            print("saved volume: \(savedVolume)")
        }
        NSSound.systemVolume = 1.0
        print("new volume: \(NSSound.systemVolume)")
        playSound(file: "siren1", ext: "wav")
        showPopover(sender: timer)
        stopTimerDate = Calendar.current.date(byAdding: .minute, value: 1, to: event.startDate)
        print("stopTimerDate: \(formatter2.string(from: stopTimerDate!))")
        if (stopTimer != nil) {
            stopTimer?.invalidate()
        }
        stopTimer = Timer(fireAt: stopTimerDate!, interval: 0, target: self, selector: #selector(stopSoundAction(_:)), userInfo: nil, repeats: false)
        RunLoop.main.add(stopTimer!, forMode: .common)
    }
    
    func playSound(file:String, ext:String) -> Void {
    
        let url = Bundle.main.url(forResource: file, withExtension: ext)!
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer!.prepareToPlay()
            audioPlayer?.numberOfLoops = -1
            audioPlayer!.play()
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    func stopSound() {
        var currentlyPlaying : Bool = false
        if (audioPlayer != nil) {
            currentlyPlaying = audioPlayer!.isPlaying;
            audioPlayer?.stop()
        }
        if (currentlyPlaying) {
            NSSound.systemVolume = savedVolume
            print("restored volume: \(savedVolume)")
            
            if (firstEvent != nil) {
                if (firstEvent!.endDate != nil) {
                    skipToDate = firstEvent!.endDate
                } else if (firstEventDate != nil) {
                    skipToDate = Calendar.current.date(byAdding: .minute, value: 12, to: firstEventDate!)!
                }
            }
            DispatchQueue.main.async {
                self.loadFirstEvent()
            }
        
            if (stopTimer != nil) {
                stopTimer?.invalidate()
            }
        }
    }
    
    @objc func dailyRun(_ timer: Timer ) {
        DispatchQueue.main.async {
            self.loadFirstEvent()
        }
    }
    
    @objc func stopSoundAction(_ timer: Timer ) {
        print("stopSoundAction timer fired")
        stopSound()
    }
    
    func loadFirstEvent() {
        var startDate = Date()
        
        let formatter2 = DateFormatter()
        formatter2.timeStyle = .short
        formatter2.dateStyle = .medium
        
        print("loading calendars \(formatter2.string(from: startDate))")

        let calendars = EventStore.sharedInstance.eventStore.calendars(for: .event)

        if (skipToDate != nil && startDate < skipToDate!) {
            startDate = skipToDate!
        }
       
        let startDateComponents = Calendar.current.dateComponents(
            [ .timeZone,
              .year, .month, .day,
              .hour, .minute, .second],
            from: startDate)
     
        let endDateComponents = DateComponents(calendar: Calendar.current,
                                               timeZone: startDateComponents.timeZone, year: startDateComponents.year,
                                               month: startDateComponents.month,
                                               day: startDateComponents.day,
                                               hour: 19)
        let endDate = Calendar.current.date(from: endDateComponents)
        print("End date: \(formatter2.string(from: endDate!))")
        
        //let endDate = Calendar.current.date(byAdding: .hour, value: 24, to: startDate)
        
        firstEventDate = nil
        if (startDate < endDate!) {
            for calendar in calendars {
                //print("\(calendar.title) - \(calendar.source.title)")
                
                if (selectedCalendar != nil && calendar.title == selectedCalendar) {
                    
                    let predicate = EventStore.sharedInstance.eventStore.predicateForEvents(withStart: startDate, end: endDate!, calendars: [calendar])
                    let matchingEvents = EventStore.sharedInstance.eventStore.events(matching: predicate)
                    
                    // iterate through events
                    for event in matchingEvents {
                        if (!event.isAllDay && event.hasNotes && event.status != EKEventStatus.canceled &&
                            event.startDate > startDate) {
                            var accepted: Bool = true
                            if (event.hasAttendees) {
                                for attendee in event.attendees! {
                                    print("attendee: \(attendee.name ?? "??")")
                                    if (attendee.isCurrentUser) {
                                        accepted = (attendee.participantStatus == EKParticipantStatus.accepted)
                                    }
                                }
                            }
                            if (!accepted) {
                                print("status: not-accepted")
                                continue
                            }
                            var notes = ""
                            if (event.notes != nil) {
                                notes = event.notes!
                            }
                            print("Checking event: \(formatter2.string(from: event.startDate)) \(event.title!) : \(notes)")
                            if (notes.contains("meet.google.com") ||
                                notes.contains("hangouts.google.com") ||
                                notes.contains("zoom.us") ||
                                notes.contains("doxy.me")) {
                                if (firstEventDate == nil || event.startDate < firstEventDate!) {
                                    firstEventDate = Calendar.current.date(byAdding: .minute, value: -10, to: event.startDate)
                                    firstEvent = event
                                }
                            }
                        }
                    }
                }
            }
        }

        if (nextEventTimer != nil) {
            nextEventTimer?.invalidate()
        }
        print("Time now: \(formatter2.string(from: Date()))")
        if (firstEventDate == nil) {
            print("No events upcoming")
            (popover.contentViewController as! PopupViewController).label!.stringValue = "No events upcoming"
        } else {
            print("First event: \(formatter2.string(from: firstEvent!.startDate)) \(firstEvent!.title!)")
            print("Timer: \(formatter2.string(from: firstEventDate!))")
            (popover.contentViewController as! PopupViewController).label!.stringValue = "\(formatter2.string(from: firstEvent!.startDate)) \(firstEvent!.title!)"
            //let fireDate = Date().addingTimeInterval(5)
            nextEventTimer = Timer(fireAt: firstEventDate!, interval: 0, target: self, selector: #selector(fireEvent), userInfo: firstEvent, repeats: false)
            RunLoop.main.add(nextEventTimer!, forMode: .common)
        }
        var tomorrow = Calendar.current.date(byAdding: .hour, value: 24, to: startDate)
        let tomorrowDateComponents = Calendar.current.dateComponents(
            [ .timeZone,
              .year, .month, .day,
              .hour, .minute, .second],
            from: tomorrow!)
        tomorrow = Calendar.current.date(from: DateComponents(calendar: Calendar.current,
                                                              timeZone: startDateComponents.timeZone, year: tomorrowDateComponents.year,
                                                              month: tomorrowDateComponents.month,
                                                              day: tomorrowDateComponents.day,
                                                              hour: 5))
        print("Tomorrow date: \(formatter2.string(from: tomorrow!))")
        
        if (dailyTimer != nil) {
            dailyTimer?.invalidate()
        }
        dailyTimer = Timer(fireAt: tomorrow!, interval: 0, target: self, selector: #selector(dailyRun), userInfo: nil, repeats: false)
        RunLoop.main.add(dailyTimer!, forMode: .common)
        
    }
    
    func selectCalendar(title : String) {
        selectedCalendar = title
        UserDefaults.standard.set(selectedCalendar, forKey: kSelectedCalendarKey)
        DispatchQueue.main.async {
            self.loadFirstEvent()
        }
    }
    
    @objc private func storeChanged(notification: NSNotification) {
        debugPrint("storeChanged \(notification)")
        DispatchQueue.main.async {
            self.loadFirstEvent()
        }
    }


    func loadTestEvents() {

        let startDate = Calendar.current.date(byAdding: .hour, value: -4, to: Date())!

        let formatter2 = DateFormatter()
        formatter2.timeStyle = .short
        formatter2.dateStyle = .medium
        
        print("loading calendars \(formatter2.string(from: startDate))")
        
        let calendars = EventStore.sharedInstance.eventStore.calendars(for: .event)
        
        let startDateComponents = Calendar.current.dateComponents(
            [ .timeZone,
              .year, .month, .day,
              .hour, .minute, .second],
            from: startDate)
        
        let endDateComponents = DateComponents(calendar: Calendar.current,
                                               timeZone: startDateComponents.timeZone, year: startDateComponents.year,
                                               month: startDateComponents.month,
                                               day: startDateComponents.day,
                                               hour: 19)
        let endDate = Calendar.current.date(from: endDateComponents)
        print("End date: \(formatter2.string(from: endDate!))")
        
        //let endDate = Calendar.current.date(byAdding: .hour, value: 24, to: startDate)
        
        if (startDate < endDate!) {
            for calendar in calendars {
                //print("\(calendar.title) - \(calendar.source.title)")
                
                if (selectedCalendar != nil && calendar.title == selectedCalendar) {
                    
                    let predicate = EventStore.sharedInstance.eventStore.predicateForEvents(withStart: startDate, end: endDate!, calendars: [calendar])
                    let matchingEvents = EventStore.sharedInstance.eventStore.events(matching: predicate)
                    
                    // iterate through events
                    for event in matchingEvents {
                        if (!event.isAllDay && event.hasNotes && event.status != EKEventStatus.canceled &&
                            event.startDate > startDate) {
                            var notes = ""
                            if (event.notes != nil) {
                                notes = event.notes!
                            }
                            print("Checking event: \(formatter2.string(from: event.startDate)) \(event.title!) : \(notes)")
                            if (event.title.contains("Family")) {
                                if (event.hasAttendees) {
                                    for attendee in event.attendees! {
                                        print("attendee: \(attendee.name ?? "??")")
                                        if (attendee.isCurrentUser) {
                                            if (attendee.participantStatus == EKParticipantStatus.accepted) {
                                                print("status: accepted");
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
