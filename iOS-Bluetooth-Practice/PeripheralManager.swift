//
//  PeripheralManager.swift
//  Iphone-Test
//
//  Created by Howard-Zjun on 2024/03/06.
//

import UIKit
import CoreBluetooth

let serviceUUID1: String = "FFE0"

let writeCharacteristicUUID: String = "FFF1"

let readBatteryCharacteristicUUID: String = "FFF2"

let readCharacteristicUUID: String = "FFF3"

let peripheralName: String = "Howard测试工程"

protocol PeripheralManagerDelegate: NSObjectProtocol {
    
    func readValue(peripheralManager: CBPeripheralManager, text: String)
}

class PeripheralManager: NSObject {
    
    var manager: CBPeripheralManager!
    
    weak var delegate: PeripheralManagerDelegate?
    
    var countCharacteristic: CBMutableCharacteristic?
    
    var shouldSendArray: [CBMutableCharacteristic] = []
    
    var timer: Timer?
    
    override init() {
        super.init()
        let queue = DispatchQueue(label: NSStringFromClass(PeripheralManager.self), qos: .background, attributes: .concurrent, autoreleaseFrequency: .inherit, target: nil)
        manager = CBPeripheralManager(delegate: self, queue: queue, options: nil)
    }
    
    func writeValue(count: Int) {
        if count <= 0 {
            return
        }
        let data = "\(count)".data(using: .utf8)!
        let result = manager.updateValue(data, for: countCharacteristic!, onSubscribedCentrals: nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.writeValue(count: count - 1)
        }
    }
}

extension PeripheralManager: CBPeripheralManagerDelegate {
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .poweredOn:
            let service1 = CBMutableService(type: .init(string: serviceUUID1), primary: true)
            let writeCharacteristic = CBMutableCharacteristic(type: .init(string: writeCharacteristicUUID), properties: .write, value: nil, permissions: .writeable)
            let readBatteryCharacteristic = CBMutableCharacteristic(type: .init(string: readBatteryCharacteristicUUID), properties: [.read, .notify], value: nil, permissions: .readable)
            let readCharacteristicUUID = CBMutableCharacteristic(type: .init(string: readCharacteristicUUID), properties: .read, value: nil, permissions: .readable)
            service1.characteristics = [writeCharacteristic, readBatteryCharacteristic, readCharacteristicUUID]
            manager.add(service1)
            self.countCharacteristic = readBatteryCharacteristic
            break
        default:
            break
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        if let error = error {
            print("[蓝牙外设] --- 添加服务错误: \(error.localizedDescription)")
            return
        }
        print("[蓝牙外设] --- 添加服务成功")
        manager.startAdvertising([CBAdvertisementDataLocalNameKey : peripheralName, CBAdvertisementDataServiceUUIDsKey : [CBUUID(string: serviceUUID1)]])
    }
    
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        if let error = error {
            print("[蓝牙外设] --- 发布外设错误: \(error.localizedDescription)")
            return
        }
        print("[蓝牙外设] --- 发布外设成功")
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        print("[蓝牙外设] --- 订阅")
        let data = "订阅成功".data(using: .utf8)!
        let mutableChara: CBMutableCharacteristic = .init(type: characteristic.uuid, properties: characteristic.properties, value: data, permissions: .readable)
        let result = peripheral.updateValue(data, for: mutableChara, onSubscribedCentrals: nil)
        if !result {
            shouldSendArray.append(mutableChara)
        }
        startLoop(characteristic: characteristic)
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        print("[蓝牙外设] --- 取消订阅")
        stopLoop()
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        print("[蓝牙外设] --- 接收到读请求")
        if (request.characteristic.properties.rawValue & CBCharacteristicProperties.read.rawValue) != 0 {
            if request.characteristic.uuid.uuidString == readBatteryCharacteristicUUID {
                let data = "\(UIDevice.current.batteryLevel)".data(using: .utf8)!
                request.value = data
                peripheral.respond(to: request, withResult: .success)
            } else if request.characteristic.uuid.uuidString == readCharacteristicUUID {
                let data = "\(UIDevice.current.batteryLevel)".data(using: .utf8)!
                request.value = data
                peripheral.respond(to: request, withResult: .success)
            } else {
                peripheral.respond(to: request, withResult: .requestNotSupported)
            }
        } else {
            peripheral.respond(to: request, withResult: .readNotPermitted)
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        print("[蓝牙外设] --- 接收到写请求")
        for request in requests {
            if (request.characteristic.properties.rawValue & CBCharacteristicProperties.write.rawValue) != 0 {
                if let data = request.value {
                    let text = String(data: data, encoding: .utf8) ?? "nil"
                    print("[蓝牙外设] --- 接收[\(text)]")
                    DispatchQueue.main.async {
                        self.delegate?.readValue(peripheralManager: self.manager, text: text)
                    }
                }
            } else {
                peripheral.respond(to: request, withResult: .writeNotPermitted)
                return
            }
        }
        // 如果所有请求都被完成，回传写入成功。随便取一个request
        if let first = requests.first {
            peripheral.respond(to: first, withResult: .success)
        }
    }
    
    func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        print("[蓝牙外设] --- 队列空闲")
        for temp in shouldSendArray {
            peripheral.updateValue(temp.value!, for: temp, onSubscribedCentrals: nil)
        }
        shouldSendArray.removeAll()
    }
    
    func startLoop(characteristic: CBCharacteristic) {
        DispatchQueue.main.async {
            let timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { timer in
                let date = Date()
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                let data = "\(formatter.string(from: date))：\(UIDevice.current.batteryLevel)".data(using: .utf8)!
                let mutableChara: CBMutableCharacteristic = .init(type: characteristic.uuid, properties: characteristic.properties, value: data, permissions: .readable)
                let result = self.manager.updateValue(data, for: mutableChara, onSubscribedCentrals: nil)
                if !result {
                    self.shouldSendArray.append(mutableChara)
                }
            }
        }
    }
    
    func stopLoop() {
        DispatchQueue.main.async {
            self.timer?.invalidate()
            self.timer = nil
        }
    }
}
