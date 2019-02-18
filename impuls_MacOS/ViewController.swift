//
//  ViewController.swift
//  impuls_MacOS
//
//  Created by Omar Peracha on 12/02/2019.
//  Copyright © 2019 Omar Peracha. All rights reserved.
//

import Cocoa
import MultipeerConnectivity


let conductor = AudioManager()

class ViewController: NSViewController {
    
    let audioService = AudioService()

    @IBOutlet weak var OPCheckBox: NSButton!
    
    @IBAction func toggleOP(_ sender: Any) {
        let string = "Omar Peracha’s iPhone"
        audioService.entryDict[string] = Bool(truncating: OPCheckBox.state.rawValue as NSNumber)
    }
    
    @IBOutlet weak var OPStatus: NSButton!
    
    @IBAction func OPConnectButton(_ sender: Any) {
        if OPStatus.title == "Manual Connect" {
            var peerId : MCPeerID?
            for peer in audioService.nearbyPeers{
                if peer.displayName == "Omar Peracha’s iPhone" {
                    peerId = peer
                    break
                }
            }
            if peerId == nil {return}
            print(peerId!)
            audioService.serviceBrowser.invitePeer(peerId!, to: audioService.session, withContext: nil, timeout: 10)
        }
    }
    
    @IBOutlet weak var VSCheckBox: NSButton!
    
    @IBAction func toggleVS(_ sender: Any) {
        let string = "iPhone von Viva"
        audioService.entryDict[string] = Bool(truncating: VSCheckBox.state.rawValue as NSNumber)
    }
    
    @IBOutlet weak var VSStatus: NSButton!
    
    @IBAction func VSConnectButton(_ sender: Any) {
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        conductor.vc = self
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
            conductor.updateSound(input: distance)
        }
    }
    
    func lostPeer(ID: String){
        switch ID {
        case "i":
            break
        default:
            break
        }
    }
    
    func newPeer(ID: String){
        switch ID {
        case "i":
            break
        default:
            break
        }
    }
    
}

