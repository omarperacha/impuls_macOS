//
//  audioManager.swift
//  impuls_MacOS
//
//  Created by Omar Peracha on 12/02/2019.
//  Copyright © 2019 Omar Peracha. All rights reserved.
//

import Foundation
import AudioKit

class AudioManager {
    
    let lock = NSLock()
    private var audioKitRunning = false
    
    var mixer = AKMixer()
    
    var users = [User]()
    
    var config = "Column"
    
    let configDict = ["Sax":8, "Column": 2, "Game": 8]
    
    let usernames = ["User1", "User2",  "User3",  "User4", "User5"]
    
    
    func setup() {
        
        if audioKitRunning {
            return
        }
        
        lock.lock()
        
        mixer.volume = 1.0
        AudioKit.output = mixer
        
        do {try AudioKit.start()} catch {print(error.localizedDescription)}
    
        
        audioKitRunning = true
        
        lock.unlock()
    }
    
    func initUser(name: String) {
        
        let newUser = User(name: name)
        users.append(newUser)
        
    }
    
    func updateSound(input: String){

        let alphabet = "abcdefghijklmnopqrstuvwxyz"
        
        let idx = alphabet.distance(from: alphabet.startIndex, to: alphabet.index(of: input.first!)!)
        
        var _input = input
        _input.remove(at: _input.startIndex)
        let parsed = _input.components(separatedBy: " ")
        let valDouble = Double(parsed[0])
        let mixerDouble = Double(parsed[1])
        
        var name = ""
        
        for i in 2 ..< parsed.count {
            name += parsed[i]
            if i < (parsed.count - 1) {
                name += " "
            }
        }
        
        let user = getUser(withName: name)
        
        if user != nil && valDouble != nil && mixerDouble != nil {
            user?.updateAmp(idx: idx, valDouble: valDouble!, mixer: mixerDouble!)
        }
        
    }
    
    
    func tearDown(){
        
        for user in users{
            user.disconnect()
        }
        
        users.removeAll()
        
        lock.lock()
        
        do {
            try AudioKit.stop()
        } catch {print(error.localizedDescription)}
        
        audioKitRunning = false
        
        lock.unlock()
    }
    
    func getUser(withName: String) -> User? {
        
        for user in users {
            if user.name == withName {
                return user
            }
        }
        return nil
    }
    
    func removeUser(withName: String) {
        for i in 0 ..< users.count {
            if users[i].name == withName {
                users.remove(at: i)
                return
            }
        }
    }
    
    
    func destroyUser(withName: String){
        let user = getUser(withName: withName)
        user?.disconnect()
        removeUser(withName: withName)
    }
    
    
    
}


class User {
    
    var name = ""
    let mixerSplitIdx = 4
    var numOscs = 8
    var oscillators = [AKOscillator]()
    var samplers = [ImpulsWaveTable]()
    var distanceThresh = 0.4
    var currentBank = 1
    
    var mixer1 = AKMixer()
    var mixer2 = AKMixer()
    
    var pan = AKPanner()
    
    let saxSamples = ["multiphonic1.wav", "multiphonic2.wav", "multiphonic3.wav", "multiphonic4.wav", "multiphonic5.wav", "multiphonic6.wav", "multiphonic7.wav", "multiphonic8.wav"]
    
    let colBank1 = [""]
    let colBank2 = [""]
    let colBank3 = [""]
    let colBank4 = [""]
    let colBank5 = [""]
    let colBank6 = [""]
    let colBank7 = [""]
    
    init(name: String) {
        
        self.name = name
        
        conductor.lock.lock()
        defer {
            conductor.lock.unlock()
        }
        
        self.numOscs = conductor.configDict[conductor.config] ?? 4
        
        if conductor.config == "Sax" {
            mixer1 >>> conductor.mixer
            mixer2 >>> conductor.mixer
        } else if conductor.config == "Column" {
            pan >>> conductor.mixer
        }
        
        for i in 0 ..< numOscs {
            
            if name == conductor.usernames[4] && i > 0 {
                return
            }
            
            var samples = [""]
            switch conductor.config {
            case "Sax":
                samples = saxSamples
            case "Column":
                samples = getColSamples(bank: currentBank)
            default:
                break
            }
            
            let file = try! AKAudioFile(readFileName: samples[i])
            let sampler = ImpulsWaveTable(file: file)
            samplers.append(sampler)
            samplers[i].loopEnabled = true
            samplers[i].volume = 0
            
            if conductor.config == "Sax" {
                if i < mixerSplitIdx {
                    samplers[i] >>> mixer1
                } else {
                    samplers[i] >>> mixer2
                }
            } else {
                samplers[i] >>> pan
            }
            
            samplers[i].play()
            
        }
        

    }
    
    func updateAmp(idx: Int, valDouble: Double, mixer: Double){
        
        if samplers.count < 1 {
            return
        }
        
        let normalisedVal = Double(1 - (abs(valDouble)/distanceThresh))
        
        samplers[idx].updateVol(newVol: normalisedVal)
        print("000_ \(idx) volume: \(samplers[idx].volume)")
        
        if conductor.config == "Sax" {
            
            samplers[idx + mixerSplitIdx].volume = normalisedVal
            let balance = min(1, max(0, (mixer - 0)/90))
            mixer1.volume = 1 - balance
            mixer2.volume = balance
        }
        
       
    }
    
    func getColSamples(bank: Int) -> [String]{
        var samples = [""]
        
        let banks = [colBank1, colBank2, colBank3, colBank4, colBank5, colBank6, colBank7]
        
        let colBank = banks[bank - 1]
        
        switch name {
        case conductor.usernames[0]:
            samples = [colBank[0], colBank[1]]
        case conductor.usernames[1]:
            samples = [colBank[2], colBank[3]]
        case conductor.usernames[2]:
            samples = [colBank[4], colBank[5]]
        case conductor.usernames[3]:
            samples = [colBank[6], colBank[7]]
        case conductor.usernames[4]:
            samples = [colBank[8]]
        default:
            break
        }
        
        return samples
    }
    
    func mute(){
        for osc in oscillators {
            osc.amplitude = 0
        }
        for sampler in samplers {
            sampler.volume = 0
        }
    }
    
    func disconnect() {
        
        conductor.lock.lock()
        defer {
            conductor.lock.unlock()
        }
        
        mute()
        for osc in oscillators {
            osc.detach()
        }
        for sampler in samplers {
            sampler.detach()
        }
        
        mixer1.detach()
        mixer2.detach()
        
        oscillators.removeAll()
        samplers.removeAll()
    }
    
    
}

class ImpulsWaveTable: AKWaveTable {
    
    var oneShot = false
    var triggered = false
    
    func updateVol(newVol: Double){
        
        if !oneShot {
            self.volume = newVol
        } else {
            
            if !self.triggered{
                
                if newVol > 0 {
                    self.volume = 1
                    self.triggered = true
                } else {
                    self.volume = 0
                    self.triggered = false
                }
                
            }
            
        }
        
    }
}
