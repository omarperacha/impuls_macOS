//
//  ViewController.swift
//  impuls_MacOS
//
//  Created by Omar Peracha on 12/02/2019.
//  Copyright © 2019 Omar Peracha. All rights reserved.
//

import Cocoa

let conductor = AudioManager()

class ViewController: NSViewController {
    
    let audioService = AudioService()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        audioService.delegate = self
        conductor.setup()

        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

extension ViewController : AudioServiceDelegate {
    
    func connectedDevicesChanged(manager: AudioService, connectedDevices: [String]) {
        OperationQueue.main.addOperation {
            print(connectedDevices)
        }
    }
    
    func distanceChanged(manager: AudioService, distance: String) {
        OperationQueue.main.addOperation {
            conductor.updateAmp(input: distance)
        }
    }
    
}

