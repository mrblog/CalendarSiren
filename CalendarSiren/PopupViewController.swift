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
        label!.stringValue = "My awesome label"
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
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        closeButton!.frame = NSRect(x: self.view.frame.origin.x + self.view.frame.size.width/2-50, y: 60, width: 100, height: 30)
        label!.frame = NSRect(x: self.view.frame.origin.x + self.view.frame.size.width/2-100, y: 200, width: 200, height: 44)
        refreshButton!.frame = NSRect(x: self.view.frame.origin.x + self.view.frame.size.width/2-50, y: 140, width: 100, height: 30)

    }
    
    @objc func closePopup(_ sender: Any?) {
        (NSApp.delegate as! AppDelegate).popover.performClose(sender)
    }

    @objc func refresh(_ sender: Any?) {
        (NSApp.delegate as! AppDelegate).loadFirstEvent()
    }
}
