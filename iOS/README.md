# AudioMoth Configuration — iOS App

iOS 18.1 port of the [AudioMoth Configuration App](https://github.com/OpenAcousticDevices/AudioMoth-Configuration-App).

## Requirements

- Xcode 16+
- iOS 18.1 deployment target
- iPhone (all features) or iPad

## Setup in Xcode

1. **Create a new Xcode project**
   - Template: iOS → App
   - Interface: SwiftUI
   - Language: Swift
   - Deployment target: iOS 18.1

2. **Add source files**  
   Add every `.swift` file from `AudioMothConfig/` into the project, preserving group structure (App, Models, Constants, Services, ViewModels, Views, Views/Components).

3. **Replace Info.plist**  
   Replace the generated `Info.plist` with `AudioMothConfig/Resources/Info.plist`, or merge the keys manually.

4. **Add frameworks**  
   In *Target → General → Frameworks, Libraries, and Embedded Content*, add:
   - `MapKit.framework`
   - `ExternalAccessory.framework` (for future USB support)
   - `CoreLocation.framework`

5. **Build and run**  
   The app runs in **demo mode** by default (a mock AudioMoth device appears after 1 second). All configuration screens are fully functional.

## Features

| Tab | Functionality |
|-----|---------------|
| Recording | Sample rate (8–384 kHz), gain, record/sleep duration, LED, battery check |
| Schedule | Up to 4 time periods, sun schedule (sunrise/sunset/civil/nautical/astronomical), date range |
| Filtering | Low/high/band-pass, amplitude threshold (%, 16-bit, dB), Goertzel frequency trigger |
| Advanced | Duty cycle, daily folders, energy saver, 48 Hz DC filter, magnetic switch, timezone |
| Add-ons | GPS time setting, acoustic configuration chime, pre-recording preparation time |

- Export/import JSON configuration files (Files app, AirDrop, etc.)
- Battery life estimator
- Real-time schedule bar visualisation
- Location picker with MapKit for sun schedule
- Dark mode support

## Hardware connection

### Current: Demo mode
The app ships with `MockDeviceService` which simulates a connected AudioMoth.

### Production: USB HID via iPhone 15+ (USB-C)

AudioMoth communicates over USB HID. To enable direct connection:

1. Request the **`com.apple.developer.hid.management`** entitlement from Apple (required for iOS 18 HID device access on USB-C iPhones).
2. Implement `HIDDeviceService` in `Services/DeviceService.swift` using `CoreHID` / `IOHIDManager` APIs with the entitlement.
3. AudioMoth USB descriptors (verify with `system_profiler SPUSBDataType` on Mac):
   - Vendor ID: `0x10C4` (Silicon Labs CP2102)
   - Usage Page: `0xFF00` (vendor-defined)

### Alternative: File export workflow
1. Configure settings in the app.
2. Tap the share icon → export JSON config.
3. Transfer file to a computer and use the desktop app's *Open* to load it, then configure the device via USB.

## Packet format

`Services/PacketBuilder.swift` produces an exact binary packet matching firmware 1.0.0–1.12.0. The 62-byte packet is byte-compatible with the desktop app — a packet written here, when sent via USB HID, will configure the device identically.

## Project structure

```
iOS/AudioMothConfig/
├── App/AudioMothConfigApp.swift          Entry point (@main)
├── Models/AudioMothConfiguration.swift   Complete config model (Codable)
├── Constants/AudioMothConstants.swift    Sample rates, packet lengths, limits
├── Services/
│   ├── PacketBuilder.swift               Binary packet construction (exact port)
│   ├── ConfigFileService.swift           JSON save/load
│   ├── DeviceService.swift               Device protocol + MockDeviceService
│   └── SunCalculator.swift               NOAA sunrise/sunset algorithm
├── ViewModels/AppViewModel.swift         @Observable state manager
└── Views/
    ├── ContentView.swift                 Navigation + toolbar
    ├── DeviceInfoView.swift              Connection status bar
    ├── RecordingSettingsView.swift       Tab 1
    ├── ScheduleView.swift                Tab 2
    ├── FilteringView.swift               Tab 3
    ├── AdvancedView.swift                Tab 4
    ├── AddOnsView.swift                  Tab 5
    └── Components/
        ├── ScheduleBarView.swift         Visual 24-hour schedule bar
        ├── TimePeriodEditor.swift        Time period row + time picker sheet
        └── LocationPickerView.swift      MapKit location picker
```
