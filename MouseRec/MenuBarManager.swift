//
//  MenuBarManager.swift
//  MouseRec
//
//  Created by Stanislas Peridy on 11/11/2025.
//

import SwiftUI
import AppKit
import Combine

class MenuBarManager: ObservableObject {
    private var statusItem: NSStatusItem?
    private var menu: NSMenu?
    
    @Published var isWindowVisible = true
    weak var mainWindow: NSWindow?
    
    weak var recorder: EventRecorder?
    var onToggleRecording: (() -> Void)?
    var onTogglePlayback: (() -> Void)?
    var onQuit: (() -> Void)?
    
    init() {
        setupMenuBar()
    }
    
    private func setupMenuBar() {
        // Create status item in menu bar
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.action = #selector(statusBarButtonClicked)
            button.target = self
            
            // Set initial emoji icon
            button.title = "🐭"
            print("✅ Menu bar icon created and set")
        }
        
        // Create menu
        menu = NSMenu()
        
        let recordItem = NSMenuItem(title: "Record (⌘⇧R)", action: #selector(toggleRecording), keyEquivalent: "")
        recordItem.target = self
        menu?.addItem(recordItem)
        
        let playItem = NSMenuItem(title: "Play (⌘⇧P)", action: #selector(togglePlayback), keyEquivalent: "")
        playItem.target = self
        menu?.addItem(playItem)
        
        menu?.addItem(NSMenuItem.separator())
        
        let showWindowItem = NSMenuItem(title: "Show Window", action: #selector(toggleWindow), keyEquivalent: "")
        showWindowItem.target = self
        menu?.addItem(showWindowItem)
        
        menu?.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu?.addItem(quitItem)
    }
    
    @objc private func statusBarButtonClicked() {
        guard let menu = menu else { return }
        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        statusItem?.menu = nil
    }
    
    @objc private func toggleRecording() {
        onToggleRecording?()
    }
    
    @objc private func togglePlayback() {
        onTogglePlayback?()
    }
    
    @objc private func toggleWindow() {
        print("🔄 Toggle window from menu bar, current state: \(isWindowVisible)")
        
        if isWindowVisible {
            // Window is currently visible, hide it
            if let window = mainWindow {
                window.orderOut(nil)
                // Remove from Dock
                NSApp.setActivationPolicy(.accessory)
                print("✅ Window hidden via menu and removed from Dock")
            }
        }
        
        // Toggle the state (showing will be handled by ContentView's onChange)
        DispatchQueue.main.async { [weak self] in
            self?.isWindowVisible.toggle()
            self?.updateMenuItems()
        }
    }
    
    @objc private func quitApp() {
        onQuit?()
    }
    
    func updateMenuItems() {
        // Update show/hide window menu item text based on current state
        let targetTitle = isWindowVisible ? "Hide Window" : "Show Window"
        for item in menu?.items ?? [] {
            if item.title.contains("Window") && item.action == #selector(toggleWindow) {
                item.title = targetTitle
                print("🔄 Menu item updated to: \(targetTitle)")
            }
        }
    }
    
    private func updateIcon(state: AppState) {
        guard let button = statusItem?.button else { 
            print("⚠️ No status item button available")
            return 
        }
        
        switch state {
        case .idle:
            // Use mouse emoji for idle
            button.image = nil
            button.title = "🐭"
            print("🎨 Icon updated to idle (🐭)")
            
        case .recording:
            // Red circle for recording
            button.title = ""
            button.image = createCircleImage(color: .systemRed)
            print("🎨 Icon updated to recording (🔴)")
            
        case .playing:
            // Green circle for playing
            button.title = ""
            button.image = createCircleImage(color: .systemGreen)
            print("🎨 Icon updated to playing (🟢)")
        }
    }
    
    private func createCircleImage(color: NSColor) -> NSImage {
        let size = NSSize(width: 16, height: 16)
        let image = NSImage(size: size)
        
        image.lockFocus()
        
        color.setFill()
        let circlePath = NSBezierPath(ovalIn: NSRect(x: 2, y: 2, width: 12, height: 12))
        circlePath.fill()
        
        image.unlockFocus()
        image.isTemplate = false
        
        return image
    }
    
    func updateMenu(isRecording: Bool, isPlaying: Bool, eventCount: Int) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let menu = self.menu else { return }
            
            // Update record menu item
            if let recordItem = menu.item(at: 0) {
                recordItem.title = isRecording ? "Stop Recording (⌘⇧R)" : "Start Recording (⌘⇧R)"
            }
            
            // Update play menu item
            if let playItem = menu.item(at: 1) {
                if isPlaying {
                    playItem.title = "Stop Playing (⌘⇧P)"
                    playItem.isEnabled = true
                } else {
                    playItem.title = "Play Recording (⌘⇧P)"
                    playItem.isEnabled = eventCount > 0
                }
            }
            
            // Disable recording while playing and vice versa
            if let recordItem = menu.item(at: 0) {
                recordItem.isEnabled = !isPlaying
            }
            
            // Update icon based on state
            let state: AppState = isRecording ? .recording : (isPlaying ? .playing : .idle)
            self.updateIcon(state: state)
        }
    }
    
    enum AppState {
        case idle
        case recording
        case playing
    }
}

