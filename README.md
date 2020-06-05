#  CalendarSiren

A little Menu Bar Application to signal persistent alarms for certain events in a calendar

## Description

I  found myself missing Zoom and Google Hangouts meetings because the normal phone calendar alarms are too subtle, especially when the phone is on silent.

When it's time to get ready for a Zoom or Google Hangouts conference call, this simple menubar app makes a lot of noise and keeps making noise until you stop it.


## Usage

The first time you run the app, it will prompt for permission to access your calendars (it only reads them).

Click the menubar icon to open the menu:

![Menubar](screenshots/menubar.png)

Click _Settings_ to open the main popup user interface

![Popup](screenshots/popup.png)

Choose the Calendar you want the app to use.

That's pretty much it. The app scans for events with Zoom or Google Hangout (Google Meet) links and triggers 10 minutes before the event. To silence the app, close the popup.

## What it does

The app uses [EventKit](https://developer.apple.com/documentation/eventkit). It loads calendars into a popup button. When a desired calendar is selected, the app sets up to scan that calender for events that have  Zoom or Google Hangouts/Meet links. If there are any, it sets an alarm for the next upcoming such event. 10 minutes before the event, when the alarm for the event is fired, it cranks the volume of the Mac to the max and plays a load siren alarm. Once that alarm fires it looks for the next one, if any. Otherwise it will scan again the next day (at 5AM localtime).

The app also listens for changes to calendars and updates appropriately for any changes.

## TODO - or maybe not (limitiations)

It only supports scanning one selected calendar. It is hardcoded to look at daytime hours 7am-7pm localtime. The 10-minute warning time is hard-coded.

The meeting urls scanning is hard-coded to look for Zoom and Google Hangout/Meet. You can add more in the code but it could also be part of the settings in the UI.
