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
    
    lazy var centralWriteBtn: UIButton = {
        let centralWriteBtn = UIButton(frame: .init(x: (view.width - 100) * 0.5, y: lab.maxY + 20, width: 100, height: 45))
        centralWriteBtn.setTitle("中心写", for: .normal)
        centralWriteBtn.setTitleColor(.black, for: .normal)
        centralWriteBtn.addTarget(self, action: #selector(touchCentralWriteBtn(_:)), for: .touchUpInside)
        return centralWriteBtn
    }()
    
    lazy var centralReadBtn: UIButton = {
        let centralWriteBtn = UIButton(frame: .init(x: (view.width - 100) * 0.5, y: centralWriteBtn.maxY + 20, width: 100, height: 45))
        centralWriteBtn.setTitle("中心读", for: .normal)
        centralWriteBtn.setTitleColor(.black, for: .normal)
        centralWriteBtn.addTarget(self, action: #selector(touchCentralReadBtn(_:)), for: .touchUpInside)
        return centralWriteBtn
    }()
    
    lazy var centralReadRemainBtn: UIButton = {
        let centralReadRemainBtn = UIButton(frame: .init(x: (view.width - 100) * 0.5, y: centralReadBtn.maxY + 20, width: 100, height: 45))
        centralReadRemainBtn.setTitle("中心持续读", for: .normal)
        centralReadRemainBtn.setTitleColor(.black, for: .normal)
        centralReadRemainBtn.addTarget(self, action: #selector(touchCentralReadRemainBtn(_:)), for: .touchUpInside)
        return centralReadRemainBtn
    }()
    
    lazy var lineView: UIView = {
        let lineView = UIView(frame: .init(x: (view.width - 2) * 0.5, y: 0, width: 2, height: view.height))
        lineView.backgroundColor = .black
        return lineView
    }()
    
    lazy var peripheralWriteBtn: UIButton = {
        let centralWriteBtn = UIButton(frame: .init(x: (view.width - 100) * 0.5, y: lab.maxY + 20, width: 100, height: 45))
        centralWriteBtn.setTitle("外设写", for: .normal)
        centralWriteBtn.setTitleColor(.black, for: .normal)
        centralWriteBtn.addTarget(self, action: #selector(touchPeripheralWriteBtn(_:)), for: .touchUpInside)
        return centralWriteBtn
    }()
    
    lazy var peripheralReadBtn: UIButton = {
        let centralWriteBtn = UIButton(frame: .init(x: (view.width - 100) * 0.5, y: peripheralWriteBtn.maxY + 20, width: 100, height: 45))
        centralWriteBtn.setTitle("外设读", for: .normal)
        centralWriteBtn.setTitleColor(.black, for: .normal)
        centralWriteBtn.addTarget(self, action: #selector(touchPeripheralReadBtn(_:)), for: .touchUpInside)
        return centralWriteBtn
    }()
    
    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .init(x: 0, y: centralReadRemainBtn.maxY + 20, width: view.width, height: view.height - centralReadBtn.maxY - 20))
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
            lab.text = "调度中心"
            view.addSubview(centralWriteBtn)
            view.addSubview(centralReadBtn)
            view.addSubview(centralReadRemainBtn)
            view.addSubview(tableView)
            centralManager = .init()
            centralManager?.delegate = self
        } else {
            lab.text = "外设"
            view.addSubview(peripheralWriteBtn)
            view.addSubview(peripheralReadBtn)
            peripheralManager = .init()
        }
    }
    
    @objc func touchCentralWriteBtn(_ sender: UIButton) {
        centralManager?.writeValue()
    }
    
    @objc func touchCentralReadBtn(_ sender: UIButton) {
        centralManager?.readValue()
    }
    
    @objc func touchCentralReadRemainBtn(_ sender: UIButton) {
        centralManager?.readRemainValue()
    }
    
    @objc func touchPeripheralWriteBtn(_ sender: UIButton) {
        
    }
    
    @objc func touchPeripheralReadBtn(_ sender: UIButton) {
        
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
}

