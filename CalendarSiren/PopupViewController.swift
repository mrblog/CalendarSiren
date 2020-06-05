//
//  PopupViewController.swift
//  CalendarSiren
//
//  Created by David Beckemeyer on 5/29/20.
//  Copyright © 2020 telEvolution. All rights reserved.
//

import Cocoa

class PopupViewController: NSViewController {

    var closeButton : NSButton?
    var refreshButton : NSButton?
    var label : NSTextField?
    var calendarPopup : NSPopUpButton?
    var calendarLabel : NSTextField?
    
    override func loadView() {
        self.view = NSView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        closeButton = NSButton(frame: NSRect(x: 0, y: 0, width: 100, height: 30))
        //closeButton!.setButtonType( .switch )
        closeButton!.bezelStyle = .regularSquare
        closeButton!.title = "Close"
        closeButton!.target = self
        closeButton!.action = #selector(closePopup(_:))
        self.view.addSubview( closeButton! )
        
        label = NSTextField()
        label!.frame = NSRect(origin: .zero, size: NSSize(width: 200, height: 44))
        label!.stringValue = "(None)"
        label!.backgroundColor = .clear
        label!.isBezeled = false
        label!.isEditable = false
        label!.alignment = .center
        label!.sizeToFit()
        self.view.addSubview( label! )
        
        refreshButton = NSButton(frame: NSRect(x: 0, y: 0, width: 100, height: 30))
        refreshButton!.bezelStyle = .regularSquare
        refreshButton!.title = "Refresh"
        refreshButton!.target = self
        refreshButton!.action = #selector(refresh(_:))
        self.view.addSubview( refreshButton! )
        
        calendarPopup = NSPopUpButton()
        calendarPopup!.target = self;
        calendarPopup!.action = #selector(calendarChanged(_:))
        self.view.addSubview( calendarPopup! )

        calendarLabel = NSTextField()
        calendarLabel!.frame = NSRect(origin: .zero, size: NSSize(width: 200, height: 44))
        calendarLabel!.stringValue = "Calendar:"
        calendarLabel!.backgroundColor = .clear
        calendarLabel!.isBezeled = false
        calendarLabel!.isEditable = false
        calendarLabel!.alignment = .center
        calendarLabel!.sizeToFit()
        self.view.addSubview( calendarLabel! )
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        let calendars = EventStore.sharedInstance.eventStore.calendars(for: .event)
        for calendar in calendars {
            calendarPopup?.addItem(withTitle: calendar.title)
        }
        if ((NSApp.delegate as! AppDelegate).selectedCalendar != nil) {
            calendarPopup?.selectItem(withTitle: (NSApp.delegate as! AppDelegate).selectedCalendar!)
        }
        closeButton!.frame = NSRect(x: self.view.frame.origin.x + self.view.frame.size.width/2-50, y: 60, width: 100, height: 30)
        label!.frame = NSRect(x: self.view.frame.origin.x + self.view.frame.size.width/2-100, y: 200, width: 200, height: 44)
        refreshButton!.frame = NSRect(x: self.view.frame.origin.x + self.view.frame.size.width/2-50, y: 140, width: 100, height: 30)
        calendarPopup!.frame = NSRect(x: self.view.frame.origin.x + self.view.frame.size.width/2-40, y: 280, width: 150, height: 44)
        calendarLabel!.frame = NSRect(x: self.view.frame.origin.x + self.view.frame.size.width/2-140, y: 267, width: 100, height: 44)

    }
    
    @objc func closePopup(_ sender: Any?) {
        (NSApp.delegate as! AppDelegate).closePopover(sender: sender)
    }

    @objc func refresh(_ sender: Any?) {
        (NSApp.delegate as! AppDelegate).loadFirstEvent()
    }
    
    @objc func calendarChanged(_ sender: Any?) {
        let menuItem = (sender as! NSPopUpButton).selectedItem
        print("calendarChanged: \(menuItem!.title)")
        (NSApp.delegate as! AppDelegate).selectCalendar(title: menuItem!.title)
    }
}
