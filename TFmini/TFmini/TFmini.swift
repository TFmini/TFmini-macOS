//
//  TFmini.swift
//  TFmini
//
//  Created by karoto on 2018/2/12.
//  Copyright © 2018年 karoto. All rights reserved.
//

import Cocoa

extension Data {
    struct HexEncodingOptions: OptionSet {
        let rawValue: Int
        static let upperCase = HexEncodingOptions(rawValue: 1 << 0)
    }
    
    func hexEncodedString(options: HexEncodingOptions = []) -> String {
        let hexDigits = Array((options.contains(.upperCase) ? "0123456789ABCDEF" : "0123456789abcdef").utf16)
        var chars: [unichar] = []
        chars.reserveCapacity(2 * count)
        for byte in self {
            chars.append(hexDigits[Int(byte / 16)])
            chars.append(hexDigits[Int(byte % 16)])
        }
        return String(utf16CodeUnits: chars, count: chars.count)
    }
}

extension Data {
    
    init<T>(fromArray values: [T]) {
        var values = values
        self.init(buffer: UnsafeBufferPointer(start: &values, count: values.count))
    }
    
    func toArray<T>(type: T.Type) -> [T] {
        return self.withUnsafeBytes {
            [T](UnsafeBufferPointer(start: $0, count: self.count/MemoryLayout<T>.stride))
        }
    }
}

class TFmini: NSObject, ORSSerialPortDelegate, NSUserNotificationCenterDelegate {
    
    @IBOutlet weak var openCloseButton: NSButton!
    @IBOutlet var receivedDataTextView: NSTextView!
    
    @objc dynamic let serialPortManager = ORSSerialPortManager.shared()
    @objc dynamic let availableBaudRates = [300, 1200, 2400, 4800, 9600, 14400, 19200, 28800, 38400, 57600, 115200, 230400]
    
    @objc dynamic var serialPort: ORSSerialPort? {
        didSet {
            oldValue?.close()
            oldValue?.delegate = nil
            serialPort?.delegate = self
        }
    }
    
    override init() {
        super.init()
        
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(serialPortsWereConnected(_:)), name: NSNotification.Name.ORSSerialPortsWereConnected, object: nil)
        nc.addObserver(self, selector: #selector(serialPortsWereDisconnected(_:)), name: NSNotification.Name.ORSSerialPortsWereDisconnected, object: nil)
        
        NSUserNotificationCenter.default.delegate = self
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Actions
    
    @IBAction func openOrClosePort(_ sender: Any) {
        if let port = self.serialPort {
            if (port.isOpen) {
                port.close()
            } else {
                port.open()
            }
        }
    }
    
    // MARK: - ORSSerialPortDelegate
    
    func serialPortWasOpened(_ serialPort: ORSSerialPort) {
        self.openCloseButton.title = "Close"
    }
    
    func serialPortWasClosed(_ serialPort: ORSSerialPort) {
        self.openCloseButton.title = "Open"
    }
    
    var receiveCount = 0
    
    func serialPort(_ serialPort: ORSSerialPort, didReceive data: Data) {
        
        let dataArray = data.toArray(type: UInt8.self)
        
        if dataArray.count == 9 {
            var check: UInt16 = 0
            for (index, number) in dataArray.enumerated() {
                if index < (dataArray.endIndex - 1) {
                    check += UInt16(number)
                }
            }
            
            var distance: UInt16 = 0
            if dataArray[0] == 89 && dataArray[1] == 89 && dataArray[8] == check % 256 {
                distance = UInt16(dataArray[2]) + UInt16(dataArray[3])*256
                
                var appendString = ""
                var count = 0
                for index in data.hexEncodedString(options: .upperCase).indices {
                    count += 1;
                    appendString.append(data.hexEncodedString(options: .upperCase)[index])
                    if count == 18 {
                        appendString += "\t \t \(distance) \r\n"
                    } else if count % 2 == 0 {
                        appendString.append(" ")
                    }
                }
                
                self.receivedDataTextView.textStorage?.mutableString.append(appendString)
                self.receivedDataTextView.scrollToEndOfDocument(1)
                self.receivedDataTextView.needsDisplay = true
                
                receiveCount += 1
                if receiveCount > 10000 {
                    receiveCount = 0
                    self.receivedDataTextView.textStorage?.mutableString.setString("");
                }
            }
        }
        
    }
    
    func serialPortWasRemoved(fromSystem serialPort: ORSSerialPort) {
        self.serialPort = nil
        self.openCloseButton.title = "Open"
    }
    
    func serialPort(_ serialPort: ORSSerialPort, didEncounterError error: Error) {
        print("SerialPort \(serialPort) encountered an error: \(error)")
    }
    
    // MARK: - NSUserNotifcationCenterDelegate
    
    func userNotificationCenter(_ center: NSUserNotificationCenter, didDeliver notification: NSUserNotification) {
        let popTime = DispatchTime.now() + Double(Int64(3.0 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: popTime) { () -> Void in
            center.removeDeliveredNotification(notification)
        }
    }
    
    func userNotificationCenter(_ center: NSUserNotificationCenter, shouldPresent notification: NSUserNotification) -> Bool {
        return true
    }
    
    // MARK: - Notifications
    
    @objc func serialPortsWereConnected(_ notification: Notification) {
        if let userInfo = notification.userInfo {
            let connectedPorts = userInfo[ORSConnectedSerialPortsKey] as! [ORSSerialPort]
            print("Ports were connected: \(connectedPorts)")
            self.postUserNotificationForConnectedPorts(connectedPorts)
        }
    }
    
    @objc func serialPortsWereDisconnected(_ notification: Notification) {
        if let userInfo = notification.userInfo {
            let disconnectedPorts: [ORSSerialPort] = userInfo[ORSDisconnectedSerialPortsKey] as! [ORSSerialPort]
            print("Ports were disconnected: \(disconnectedPorts)")
            self.postUserNotificationForDisconnectedPorts(disconnectedPorts)
        }
    }
    
    func postUserNotificationForConnectedPorts(_ connectedPorts: [ORSSerialPort]) {
        let unc = NSUserNotificationCenter.default
        for port in connectedPorts {
            let userNote = NSUserNotification()
            userNote.title = NSLocalizedString("Serial Port Connected", comment: "Serial Port Connected")
            userNote.informativeText = "Serial Port \(port.name) was connected to your Mac."
            userNote.soundName = nil;
            unc.deliver(userNote)
        }
    }
    
    func postUserNotificationForDisconnectedPorts(_ disconnectedPorts: [ORSSerialPort]) {
        let unc = NSUserNotificationCenter.default
        for port in disconnectedPorts {
            let userNote = NSUserNotification()
            userNote.title = NSLocalizedString("Serial Port Disconnected", comment: "Serial Port Disconnected")
            userNote.informativeText = "Serial Port \(port.name) was disconnected from your Mac."
            userNote.soundName = nil;
            unc.deliver(userNote)
        }
    }
    
}


























