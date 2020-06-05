//
//  AppDelegate.swift
//  CalendarSiren
//
//  Created by David Beckemeyer on 5/29/20.
//  Copyright © 2020 telEvolution. All rights reserved.
//

import Cocoa
import AVFoundation
import AudioToolbox
import EventKit

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    let statusItem = NSStatusBar.system.statusItem(withLength:NSStatusItem.squareLength)
    let popover = NSPopover()
    var audioPlayer : AVAudioPlayer?
    var savedVolume : Int32 = 0
    var nextEventTimer : Timer?
    var dailyTimer : Timer?
    var firstEventDate : Date?
    var firstEvent : EKEvent?
    var selectedCalendar : String?
    let kSelectedCalendarKey = "selectedCalendar"
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        savedVolume = macvolume_cmd(set:0, vol:100)
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

    @objc func fire(_ sender: Any?) {
        print("FIRE!!!")
       
        print("new volume: \(macvolume_cmd(set: 1, vol: 100))")
        playSound(file: "siren1", ext: "wav")
        showPopover(sender: sender)
    }
    
    
    @objc func fireEvent(_ timer: Timer ) {
        print("fireEvent!!")
        guard let event = timer.userInfo as? EKEvent else { return }
        let formatter2 = DateFormatter()
        formatter2.timeStyle = .medium
        print("Timer fired on event: \(formatter2.string(from: event.startDate)) \(event.title!)")
        print("new volume: \(macvolume_cmd(set: 1, vol: 100))")
        playSound(file: "siren1", ext: "wav")
        showPopover(sender: timer)
    }
    
    func playSound(file:String, ext:String) -> Void {
    
        let url = Bundle.main.url(forResource: file, withExtension: ext)!
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer!.prepareToPlay()
            audioPlayer?.numberOfLoops = -1;
            audioPlayer!.play()
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    func stopSound() {
        if (audioPlayer != nil) {
            audioPlayer?.stop();
        }
        if (macvolume_cmd(set:0, vol:100) != savedVolume) {
            print("restored volume: \(macvolume_cmd(set: 1, vol: savedVolume))")
            loadFirstEvent()
        }
    }
    
    @objc func dailyRun(_ timer: Timer ) {
        loadFirstEvent()
    }
    
    func loadFirstEvent() {
        print("loading calendars")
        let calendars = EventStore.sharedInstance.eventStore.calendars(for: .event)
        
        let formatter2 = DateFormatter()
        formatter2.timeStyle = .medium
        
        var startDate = Date();
        if (firstEventDate != nil) {
            startDate =  Calendar.current.date(byAdding: .minute, value: 10, to: firstEventDate!)!
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
        
        firstEventDate = nil;
        for calendar in calendars {
            //print("\(calendar.title) - \(calendar.source.title)");
            
            if (selectedCalendar != nil && calendar.title == selectedCalendar) {
              
                let predicate = EventStore.sharedInstance.eventStore.predicateForEvents(withStart: startDate, end: endDate!, calendars: [calendar])
                let matchingEvents = EventStore.sharedInstance.eventStore.events(matching: predicate)
                
                // iterate through events
                for event in matchingEvents {
                    if (!event.isAllDay && event.startDate > startDate) {
                        var notes = "";
                        if (event.notes != nil) {
                            notes = event.notes!
                        }
                        print("\(formatter2.string(from: event.startDate)) \(event.title!) : \(notes)")
                        if (notes.contains("meet.google.com") ||
                            notes.contains("hangouts.google.com") ||
                            notes.contains("zoom.us")) {
                            if (firstEventDate == nil || event.startDate < firstEventDate!) {
                                firstEventDate = Calendar.current.date(byAdding: .minute, value: -10, to: event.startDate)
                                firstEvent = event
                            }
                        }
                    }
                }
            }
        }
        
        if (nextEventTimer != nil) {
            nextEventTimer?.invalidate()
        }
        if (firstEventDate == nil) {
            print("No events upcoming")
            (popover.contentViewController as! PopupViewController).label!.stringValue = "No events upcoming"
        } else {
            print("First event: \(formatter2.string(from: firstEvent!.startDate)) \(firstEvent!.title!)")
            print("Timer: \(formatter2.string(from: firstEventDate!))")
            (popover.contentViewController as! PopupViewController).label!.stringValue = "\(formatter2.string(from: firstEvent!.startDate)) \(firstEvent!.title!)"
            //let fireDate = Date().addingTimeInterval(5);
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
    
    func macvolume_cmd (set: Int32, vol: Int32) -> Int32
    {
        var defaultOutputDeviceID = AudioDeviceID(0)
        var defaultOutputDeviceIDSize = UInt32(MemoryLayout.size(ofValue:defaultOutputDeviceID))
        
        var getDefaultOutputDevicePropertyAddress = AudioObjectPropertyAddress(
            mSelector: AudioObjectPropertySelector(kAudioHardwarePropertyDefaultOutputDevice),
            mScope: AudioObjectPropertyScope(kAudioObjectPropertyScopeGlobal),
            mElement: AudioObjectPropertyElement(kAudioObjectPropertyElementMaster))
        
        AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &getDefaultOutputDevicePropertyAddress,
            0,
            nil,
            &defaultOutputDeviceIDSize,
            &defaultOutputDeviceID)
        
        var volume = Float32()
        var volumeSize = UInt32(MemoryLayout.size(ofValue:volume))
        
        var volumePropertyAddress = AudioObjectPropertyAddress(
            mSelector: AudioObjectPropertySelector(kAudioHardwareServiceDeviceProperty_VirtualMasterVolume),
            mScope: AudioObjectPropertyScope(kAudioDevicePropertyScopeOutput),
            mElement: AudioObjectPropertyElement(kAudioObjectPropertyElementMaster))
        
        if (set == 1) {
            volume = Float(vol) / 100.0
            AudioHardwareServiceSetPropertyData(
                defaultOutputDeviceID,
                &volumePropertyAddress,
                0,
                nil,
                volumeSize,
                &volume)
        }
        
        AudioHardwareServiceGetPropertyData(
            defaultOutputDeviceID,
            &volumePropertyAddress,
            0,
            nil,
            &volumeSize,
            &volume)
        let ivol = Int32(round(volume*100.0))
        return ivol
    }
    
    func selectCalendar(title : String) {
        selectedCalendar = title;
        UserDefaults.standard.set(selectedCalendar, forKey: kSelectedCalendarKey)
        loadFirstEvent()
    }
    
    @objc private func storeChanged(notification: NSNotification) {
        debugPrint("storeChanged \(notification)")
        loadFirstEvent()
    }
}

