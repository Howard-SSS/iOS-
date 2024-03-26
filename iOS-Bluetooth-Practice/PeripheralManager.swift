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

let readCharacteristicUUID: String = "FFF2"

let peripheralName: String = "Howard测试工程"

protocol PeripheralManagerDelegate: NSObjectProtocol {
    
    func readValue(peripheralManager: CBPeripheralManager, text: String)
}

class PeripheralManager: NSObject {
    
    var manager: CBPeripheralManager!
    
    weak var delegate: PeripheralManagerDelegate?
    
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
        // 若data太长，需要分包
        let mutable = CBMutableCharacteristic(type: .init(string: readCharacteristicUUID), properties: [.read, .notify], value: data, permissions: .readable)
        let result = manager.updateValue(data, for: mutable, onSubscribedCentrals: nil)
        if !result {
            objc_sync_enter(self)
            self.shouldSendArray.append(mutable)
            objc_sync_exit(self)
        }
        print("[蓝牙外设] --- 写\(count), result:\(result)")
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
            let readCharacteristicUUID = CBMutableCharacteristic(type: .init(string: readCharacteristicUUID), properties: [.read, .notify], value: nil, permissions: .readable)
            service1.characteristics = [writeCharacteristic, readCharacteristicUUID]
            manager.add(service1)
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
        let text = "订阅成功"
        let data = text.data(using: .utf8)!
        let mutableChara: CBMutableCharacteristic = .init(type: characteristic.uuid, properties: characteristic.properties, value: data, permissions: .readable)
        let result = peripheral.updateValue(data, for: mutableChara, onSubscribedCentrals: nil)
        print("[蓝牙外设] --- 接收到uuid:\(characteristic.uuid.uuidString)订阅, 订阅回传:\(text), result:\(result)")
        if !result {
            objc_sync_enter(self)
            shouldSendArray.append(mutableChara)
            objc_sync_exit(self)
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        print("[蓝牙外设] --- 取消订阅")
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        print("[蓝牙外设] --- 接收到读请求")
        // 匹配中央设备请求的特征对象
        if request.characteristic.uuid.uuidString != readCharacteristicUUID {
            return
        }
        // 匹配到特征对象后，开始判断请求的数据偏移量是否超出特征值的有效范围
//        guard let value = request.characteristic.value, request.offset <= value.count else {
//            peripheral.respond(to: request, withResult: .invalidOffset)
//            return
//        }
        // 校验权限
        if (request.characteristic.properties.rawValue & CBCharacteristicProperties.read.rawValue) == 0 {
            peripheral.respond(to: request, withResult: .readNotPermitted)
            return
        }
        if request.characteristic.uuid.uuidString == readCharacteristicUUID {
            let data = "\(UIDevice.current.batteryLevel)".data(using: .utf8)!
            request.value = data
            peripheral.respond(to: request, withResult: .success)
        } else {
            peripheral.respond(to: request, withResult: .requestNotSupported)
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
        objc_sync_enter(self)
        for temp in shouldSendArray {
            peripheral.updateValue(temp.value!, for: temp, onSubscribedCentrals: nil)
        }
        shouldSendArray.removeAll()
        objc_sync_exit(self)
    }
}
