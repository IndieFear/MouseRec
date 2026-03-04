//
//  ContentView.swift
//  MouseRec
//
//  Created by Stanislas Peridy on 11/11/2025.
//

import SwiftUI
import ApplicationServices

struct ContentView: View {
    @StateObject private var recorder = EventRecorder()
    @EnvironmentObject var menuBarManager: MenuBarManager
    @State private var playbackSpeed: Double = 1.0
    @State private var loopMode: LoopMode = .once
    @State private var repeatCount: Int = 1
    @State private var isHiding = false
    @State private var showPermissionAlert = false
    @State private var hasCheckedPermissions = false
    
    private let hotkeyManager = HotkeyManager.shared
    
    enum LoopMode: String, CaseIterable {
        case once = "Once"
        case loop = "Loop"
        case custom = "Custom"
    }
    
    // Convertit le LoopMode de la vue vers celui du recorder
    private var recorderLoopMode: EventRecorder.LoopMode {
        switch loopMode {
        case .once: return .once
        case .loop: return .loop
        case .custom: return .custom
        }
    }
    
    // Toggle enregistrement
    private func toggleRecording() {
        if recorder.isRecording {
            recorder.stopRecording()
        } else {
            // Check permissions before starting
            if !AXIsProcessTrusted() {
                print("⚠️ Recording blocked - Accessibility permissions required")
                
                // Try to post a dummy event to add app to list
                let currentMouseLocation = NSEvent.mouseLocation
                if let moveEvent = CGEvent(mouseEventSource: nil, 
                                          mouseType: .mouseMoved, 
                                          mouseCursorPosition: CGPoint(x: currentMouseLocation.x, y: currentMouseLocation.y), 
                                          mouseButton: .left) {
                    moveEvent.post(tap: .cghidEventTap)
                }
                
                // Show prompt
                let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
                _ = AXIsProcessTrustedWithOptions(options)
                
                showPermissionAlert = true
                return
            }
            recorder.startRecording()
        }
    }
    
    // Toggle lecture
    private func togglePlayback() {
        if recorder.isPlaying {
            recorder.stopPlaying()
        } else {
            // Check permissions before starting
            if !AXIsProcessTrusted() {
                print("⚠️ Playback blocked - Accessibility permissions required")
                
                // Try to post a dummy event to add app to list
                let currentMouseLocation = NSEvent.mouseLocation
                if let moveEvent = CGEvent(mouseEventSource: nil, 
                                          mouseType: .mouseMoved, 
                                          mouseCursorPosition: CGPoint(x: currentMouseLocation.x, y: currentMouseLocation.y), 
                                          mouseButton: .left) {
                    moveEvent.post(tap: .cghidEventTap)
                }
                
                // Show prompt
                let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
                _ = AXIsProcessTrustedWithOptions(options)
                
                showPermissionAlert = true
                return
            }
            recorder.playbackSpeed = playbackSpeed
            recorder.loopMode = recorderLoopMode
            recorder.repeatCount = repeatCount
            recorder.playRecording()
        }
    }
    
    // Update menu bar
    private func updateMenuBar() {
        menuBarManager.updateMenu(
            isRecording: recorder.isRecording,
            isPlaying: recorder.isPlaying,
            eventCount: recorder.eventCount()
        )
    }
    
    // Check accessibility permissions at launch (silent check, no custom alert)
    private func checkAccessibilityPermissions() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // First check if we already have permissions
            if AXIsProcessTrusted() {
                print("✅ Accessibility permissions already granted")
                return
            }
            
            print("⚠️ No accessibility permissions - attempting to add app to list")
            
            // Try to create a dummy CGEvent to force the system to add the app to the list
            // This won't actually move the mouse if we don't have permissions
            let currentMouseLocation = NSEvent.mouseLocation
            let moveEvent = CGEvent(mouseEventSource: nil, 
                                   mouseType: .mouseMoved, 
                                   mouseCursorPosition: CGPoint(x: currentMouseLocation.x, y: currentMouseLocation.y), 
                                   mouseButton: .left)
            
            if let event = moveEvent {
                // Try to post the event - this will fail without permissions but will add the app to the list
                event.post(tap: .cghidEventTap)
                print("📝 Attempted to post CGEvent to register app in Accessibility list")
            }
            
            // Small delay to let the system process the event attempt
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                // Now use the option that triggers the system prompt (native popup only)
                let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
                let trusted = AXIsProcessTrustedWithOptions(options)
                
