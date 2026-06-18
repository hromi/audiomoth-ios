import Foundation
import Combine

struct DeviceInfo {
    var deviceID: String
    var firmwareVersion: (Int, Int, Int)
    var firmwareDescription: String
    var batteryVoltage: Double       // volts
    var deviceTime: Date?
}

enum DeviceState {
    case disconnected
    case connecting
    case connected(DeviceInfo)
    case error(String)
}

enum DeviceError: Error, LocalizedError {
    case notConnected
    case packetMismatch
    case timeout
    case unsupportedFirmware(String)
    case communicationError(String)

    var errorDescription: String? {
        switch self {
        case .notConnected:               return "No AudioMoth connected"
        case .packetMismatch:             return "Device did not accept configuration — please try again"
        case .timeout:                    return "Device did not respond in time"
        case .unsupportedFirmware(let d): return "Unsupported firmware: \(d)"
        case .communicationError(let m):  return m
        }
    }
}

// MARK: - Protocol

protocol DeviceServiceProtocol: AnyObject {
    var statePublisher: AnyPublisher<DeviceState, Never> { get }
    func startMonitoring()
    func stopMonitoring()
    func sendConfiguration(_ config: AudioMothConfiguration) async throws
    func copyDeviceID() -> String?
}

// MARK: - Mock service (demo / simulator)

@Observable
final class MockDeviceService: DeviceServiceProtocol {

    private let subject = CurrentValueSubject<DeviceState, Never>(.disconnected)
    var statePublisher: AnyPublisher<DeviceState, Never> { subject.eraseToAnyPublisher() }

    private var pollingTask: Task<Void, Never>?
    private var connected = false

    func startMonitoring() {
        pollingTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(1))
            subject.send(.connected(DeviceInfo(
                deviceID: "247AA40C3F70CB2A",
                firmwareVersion: (1, 12, 0),
                firmwareDescription: "AudioMoth-Firmware-Basic",
                batteryVoltage: 4.15,
                deviceTime: Date()
            )))
            connected = true
            // Tick time
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                if case .connected(var info) = subject.value {
                    info.deviceTime = Date()
                    subject.send(.connected(info))
                }
            }
        }
    }

    func stopMonitoring() {
        pollingTask?.cancel()
        pollingTask = nil
        subject.send(.disconnected)
        connected = false
    }

    func sendConfiguration(_ config: AudioMothConfiguration) async throws {
        guard connected else { throw DeviceError.notConnected }
        let (_, sendAt) = PacketBuilder.build(config: config)
        let delay = sendAt.timeIntervalSinceNow
        if delay > 0 { try await Task.sleep(for: .seconds(delay)) }
        // Simulate success
        try await Task.sleep(for: .milliseconds(200))
    }

    func copyDeviceID() -> String? {
        if case .connected(let info) = subject.value { return info.deviceID }
        return nil
    }
}

// MARK: - USB / HID service stub
// Requires CoreUSB entitlement (com.apple.developer.hid.management) on iPhone 15+ running iOS 18+
// Enable this service and add the entitlement to Info.plist / Entitlements file for production.

/*
 To activate USB HID communication:
 1. Add entitlement `com.apple.developer.hid.management` to your entitlements file.
 2. Uncomment and implement HIDDeviceService below using IOHIDManager / CoreHID APIs.
 3. In AudioMothConfigApp.swift, replace MockDeviceService with HIDDeviceService.

 USB descriptor expected on device:
   Vendor  ID : 0x10C4  (Silicon Labs)
   Product ID : 0x0002  (or device-specific — verify with `system_profiler SPUSBDataType` on Mac)
   Usage Page : 0xFF00  (Vendor-defined)
   Usage      : 0x0001
 */
