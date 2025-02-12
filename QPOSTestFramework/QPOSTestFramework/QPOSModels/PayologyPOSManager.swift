//
//  PayologyPOSManager.swift
//  PayologyCreditCard
//
//  Created by Filipe Rogério Canzi da Silva on 04/11/24.
//

import Foundation

public class PayologyPOSManager: NSObject, QPOSServiceListener {
    
    // MARK: - Stored Properties
    public let POSInstance = QPOSService.sharedInstance()
    public let bluetoothFinder = PayologyPOSBluetoothFinder()
    
    public private(set) var hasConnectedDevice: Bool = false {
        didSet {
            bluetoothFinder.didFoundDevice = hasConnectedDevice
        }
    }
    
    // MARK: - Observer Properties
    public var bluetoothStatus: BluetoothStatus = .awaitingConnection
    
    public var tradeStatus: TradeStatus = .awaitingTradeStart
    
    // MARK: - Initializer
    public override init() {
        super.init()
        bluetoothFinder.delegate = self
    }
}

// MARK: - Bluetooth Connection
extension PayologyPOSManager: PayologyPOSBluetoothFinderDelegate {

    public enum BluetoothStatus: Hashable, CaseIterable {
        case awaitingConnection
        
        case didStartScanning
        case scanDidFoundDevice
        case scanDidNotFoundDevice
        
        case connectingDevice
        case connectionDidSuccessfullyEnd
        case unableToConnectDevice
        
        case disconnectingDevice
        case disconnectionDidEnd
    }
    
    public func startScanning(scanningInterval: TimeInterval) {
        print(#line, #function)
        guard !hasConnectedDevice else { return }
        bluetoothFinder.startScan(scanningInterval: scanningInterval)
    }
    
    public func connectBluetoothDevice(deviceName: String) {
        print(#line, #function)
        POSInstance?.setDelegate(self)
        POSInstance?.setPosType(PosType.bluetooth_2mode)
        POSInstance?.setQueue(nil)
        
        POSInstance?.connectBT(deviceName)
        POSInstance?.setBTAutoDetecting(true)
        bluetoothStatus = .connectingDevice
    }
    
    public func disconnectBluetoothDevice() {
        print(#line, #function)
        POSInstance?.disconnectBT()
        bluetoothStatus = .disconnectingDevice
    }
    
    public func onRequestQposConnected() {
        print(#line, #function)
        hasConnectedDevice = true
        bluetoothStatus = .connectionDidSuccessfullyEnd
    }
    
    public func onRequestNoQposDetected() {
        print(#line, #function)
        bluetoothStatus = .unableToConnectDevice
    }
    
    public func onRequestQposDisconnected() {
        print(#line, #function)
        hasConnectedDevice = false
        bluetoothStatus = .disconnectionDidEnd
    }

    public func didStartScanning() {
        print(#line, #function)
        bluetoothStatus = .didStartScanning
    }
    
    public func didStopScanning(hasFoundDevice: Bool) {
        print(#line, #function)
        guard !hasConnectedDevice else { return }
        bluetoothStatus = hasFoundDevice ? .scanDidFoundDevice : .scanDidNotFoundDevice
    }
    
    public func didFindPOSDeviceName(deviceName: String) {
        print(#line, #function)
        connectBluetoothDevice(deviceName: deviceName)
    }
}

extension PayologyPOSManager {
    
    public enum TradeStatus: Hashable, CaseIterable {

        case awaitingTradeStart
        case awaitingUserCardAction
        
        case awaitingUserPIN
        case userDidEnterPIN
        case didCancelPINEntry
        case didBypassPINEntry
        
        case tradeDidTimeout
        case tradeDidFail
        case didCompleteTapTrade
        case didCompleteInsertTrade
    }
        
    public func startTrade(tradeData: POSTradeData) {
        print(#line, #function)
        let amountString = getAmountString(decimalValue: tradeData.paymentAmount)
                    
        POSInstance?.setAmount(
            amountString,
            aAmountDescribe: "",
            currency: tradeData.currencyCode,
            transactionType: tradeData.transactionType)
                
        POSInstance?.setCardTradeMode(tradeData.tradeMode)
        POSInstance?.doTrade()
    }
    
    public func stopTrade() {
        print(#line, #function)
        POSInstance?.cancelTrade(true)
    }
    
    private func getAmountString(decimalValue: Decimal) -> String {
        print(#line, #function)
        let doubleValue = NSDecimalNumber(decimal: decimalValue).doubleValue
        let amountString = String(format: "%.2f", doubleValue)
        
        /// This line takes out the decimal separator `.`.
        return amountString.components(separatedBy: CharacterSet.decimalDigits.inverted)
            .joined()
    }
    
    private func getTerminalTimeString() -> String {
        print(#line, #function)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMddHHmmss"
        return dateFormatter.string(from: Date())
    }
    
    public func onRequestTime() {
        print(#line, #function)
        let terminalTimeString = getTerminalTimeString()
        POSInstance?.sendTime(terminalTimeString)
    }
    
    public func onRequestWaitingUser() {
        print(#line, #function)
        tradeStatus = .awaitingUserCardAction
    }
    
    public func onDHError(_ errorState: DHError) {
        print(#line, #function)
        if errorState == .TIMEOUT || errorState == .CMD_TIMEOUT {
            tradeStatus = .tradeDidTimeout
        } else {
            tradeStatus = .tradeDidFail
        }
    }
    
    public func onRequestPinEntry() {
        print(#line, #function)
        tradeStatus = .awaitingUserPIN
        POSInstance?.bypassPinEntry()
        tradeStatus = .didBypassPINEntry
    }
    

    public func onDoTradeResult(_ result: DoTradeResult, decodeData: [AnyHashable : Any]!) {
        print(#line, #function)
        guard true else { fatalError() }
        print("ON DO TRADE RESULT")
        print("DECODED DATA")
        if let decodeData {
            print("[")
            for (key, value) in decodeData {
                print("KEY: \(key), VALUE: \(value)")
            }
            print("]")
        }
        print()

        if result == .ICC {
            tradeStatus = .didCompleteInsertTrade
            return
            
        } else if result == .NFC_ONLINE, let dictionary = decodeData as? [String : String] {
            tradeStatus = .didCompleteTapTrade
            return
        } else {
            tradeStatus = .tradeDidFail
            return
        }
    }
    
    public func onRequestOnlineProcess(_ tlv: String!) {
        
        /// THIS FUNCTION IS NOT GETTING THE TLV
        print(#line, #function)
        print("TLV", tlv)
        
        guard let tlv else {
            tradeStatus = .tradeDidFail
            return
        }
        
        tradeStatus = .didCompleteInsertTrade
    }
}



extension PayologyPOSManager {
    
    public enum ConfigurationStatus: Hashable, CaseIterable {
        case isUpdatingConfiguration
        case didUpdateConfiguration
    }
}

