//
//  ViewController.swift
//  iOS-Bluetooth-Practice
//
//  Created by Howard-Zjun on 2023/09/27.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController {
    
    var centralManager: CentralManager?
    
    var peripheralManager: PeripheralManager?
    
    var peripheralArray: [PeripheralObject] = []
    
    lazy var lab: UILabel = {
        let lab = UILabel(frame: .init(x: 0, y: 50, width: view.width, height: 45))
        lab.textColor = .black
        lab.textAlignment = .center
        return lab
    }()
    
    lazy var centralWriteBtns: [UIButton] = {
        var centralWriteBtns: [UIButton] = []
        let count = 3
        var minX: CGFloat = (view.width - 100 * CGFloat(count) - 10 * (CGFloat(count) - 1)) * 0.5
        for index in 0..<count {
            let btn = UIButton(frame: .init(x: minX, y: lab.maxY + 20, width: 100, height: 45))
            btn.setTitle("发送\(index)", for: .normal)
            btn.setTitleColor(.black, for: .normal)
            btn.tag = index
            btn.addTarget(self, action: #selector(touchCentralWriteBtn(_:)), for: .touchUpInside)
            centralWriteBtns.append(btn)
            minX = btn.maxX + 10
        }
        return centralWriteBtns
    }()
    
    lazy var centralReadBtn: UIButton = {
        let centralReadBtn = UIButton(frame: .init(x: (view.width - 100) * 0.5, y: centralWriteBtns[0].maxY + 20, width: 100, height: 45))
        centralReadBtn.setTitle("读电量", for: .normal)
        centralReadBtn.setTitleColor(.black, for: .normal)
        centralReadBtn.addTarget(self, action: #selector(touchCentralReadBtn(_:)), for: .touchUpInside)
        return centralReadBtn
    }()
    
    lazy var lineView: UIView = {
        let lineView = UIView(frame: .init(x: (view.width - 2) * 0.5, y: 0, width: 2, height: view.height))
        lineView.backgroundColor = .black
        return lineView
    }()
    
    lazy var peripheralWriteOnceBtn: UIButton = {
        let peripheralWriteBtn = UIButton(frame: .init(x: (view.width - 100) * 0.5, y: lab.maxY + 20, width: 100, height: 45))
        peripheralWriteBtn.setTitle("写一次", for: .normal)
        peripheralWriteBtn.setTitleColor(.black, for: .normal)
        peripheralWriteBtn.addTarget(self, action: #selector(touchPeripheralWriteOnceBtn(_:)), for: .touchUpInside)
        return peripheralWriteBtn
    }()
    
    lazy var peripheralWriteThreeBtn: UIButton = {
        let peripheralWriteThreeBtn = UIButton(frame: .init(x: (view.width - 100) * 0.5, y: peripheralWriteOnceBtn.maxY + 20, width: 100, height: 45))
        peripheralWriteThreeBtn.setTitle("写3次", for: .normal)
        peripheralWriteThreeBtn.setTitleColor(.black, for: .normal)
        peripheralWriteThreeBtn.addTarget(self, action: #selector(touchPeripheralWriteThreeBtn(_:)), for: .touchUpInside)
        return peripheralWriteThreeBtn
    }()
    
    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .init(x: 0, y: centralReadBtn.maxY + 20, width: view.width, height: view.height - centralReadBtn.maxY - 20))
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: NSStringFromClass(UITableViewCell.self))
        tableView.allowsMultipleSelection = false
        tableView.delegate = self
        tableView.dataSource = self
        return tableView
    }()
    
    // MARK: - view
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        view.addSubview(lab)
        if UIDevice.current.model == "iPhone" {
            lab.text = "外设"
            view.addSubview(peripheralWriteOnceBtn)
            view.addSubview(peripheralWriteThreeBtn)
            peripheralManager = .init()
            peripheralManager?.delegate = self
        } else {
            lab.text = "调度中心"
            for centralWriteBtn in centralWriteBtns {
                view.addSubview(centralWriteBtn)
            }
            view.addSubview(centralReadBtn)
            view.addSubview(tableView)
            centralManager = .init()
            centralManager?.delegate = self
        }
    }
    
    @objc func touchCentralWriteBtn(_ sender: UIButton) {
        centralManager?.writeValue(text: "\(sender.tag)")
    }
    
    @objc func touchCentralReadBtn(_ sender: UIButton) {
        centralManager?.readPowerValue()
    }
    
    @objc func touchPeripheralWriteOnceBtn(_ sender: UIButton) {
        peripheralManager?.writeValue(count: 1)
    }
    
    @objc func touchPeripheralWriteThreeBtn(_ sender: UIButton) {
        peripheralManager?.writeValue(count: 3)
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        peripheralArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(UITableViewCell.self), for: indexPath)
        let temp = peripheralArray[indexPath.row]
        cell.textLabel?.text = temp.advertisementData[CBAdvertisementDataLocalNameKey] as? String ?? "nil"
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let temp = peripheralArray[indexPath.row]
        centralManager?.connect(peripheral: temp.peripheral)
    }
}

extension ViewController: CentralManagerDelegate {
    
    func discover(peripheralObject: PeripheralObject) {
        peripheralArray.append(peripheralObject)
        tableView.reloadData()
    }
    
    func readValue(centralManager: CBCentralManager, text: String) {
        let lab = UILabel(frame: view.bounds)
        lab.text = text
        lab.textColor = .black
        lab.textAlignment = .center
        lab.isUserInteractionEnabled = true
        view.addSubview(lab)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            lab.removeFromSuperview()
        }
    }
}

extension ViewController: PeripheralManagerDelegate {
    
    func readValue(peripheralManager: CBPeripheralManager, text: String) {
        let lab = UILabel(frame: view.bounds)
        lab.text = text
        lab.textColor = .black
        lab.textAlignment = .center
        lab.isUserInteractionEnabled = true
        view.addSubview(lab)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            lab.removeFromSuperview()
        }
    }
}
