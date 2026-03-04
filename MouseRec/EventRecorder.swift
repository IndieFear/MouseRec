//
//  EventRecorder.swift
//  MouseRec
//
//  Created by Stanislas Peridy on 11/11/2025.
//

import Foundation
import CoreGraphics
import AppKit
import Combine

// Structure pour stocker un événement enregistré
struct RecordedEvent {
    let type: CGEventType
    let timestamp: TimeInterval
    let location: CGPoint?
    let keyCode: Int64?
    let flags: CGEventFlags?
    let mouseButton: CGMouseButton?
}

class EventRecorder: ObservableObject {
    @Published var isRecording = false
    @Published var isPlaying = false
    
    private var recordedEvents: [RecordedEvent] = []
    private var startTime: TimeInterval = 0
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    /// Pointeur opaque retenu pour le callback - doit être libéré dans stopRecording
    private var tapRefcon: UnsafeMutableRawPointer?
    
    // Paramètres de lecture
    var playbackSpeed: Double = 1.0
    var loopMode: LoopMode = .once
    var repeatCount: Int = 1
    
    enum LoopMode {
        case once
        case loop
        case custom
    }
    
    // Check accessibility permissions
    func checkAccessibilityPermissions() -> Bool {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        return AXIsProcessTrustedWithOptions(options)
    }
    
    // Start recording
    func startRecording() {
        guard checkAccessibilityPermissions() else {
            print("Accessibility permissions required")
            return
        }
        
        recordedEvents.removeAll()
        startTime = Date().timeIntervalSince1970
        isRecording = true
        
        // Create an event tap to capture all events
        let mouseMask: CGEventMask = (1 << CGEventType.mouseMoved.rawValue) |
                                      (1 << CGEventType.leftMouseDown.rawValue) |
                                      (1 << CGEventType.leftMouseUp.rawValue) |
                                      (1 << CGEventType.rightMouseDown.rawValue) |
                                      (1 << CGEventType.rightMouseUp.rawValue)
        
        let keyboardMask: CGEventMask = (1 << CGEventType.keyDown.rawValue) |
                                         (1 << CGEventType.keyUp.rawValue)
        
        let dragMask: CGEventMask = (1 << CGEventType.leftMouseDragged.rawValue) |
                                     (1 << CGEventType.rightMouseDragged.rawValue)
        
        let scrollMask: CGEventMask = (1 << CGEventType.scrollWheel.rawValue)
        
        let eventMask: CGEventMask = mouseMask | keyboardMask | dragMask | scrollMask
        
        let callback: CGEventTapCallBack = { proxy, type, event, refcon in
            // Sécurité : refcon peut être nil si le tap reçoit un événement après désactivation
            guard let refcon = refcon else {
                return Unmanaged.passRetained(event)
            }
            
            let recorder = Unmanaged<EventRecorder>.fromOpaque(refcon).takeUnretainedValue()
            recorder.recordEvent(type: type, event: event)
            return Unmanaged.passRetained(event)
        }
        
        // passRetained : garde l'instance vivante tant que le tap est actif
        // (évite le crash si un événement arrive après désallocation)
        tapRefcon = Unmanaged.passRetained(self).toOpaque()
        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: callback,
            userInfo: tapRefcon
        )
        
        guard let eventTap = eventTap else {
            print("Failed to create event tap")
            if let refcon = tapRefcon {
                Unmanaged<EventRecorder>.fromOpaque(refcon).release()
                tapRefcon = nil
            }
            isRecording = false
            return
        }
        
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource!, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
        
