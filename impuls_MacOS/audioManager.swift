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
    let midi = AudioKit.midi
    private var audioKitRunning = false
    
    var mixer = AKMixer()
    
    var users = [User]()
    
    var config = "Sax"
    
    
    func setup() {
        
        if audioKitRunning {
            return
        }
        
        lock.lock()
        
        AKSettings.playbackWhileMuted = true
        
        midi.openOutput()
        
        
        mixer.volume = 1.0
        AudioKit.output = mixer
        
        do {try AudioKit.start()} catch {print(error.localizedDescription)}
    
        
        audioKitRunning = true
        
        lock.unlock()
    }
    
    func initUser(name: String) {
        
        let newUser = User()
        newUser.name = name
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
            print("000_ \(idx) volume: \(valDouble!)")
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
    var midiNotes = [Int]()
    let mixerSplitIdx = 4
    let numOscs = 8
    var oscillators = [AKOscillator]()
    var samplers = [AKWaveTable]()
    var distanceThresh = 0.4
    
    var mixer1 = AKMixer()
    var mixer2 = AKMixer()
    var dryWet = AKDryWetMixer()
    
    let samples = ["multiphonic1.wav", "multiphonic2.wav", "multiphonic3.wav", "multiphonic4.wav", "multiphonic5.wav", "multiphonic6.wav", "multiphonic7.wav", "multiphonic8.wav"]
    
    init() {
        
        conductor.lock.lock()
        defer {
            conductor.lock.unlock()
        }
        
        mixer1 >>> conductor.mixer
        mixer2 >>> conductor.mixer

        for i in 0 ..< numOscs {
            
            midiNotes.append(36 + i*8 + 3*(conductor.users.count))
            
            let file = try! AKAudioFile(readFileName: samples[i])
            let sampler = AKWaveTable(file: file)
            samplers.append(sampler)
            samplers[i].loopEnabled = true
            samplers[i].volume = 0
            
            
            if i < mixerSplitIdx {
                samplers[i] >>> mixer1
            } else {
                samplers[i] >>> mixer2
                print("000_ connected to mixer 2")
            }
            
            samplers[i].play()
            
        }
        

    }
    
    func noteOn(note: Int, vel: Int) {
        conductor.midi.sendEvent(AKMIDIEvent(noteOn: MIDINoteNumber(note), velocity: MIDIVelocity(vel), channel: 1))
    }
    
    func updateAmp(idx: Int, valDouble: Double, mixer: Double){
        
        if conductor.config != "Sax" && oscillators.count < 1 {
            return
        }
        
        let normalisedVal = Double(1 - (abs(valDouble)/distanceThresh))
        let midiVal = Int(max(normalisedVal * 127, 0))
            
        if midiVal > 0 {
            noteOn(note: midiNotes[idx], vel: midiVal)
        } else {
            conductor.midi.sendNoteOffMessage(noteNumber: MIDINoteNumber(midiNotes[idx]), velocity: 0)
        }
        
        if samplers.count > 0 {
            samplers[idx].volume = normalisedVal
            if conductor.config == "Sax" {
                samplers[idx + mixerSplitIdx].volume = normalisedVal
            }
        }
        
        let balance = min(1, max(0, (mixer - 0)/90))
        mixer1.volume = 1 - balance
        mixer2.volume = balance
        
        print("000_ mixer 1: \(mixer1.volume), mixer 2: \(mixer2.volume)")
        
    }
    
    func mute(){
        for note in midiNotes{
            conductor.midi.sendNoteOffMessage(noteNumber: MIDINoteNumber(note), velocity: 0)
        }
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

class ImpulsBell: AKTubularBells {
    
    var triggered = false
    
    init(){
        super.init()
    }
}
