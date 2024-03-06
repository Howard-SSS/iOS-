import UIKit
import CoreBluetooth

protocol CentralManagerDelegate: NSObjectProtocol {
    
    func discover(peripheralObject: PeripheralObject)
}

class PeripheralObject: NSObject {
    
    let peripheral: CBPeripheral
    
    let advertisementData: [String : Any]
    
    let RSSI: NSNumber
    
    init(peripheral: CBPeripheral, advertisementData: [String : Any], RSSI: NSNumber) {
        self.peripheral = peripheral
        self.advertisementData = advertisementData
        self.RSSI = RSSI
    }
}

class CentralManager: NSObject {

    var certralManager: CBCentralManager!
    
    var connectPeripheral: CBPeripheral?
        
    var readCharacteristic: CBCharacteristic?
    
    var writeCharacteristic: CBCharacteristic?
    
    var readRemainCharacteristic: CBCharacteristic?
    
    var delegate: CentralManagerDelegate?
    
//    private static var instance: CentralManager = .init()
//    
//    static var `default` = instance
    
    override init() {
        super.init()
        let queue: DispatchQueue = .init(label: NSStringFromClass(CentralManager.self), qos: .background, attributes: .concurrent, autoreleaseFrequency: .inherit, target: nil)
        let options: [String : Any] = [CBCentralManagerOptionShowPowerAlertKey : NSNumber(booleanLiteral: true), CBCentralManagerOptionRestoreIdentifierKey : "unique identifer"]
        certralManager = .init(delegate: self, queue: queue, options: options)
    }
    
    func connect(peripheral: CBPeripheral) {
        certralManager.stopScan()
        certralManager.connect(peripheral, options: nil)
    }
    
    func writeValue() {
        if let writeCharacteristic = writeCharacteristic {
            let date = Date()
            let fomatter = DateFormatter()
            fomatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let data = "来自管理中心：\(fomatter.string(from: date))通信一次".data(using: .utf8)!
            connectPeripheral?.writeValue(data, for: writeCharacteristic, type: .withResponse)
        }
    }
    
    func readValue() {
        if let readCharacteristic = readCharacteristic {
            connectPeripheral?.readValue(for: readCharacteristic)
        }
    }
    
    func readRemainValue() {
        if let readRemainCharacteristic = readRemainCharacteristic {
            connectPeripheral?.setNotifyValue(true, for: readRemainCharacteristic)
        }
    }
}

extension CentralManager: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOff { // 关闭
            
        } else if central.state == .poweredOn { // 开启
//            let uuid = CBUUID(string: serviceUUID1)
            central.scanForPeripherals(withServices: nil, options: [
                CBCentralManagerScanOptionAllowDuplicatesKey : NSNumber(booleanLiteral: false)
            ])
        } else if central.state == .resetting { //
            
        } else if central.state == .unauthorized { // 未授权
            
        } else if central.state == .unsupported { // 不支持
             
        } else if central.state == .resetting { // 重置
            
        } else if central.state == .unknown { // 未知
            
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if let name = advertisementData[CBAdvertisementDataLocalNameKey] as? String, let uuidArrat = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] {
            print("[管理中心] --- 发现外设，name：\(name)，\(uuidArrat)")
            DispatchQueue.main.async {
                self.delegate?.discover(peripheralObject: .init(peripheral: peripheral, advertisementData: advertisementData, RSSI: RSSI))
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        connectPeripheral = peripheral
        let uuid1 = CBUUID(string: serviceUUID1)
        peripheral.discoverServices([uuid1])
        print("[管理中心] --- 连接成功")
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        if let error = error {
            print("[管理中心] --- 连接失败：\(error.localizedDescription)")
            return
        }
        print("[管理中心] --- 连接失败：nil")
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if let error = error {
            print("[管理中心] --- 断连：\(error.localizedDescription)")
            return
        }
        print("[管理中心] --- 断连：nil")
    }
    
    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
        
    }
}

extension CentralManager: CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("[管理中心] --- 发现服务，失败：\(error.localizedDescription)")
            return
        }
        for service in peripheral.services ?? [] {
            print("[管理中心] --- 发现服务，uuid：\(service.uuid)")
            if service.uuid.uuidString == serviceUUID1 {
                let readUUID = CBUUID(string: readBatteryCharacteristicUUID)
                let writeUUID = CBUUID(string: writeCharacteristicUUID)
                let readRemainUUID = CBUUID(string: readBatteryRemainCharacteristicUUID)
                peripheral.discoverCharacteristics([readUUID, writeUUID, readRemainUUID], for: service)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            print("[管理中心] --- 发现特征，失败：\(error.localizedDescription)")
            return
        }
        if service.uuid.uuidString == serviceUUID1 {
            for characteristic in service.characteristics ?? [] {
                if characteristic.uuid.uuidString == readBatteryCharacteristicUUID {
                    readCharacteristic = characteristic
                    print("[管理中心] --- 发现特征，uuid：\(readBatteryCharacteristicUUID)")
                    peripheral.readValue(for: characteristic)
                } else if characteristic.uuid.uuidString == writeCharacteristicUUID {
                    writeCharacteristic = characteristic
                    print("[管理中心] --- 发现特征，uuid：\(writeCharacteristicUUID)")
                } else if characteristic.uuid.uuidString == readBatteryRemainCharacteristicUUID {
                    readRemainCharacteristic = characteristic
                    print("[管理中心] --- 发现特征，uuid：\(readBatteryRemainCharacteristicUUID)")
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("[管理中心] --- 收到消息，失败：\(error.localizedDescription)")
        } else {
            if let data = characteristic.value {
                let text = String(data: data, encoding: .utf8)
                print("[管理中心] --- 收到消息：\(text ?? "nil")")
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("[管理中心] --- 写数据，失败：\(error.localizedDescription)")
        } else {
            print("[管理中心] --- 写数据成功")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("[管理中心] --- 通知状态更新，失败：\(error.localizedDescription)")
        } else {
            print("[管理中心] --- 通知状态更新：\(characteristic.isNotifying)")
        }
    }
}