                if !trusted {
                    print("⚠️ Accessibility permissions not granted - Native system prompt shown")
                    // Don't show custom alert at launch, only when user tries to record/play
                } else {
                    print("✅ Accessibility permissions granted")
                }
            }
        }
    }
    
    // Open accessibility settings
    private func openAccessibilitySettings() {
        let prefpaneUrl = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(prefpaneUrl)
        print("🔓 Opening Accessibility settings")
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 4) {
                HStack {
                    Image(systemName: "computermouse.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.blue)
                    Text("MouseRec")
                        .font(.system(size: 20, weight: .bold))
                    
                    Spacer()
                    
                    // Hide window button
                    Button(action: {
                        guard !isHiding, let window = menuBarManager.mainWindow else { 
                            print("⏳ Cannot hide: isHiding=\(isHiding), window=\(menuBarManager.mainWindow != nil)")
                            return 
                        }
                        
                        isHiding = true
                        print("🔽 Hide button clicked")
                        
                        // Hide window and update state
                        window.orderOut(nil)
                        
                        // Remove app from Dock
                        NSApp.setActivationPolicy(.accessory)
                        
                        // Update state and menu
                        menuBarManager.isWindowVisible = false
                        menuBarManager.updateMenuItems()
                        
                        print("✅ Window hidden and app removed from Dock")
                        
                        // Reset hiding flag after delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self.isHiding = false
                            print("🔓 Hide button unlocked")
                        }
                    }) {
                        Image(systemName: "arrow.down.right.and.arrow.up.left")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                            .padding(4)
                    }
                    .buttonStyle(.borderless)
                    .help("Hide to Menu Bar")
                    .disabled(isHiding)
                }
                .padding(.horizontal, 16)
                .padding(.top, 6)
                .padding(.bottom, 4)
            }
            
            Divider()
            
            // Main Controls
            VStack(spacing: 0) {
                // Recording Button
                VStack(spacing: 6) {
                    Button(action: toggleRecording) {
                        VStack(spacing: 4) {
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(recorder.isRecording ? Color.red : Color.gray.opacity(0.3))
                                    .frame(width: 12, height: 12)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: 1.5)
                                    )
                                
                                Text(recorder.isRecording ? "Stop" : "Record")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.primary)
                            }
                            
                            Text("⌘⇧R")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(recorder.isRecording ? Color.red.opacity(0.1) : Color.gray.opacity(0.05))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(recorder.isRecording ? Color.red : Color.gray.opacity(0.2), lineWidth: 1.5)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(recorder.isPlaying)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 10)
                
                // Play/Stop Button
                Button(action: togglePlayback) {
                    VStack(spacing: 4) {
                        HStack(spacing: 8) {
                            Image(systemName: recorder.isPlaying ? "stop.fill" : "play.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.white)
                            
                            Text(recorder.isPlaying ? "Stop" : "Play")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        
                        Text("⌘⇧P")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: recorder.isPlaying ? [Color.orange, Color.red] : [Color.blue, Color.purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                    .shadow(color: (recorder.isPlaying ? Color.orange : Color.blue).opacity(0.3), radius: 4, x: 0, y: 2)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                .disabled(recorder.isRecording || recorder.eventCount() == 0)
                .opacity((recorder.isRecording || recorder.eventCount() == 0) ? 0.5 : 1.0)
            
                
                // Settings Section
                VStack(alignment: .leading, spacing: 14) {
                    // Playback Speed
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "speedometer")
                                .font(.system(size: 11))
                                .foregroundStyle(.blue)
                            Text("Speed")
                                .font(.system(size: 11, weight: .medium))
                        }
                        
                        HStack(spacing: 6) {
                            ForEach([1.0, 2.0, 3.0, 5.0], id: \.self) { speed in
                                Button(action: {
                                    playbackSpeed = speed
                                }) {
                                    Text("x\(Int(speed))")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(playbackSpeed == speed ? .white : .primary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 6)
                                        .background(
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(playbackSpeed == speed ? Color.blue : Color.gray.opacity(0.1))
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    // Loop Mode
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "repeat")
                                .font(.system(size: 11))
                                .foregroundStyle(.purple)
                            Text("Repeat")
                                .font(.system(size: 11, weight: .medium))
                        }
                        
                        HStack(spacing: 6) {
                            ForEach(LoopMode.allCases, id: \.self) { mode in
                                Button(action: {
                                    loopMode = mode
                                }) {
                                    Text(mode.rawValue)
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(loopMode == mode ? .white : .primary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 6)
                                        .background(
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(loopMode == mode ? Color.purple : Color.gray.opacity(0.1))
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        
                        // Custom repeat count
                        if loopMode == .custom {
                            HStack {
                                Text("Count:")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                
                                Spacer()
                                
                                HStack(spacing: 6) {
                                    Button(action: {
                                        if repeatCount > 1 {
                                            repeatCount -= 1
                                        }
                                    }) {
                                        Image(systemName: "minus.circle.fill")
                                            .font(.system(size: 14))
                                            .foregroundStyle(.purple)
                                    }
                                    .buttonStyle(.plain)
                                    
                                    Text("\(repeatCount)")
                                        .font(.system(size: 13, weight: .semibold))
                                        .frame(minWidth: 24)
                                    
                                    Button(action: {
                                        if repeatCount < 99 {
                                            repeatCount += 1
                                        }
                                    }) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 14))
                                            .foregroundStyle(.purple)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.purple.opacity(0.05))
                            )
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                
                Divider()
                    .padding(.horizontal, 16)
            }
        }
        .frame(width: 280)
        .background(Color(nsColor: .windowBackgroundColor))
        .alert("Accessibility Permissions Required", isPresented: $showPermissionAlert) {
            Button("Open Settings") {
                openAccessibilitySettings()
            }
            Button("Later", role: .cancel) { }
        } message: {
            Text("MouseRec needs Accessibility permissions to record and replay mouse and keyboard events.\n\nMouseRec has been added to the list. Please:\n1. Click 'Open Settings' below\n2. Find MouseRec in the list\n3. Enable the checkbox next to MouseRec\n4. Close Settings and try again")
        }
        .onAppear {
            // Check permissions on first launch
            if !hasCheckedPermissions {
                hasCheckedPermissions = true
                checkAccessibilityPermissions()
            }
            // Configure hotkeys
            hotkeyManager.onRecordHotkey = { [self] in
                DispatchQueue.main.async {
                    self.toggleRecording()
                }
            }
            
            hotkeyManager.onPlayHotkey = { [self] in
                DispatchQueue.main.async {
                    self.togglePlayback()
                }
            }
            
            hotkeyManager.registerHotkeys()
            
            // Configure menu bar manager
            menuBarManager.recorder = recorder
            
            // Store window reference - find the main app window (not status bar window)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak menuBarManager] in
                let appWindows = NSApplication.shared.windows.filter { window in
                    // Exclude status bar windows and other system windows
                    let className = String(describing: type(of: window))
                    return !className.contains("StatusBar") && 
                           !className.contains("Panel") &&
                           window.contentView != nil
                }
                
                if let window = appWindows.first {
                    menuBarManager?.mainWindow = window
                    print("✅ Main window found and stored: \(window)")
                    print("   Window class: \(String(describing: type(of: window)))")
                } else {
                    print("❌ No suitable window found. Available windows:")
                    for window in NSApplication.shared.windows {
                        print("   - \(String(describing: type(of: window)))")
                    }
                }
            }
            
            menuBarManager.onToggleRecording = { [self] in
                DispatchQueue.main.async {
                    self.toggleRecording()
                }
            }
            menuBarManager.onTogglePlayback = { [self] in
                DispatchQueue.main.async {
                    self.togglePlayback()
                }
            }
            
            // Initial menu bar update
            DispatchQueue.main.async {
                self.updateMenuBar()
            }
        }
        .onDisappear {
            hotkeyManager.unregisterHotkeys()
        }
        .onChange(of: recorder.isRecording) { _, _ in
            DispatchQueue.main.async {
                updateMenuBar()
            }
        }
        .onChange(of: recorder.isPlaying) { _, _ in
            DispatchQueue.main.async {
                updateMenuBar()
            }
        }
        .onChange(of: menuBarManager.isWindowVisible) { oldValue, newValue in
            // Only act if the value actually changed and we're showing (not hiding)
            guard oldValue != newValue, newValue == true else { return }
            
            guard let window = menuBarManager.mainWindow else {
                print("⚠️ No window reference available")
                return
            }
            
            print("🔼 Showing window from menu bar")
            DispatchQueue.main.async {
                // Restore app to Dock first
                NSApp.setActivationPolicy(.regular)
                
                // Force the app to the front
                NSApp.activate(ignoringOtherApps: true)
                
                // Make window key and bring to front
                window.makeKeyAndOrderFront(nil)
                window.orderFrontRegardless()
                
                // Set window level to ensure it's visible
                window.level = .floating
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    window.level = .normal
                }
                
                // Update menu items to reflect window is now visible
                menuBarManager.updateMenuItems()
                
                isHiding = false // Reset the hiding flag when showing
                
                print("✅ Window shown at front and app restored to Dock")
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(MenuBarManager())
}