        print("Recording started")
    }
    
    // Record an event
    private func recordEvent(type: CGEventType, event: CGEvent) {
        let currentTime = Date().timeIntervalSince1970
        let relativeTime = currentTime - startTime
        
        let location = event.location
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let flags = event.flags
        
        // Filter application hotkeys (Cmd+Shift+R and Cmd+Shift+P)
        if type == .keyDown || type == .keyUp {
            let hasCmdShift = flags.contains(.maskCommand) && flags.contains(.maskShift)
            let isRKey = keyCode == 15  // R key
            let isPKey = keyCode == 35  // P key
            
            if hasCmdShift && (isRKey || isPKey) {
                // Don't record application hotkeys
                return
            }
        }
        
        var mouseButton: CGMouseButton? = nil
        if type == .leftMouseDown || type == .leftMouseUp || type == .leftMouseDragged {
            mouseButton = .left
        } else if type == .rightMouseDown || type == .rightMouseUp || type == .rightMouseDragged {
            mouseButton = .right
        }
        
        let recordedEvent = RecordedEvent(
            type: type,
            timestamp: relativeTime,
            location: location,
            keyCode: keyCode,
            flags: flags,
            mouseButton: mouseButton
        )
        
        recordedEvents.append(recordedEvent)
    }
    
    // Stop recording
    func stopRecording() {
        if let eventTap = eventTap, let runLoopSource = runLoopSource {
            CGEvent.tapEnable(tap: eventTap, enable: false)
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
            self.eventTap = nil
            self.runLoopSource = nil
        }
        // Libérer le retain passé au callback
        if let refcon = tapRefcon {
            Unmanaged<EventRecorder>.fromOpaque(refcon).release()
            tapRefcon = nil
        }
        
        isRecording = false
        print("Recording stopped - \(recordedEvents.count) events captured")
    }
    
    deinit {
        // Critique : désactiver le tap avant désallocation pour éviter un crash
        if let eventTap = eventTap, let runLoopSource = runLoopSource {
            CGEvent.tapEnable(tap: eventTap, enable: false)
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        }
        if let refcon = tapRefcon {
            Unmanaged<EventRecorder>.fromOpaque(refcon).release()
        }
    }
    
    // Play recording
    func playRecording() {
        guard !recordedEvents.isEmpty else {
            print("No events to replay")
            return
        }
        
        guard checkAccessibilityPermissions() else {
            print("Accessibility permissions required")
            return
        }
        
        isPlaying = true
        
        Task {
            await performPlayback()
        }
    }
    
    // Perform playback of events
    private func performPlayback() async {
        let iterations: Int
        
        switch loopMode {
        case .once:
            iterations = 1
        case .loop:
            iterations = Int.max // Infinite loop
        case .custom:
            iterations = repeatCount
        }
        
        for iteration in 0..<iterations {
            guard isPlaying else { break }
            
            print("Playing - iteration \(iteration + 1)")
            
            var previousTimestamp: TimeInterval = 0
            
            for event in recordedEvents {
                guard isPlaying else { break }
                
                // Calculate delay between events
                let delay = (event.timestamp - previousTimestamp) / playbackSpeed
                if delay > 0 {
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
                
                // Replay the event
                replayEvent(event)
                previousTimestamp = event.timestamp
            }
            
            // Small pause between iterations
            if iteration < iterations - 1 && isPlaying {
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            }
        }
        
        await MainActor.run {
            isPlaying = false
            print("Playback finished")
        }
    }
    
    // Replay a specific event
    private func replayEvent(_ recordedEvent: RecordedEvent) {
        guard let location = recordedEvent.location else { return }
        
        var event: CGEvent?
        
        switch recordedEvent.type {
        case .mouseMoved:
            event = CGEvent(mouseEventSource: nil, mouseType: .mouseMoved, mouseCursorPosition: location, mouseButton: .left)
            
        case .leftMouseDown:
            event = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown, mouseCursorPosition: location, mouseButton: .left)
            
        case .leftMouseUp:
            event = CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp, mouseCursorPosition: location, mouseButton: .left)
            
        case .rightMouseDown:
            event = CGEvent(mouseEventSource: nil, mouseType: .rightMouseDown, mouseCursorPosition: location, mouseButton: .right)
            
        case .rightMouseUp:
            event = CGEvent(mouseEventSource: nil, mouseType: .rightMouseUp, mouseCursorPosition: location, mouseButton: .right)
            
        case .leftMouseDragged:
            event = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDragged, mouseCursorPosition: location, mouseButton: .left)
            
        case .rightMouseDragged:
            event = CGEvent(mouseEventSource: nil, mouseType: .rightMouseDragged, mouseCursorPosition: location, mouseButton: .right)
            
        case .keyDown, .keyUp:
            if let keyCode = recordedEvent.keyCode {
                event = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(keyCode), keyDown: recordedEvent.type == .keyDown)
                if let flags = recordedEvent.flags {
                    event?.flags = flags
                }
            }
            
        case .scrollWheel:
            // Scroll handling (simplified)
            break
            
        default:
            break
        }
        
        event?.post(tap: .cghidEventTap)
    }
    
    // Stop playing
    func stopPlaying() {
        isPlaying = false
        print("Playback stopped")
    }
    
    // Clear recording
    func clearRecording() {
        recordedEvents.removeAll()
        print("Recording cleared")
    }
    
    // Return the number of recorded events
    func eventCount() -> Int {
        return recordedEvents.count
    }
}

