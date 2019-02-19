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
    
    var vc : ViewController?
    
    var mixer = AKMixer()
    
    var users = [User]()
    
    var config = "Column"
    
    let configDict = ["Sax":8, "Column": 2, "Outdoor": 5]
    
    let usernames = ["Omar Peracha’s iPhone", "iPhone von Viva", "iPhone",  "iPhone de Isandro Ojeda-García", "User5"]
    
    
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
        
        if input.first! == "0" {
            var _input = input
            _input.remove(at: _input.startIndex)
            let user = getUser(withName: _input)
            print("000_ setting bank")
            user?.setNextBank()
            return
        }

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
    var synth = AKAppleSampler()
    var synth2 = AKAppleSampler()
    var samplers = [ImpulsWaveTable]()
    var distanceThresh = 0.4
    var currentBank = 1
    
    var mixer1 = AKMixer()
    var mixer2 = AKMixer()
    var masterMixer = AKMixer()
    
    var pan = AKPanner()
    
    let outdoorSamples = ["1 Beep low compressed bounce.aif", "2 bird market process_bip.aif", "3 papers_bip.aif", "4 Suspiro bounce.aif", "5 Traffic bounce.aif"]
    
    let saxSamples = ["multiphonic1.wav", "multiphonic2.wav", "multiphonic3.wav", "multiphonic4.wav", "multiphonic5.wav", "multiphonic6.wav", "multiphonic7.wav", "multiphonic8.wav"]
    
    let colBank1 = [
                    "1 thump 1 TRIGGER.wav",
                    "2 lento su plastica 1 stretch.wav", "3 bump TRIGGER.wav", "4 lento su plastica 2 stretch.wav", "5 rapido su plastica 1 TRIGGER.wav", "none.wav", "none.wav", "8 rapido su plastica 2 TRIGGER.wav", "9 thump reverb TRIGGER.aif"]
    
    let colBank2 = ["1 lento polistirolo 1 stretch.wav", "2 distacco da polistirolo lento TRIGGER.wav", "3 lento polistirolo 2 stretch.wav", "4 distacco da polistirolo lento TRIGGER.wav", "5 superball grande 1.wav", "none.wav", "none.wav", "8 superball piccola 2.wav", "9 armonico grave multifonico TRIGGER.wav"]
    
    let colBank3 = ["1 righello verticale la.wav", "none.wav", "3_1 acciaccatura + battuto cluster 1 TRIGGER.wav", "4_1 acciaccatura + battuto la f TRIGGER.wav", "5 superball grande 1.wav", "none.wav", "none.wav", "8 superball piccola 2.wav", "none.wav"]
    
    let colBank4 = ["1 woodblock 2 TRIGGER.aif", "2 acuto stoppato 1 nota TRIGGER.wav", "3 acuto stoppato 1 nota TRIGGER.wav", "4 woodblock 3 TRIGGER.aif", "5 woodblock 1 TRIGGER.aif", "6 acuto stoppato 1 nota TRIGGER.wav", "7 acuto stoppato 1 nota TRIGGER.wav", "8 woodblock 4 TRIGGER.aif", "PA_1pendola tac TRIGGER.wav"]
    
    let colBank5 = ["1 acuto stoppato 3 note TRIGGER.wav", "2 acuto stoppato 1 nota TRIGGER.wav", "3 acuto stoppato 1 nota TRIGGER.wav", "4 acuto stoppato 3 note TRIGGER.wav", "5 acuto stoppato 3 note TRIGGER.wav", "6 acuto stoppato 1 nota TRIGGER.wav", "7 acuto stoppato 1 nota TRIGGER.wav", "8 acuto stoppato 3 note TRIGGER.wav", "none.wav"]
    
    let colBank6 = ["1 acuto stoppato 3 note TRIGGER.wav", "2 acuto stoppato 4 note TRIGGER.wav", "3 acuto stoppato 4 note TRIGGER.wav", "4 acuto stoppato 3 note TRIGGER.wav", "5 acuto stoppato 3 note TRIGGER.wav", "6 acuto stoppato 4 note TRIGGER.wav", "7 acuto stoppato 4 note TRIGGER.wav", "8 acuto stoppato 3 note TRIGGER.wav", "PA pioggia di aghi.wav"]
    
    let colBank7 = ["1 pendola tac TRIGGER.wav", "2 pendola tic TRIGGER.wav", "3 pendola tac TRIGGER.wav", "4 pendola tic TRIGGER.wav", "5 pendola tac TRIGGER.wav", "6 pendola tic TRIGGER.wav", "7 pendola tac TRIGGER.wav", "8 pendola tic TRIGGER.wav", "9 righello pendolo cresc TRIGGER.wav"]
    
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
            masterMixer >>> pan >>> conductor.mixer
            mixer1 >>> masterMixer
            mixer2 >>> masterMixer
        } else if conductor.config == "Outdoor" {
            mixer1 >>> conductor.mixer
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
            case "Outdoor":
                samples = outdoorSamples
            default:
                break
            }
            
            let sampleName = samples[i]
            
            let file = try! AKAudioFile(readFileName: sampleName)
            let sampler = ImpulsWaveTable(owner: self)
            sampler.load(file: file)
            samplers.append(sampler)
                
            if sampleName.contains("TRIGGER") {
                samplers[i].oneShot = true
                samplers[i].loopEnabled = false
                if i < 1{
                    do {try synth.loadAudioFile(file)} catch {print("000_ loading error")}
                } else {
                    do {try synth2.loadAudioFile(file)} catch {print("000_ loading error")}
                    }
            } else {
                samplers[i].loopEnabled = true
                samplers[i].oneShot = false
                samplers[i].volume = 0
            }
                
            if conductor.config == "Sax" {
                if i < mixerSplitIdx {
                    samplers[i] >>> mixer1
                } else {
                    samplers[i] >>> mixer2
                }
            } else if conductor.config == "Column" {
                if i < 1 {
                    if !samplers[i].oneShot {
                        samplers[i] >>> mixer1
                        samplers[i].play()
                    } else {
                        synth >>> mixer1
                    }
                } else {
                    if !samplers[i].oneShot {
                        samplers[i] >>> mixer2
                        samplers[i].play()
                    } else {
                        synth2 >>> mixer2
                    }
                }
            } else if conductor.config == "Outdoor" {
                samplers[i] >>> mixer1
            }
        }

    }
    
    func updateAmp(idx: Int, valDouble: Double, mixer: Double){
        
        if samplers.count <= idx  {
            return
        }
        
        let normalisedVal = Double(1 - (abs(valDouble)/distanceThresh))
        
        samplers[idx].updateVol(newVol: normalisedVal, idx: idx)
        //print("000_ \(idx) volume: \(normalisedVal)")
        
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
        
        let colBank = banks[(bank - 1) % banks.count]
        
        switch name {
        case conductor.usernames[0]:
            samples = [colBank[0], colBank[1]]
            pan.pan = (-1)
        case conductor.usernames[1]:
            samples = [colBank[2], colBank[3]]
            pan.pan = (1)
        case conductor.usernames[2]:
            samples = [colBank[4], colBank[5]]
            pan.pan = (-1)
        case conductor.usernames[3]:
            samples = [colBank[6], colBank[7]]
            pan.pan = (1)
        case conductor.usernames[4]:
            samples = [colBank[8]]
        default:
            break
        }
        
        return samples
    }
    
    func setNextBank(){
        
        conductor.lock.lock()
        defer {
            conductor.lock.unlock()
        }
        for sampler in samplers {
            sampler.stop()
            sampler.detach()
        }
        
        if samplers[0].oneShot {
        do {try synth.stop()} catch {print(error.localizedDescription)}
        synth.detach()
        }
        
        if samplers.count > 1 && samplers[1].oneShot {
        do {try synth2.stop()} catch {print(error.localizedDescription)}
        synth2.detach()
        }
        
        samplers.removeAll()
        
        currentBank += 1
        
        for i in 0 ..< numOscs {
            
            if name == conductor.usernames[4] && i > 0 {
                return
            }
            
            let samples = getColSamples(bank: currentBank)
            
            let sampleName = samples[i]
                
            let file = try! AKAudioFile(readFileName: sampleName)
            let sampler = ImpulsWaveTable(owner: self)
            sampler.load(file: file)
            samplers.append(sampler)
                
            if sampleName.contains("TRIGGER") {
                samplers[i].oneShot = true
                samplers[i].loopEnabled = true
                if i < 1{
                    do {try synth.loadAudioFile(file)} catch {print("000_ loading error")}
                } else {
                    do {try synth2.loadAudioFile(file)} catch {print("000_ loading error")}
                }
            } else {
                samplers[i].loopEnabled = true
                samplers[i].oneShot = false
                samplers[i].volume = 0
            }
                
            if i < 1 {
                if !samplers[i].oneShot {
                    samplers[i] >>> mixer1
                    samplers[i].play()
                } else {
                    synth >>> mixer1
                }
            } else {
                if !samplers[i].oneShot {
                    samplers[i] >>> mixer2
                    samplers[i].play()
                } else {
                    synth2 >>> mixer2
                }
            }
            
        }
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
        
        if samplers[0].oneShot{
            synth.detach()}
        
        if samplers.count > 1 && samplers[1].oneShot {
            synth2.detach()}
        
        oscillators.removeAll()
        samplers.removeAll()
        
    }
    
    
}

class ImpulsWaveTable: AKWaveTable {
    
    var oneShot = false
    var triggered = false
    var owner : User!
    
    init(owner: User){
        super.init()
        
        self.owner = owner
    }
    
    func updateVol(newVol: Double, idx: Int){
        
        if !oneShot {
            self.volume = newVol
        } else {
            
            if !self.triggered{
                
                if newVol > 0 {
                    self.triggered = true
                    print("TRIGGER")
                    if idx < 1 {
                    do {try owner.synth.play(noteNumber: 60, velocity: 127)} catch {print(error.localizedDescription)}
                    } else {
                        do {try owner.synth2.play(noteNumber: 60, velocity: 127)} catch {print(error.localizedDescription)}
                    }
                }
            } else if newVol <= 0 {
                self.triggered = false
            }
        }
        
    }
}


