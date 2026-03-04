//
//  HotkeyManager.swift
//  MouseRec
//
//  Created by Stanislas Peridy on 11/11/2025.
//

import Foundation
import AppKit
import Carbon

class HotkeyManager {
    static let shared = HotkeyManager()
    
    private var eventHandler: EventHandlerRef?
    private var recordHotkey: (id: EventHotKeyID, ref: EventHotKeyRef?)?
    private var playHotkey: (id: EventHotKeyID, ref: EventHotKeyRef?)?
    
    var onRecordHotkey: (() -> Void)?
    var onPlayHotkey: (() -> Void)?
    
    private init() {}
    
    func registerHotkeys() {
        // Cmd + Shift + R pour enregistrer/arrêter
        let recordKeyCode: UInt32 = 15 // R key
        let recordModifiers: UInt32 = UInt32(cmdKey | shiftKey)
        
        // Cmd + Shift + P pour play/stop
        let playKeyCode: UInt32 = 35 // P key
        let playModifiers: UInt32 = UInt32(cmdKey | shiftKey)
        
        var recordHotkeyID = EventHotKeyID(signature: OSType(UTGetOSTypeFromString("rcrd" as CFString)), id: 1)
        var playHotkeyID = EventHotKeyID(signature: OSType(UTGetOSTypeFromString("play" as CFString)), id: 2)
        
        var recordRef: EventHotKeyRef?
        var playRef: EventHotKeyRef?
        
        // Enregistre les hotkeys
        RegisterEventHotKey(recordKeyCode, recordModifiers, recordHotkeyID, GetApplicationEventTarget(), 0, &recordRef)
        RegisterEventHotKey(playKeyCode, playModifiers, playHotkeyID, GetApplicationEventTarget(), 0, &playRef)
        
        recordHotkey = (recordHotkeyID, recordRef)
        playHotkey = (playHotkeyID, playRef)
        
        // Configure le callback
        var eventSpec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        
        InstallEventHandler(GetApplicationEventTarget(), { (nextHandler, theEvent, userData) -> OSStatus in
            guard let userData = userData else { return OSStatus(eventNotHandledErr) }
            let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
            
            var hotkeyID = EventHotKeyID()
            GetEventParameter(theEvent, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil, MemoryLayout<EventHotKeyID>.size, nil, &hotkeyID)
            
            if hotkeyID.id == 1 {
                manager.onRecordHotkey?()
            } else if hotkeyID.id == 2 {
                manager.onPlayHotkey?()
            }
            
            return noErr
        }, 1, &eventSpec, Unmanaged.passUnretained(self).toOpaque(), &eventHandler)
    }
    
    func unregisterHotkeys() {
        if let recordRef = recordHotkey?.ref {
            UnregisterEventHotKey(recordRef)
        }
        if let playRef = playHotkey?.ref {
            UnregisterEventHotKey(playRef)
        }
        if let handler = eventHandler {
            RemoveEventHandler(handler)
        }
    }
    
    deinit {
        unregisterHotkeys()
    }
}



