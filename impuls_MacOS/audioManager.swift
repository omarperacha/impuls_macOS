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
    
    
    let midi = AudioKit.midi
    private var audioKitRunning = false
    
    var mixer = AKMixer()
    
    var users = [User]()
    
    
    func setup() {
        
        if audioKitRunning {
            return
        }
        
        AKSettings.playbackWhileMuted = true
        
        midi.openOutput()
        
        
        mixer.volume = 1.0
        AudioKit.output = mixer
        
        do {try AudioKit.start()} catch {print(error.localizedDescription)}
    
        
        audioKitRunning = true
        
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
            user?.updateAmp(idx: idx, valDouble: valDouble!, mixer: mixerDouble!)
        }
        
    }
    
    
    func tearDown(){
        
        for user in users{
            user.disconnectOscillators()
        }
        
        users.removeAll()
        
        do {
            try AudioKit.stop()
        } catch {print(error.localizedDescription)}
        
        audioKitRunning = false
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
    
    
    
}



class User {
    
    var name = ""
    var midiNotes = [Int]()
    let numOscs = 5
    var oscillators = [AKOscillator]()
    var samplers = [AKWaveTable]()
    var tubularBells = [ImpulsBell]()
    var distanceThresh = 0.2
    
    let samples = ["air.wav", "multiphonic1.wav", "ton.wav", "multiphonic2.wav", "ton unstable.wav", "multiphonic3.wav", "slap open.wav", "slap1.wav", "slap2.wav"]
    
    init() {
        for i in 0 ..< numOscs {
            midiNotes.append(36 + i*8 + 3*(conductor.users.count))
            oscillators.append(AKOscillator())
            oscillators[i].frequency = 220 + i*220 + (conductor.users.count * 110)
            oscillators[i].amplitude = 0
            
            oscillators[i] >>> conductor.mixer
            oscillators[i].start()
            
            let file = try! AKAudioFile(readFileName: samples[((conductor.users.count)*numOscs + i) % samples.count])
            let sampler = AKWaveTable(file: file)
            samplers.append(sampler)
            samplers[i].loopEnabled = true
            samplers[i].volume = 0
            
            samplers[i] >>> conductor.mixer
            samplers[i].play()
            
            let tubularBell = ImpulsBell()
            tubularBells.append(tubularBell)
            tubularBells[i] >>> conductor.mixer
        }
        
    }
    
    func noteOn(note: Int, vel: Int) {
        conductor.midi.sendEvent(AKMIDIEvent(noteOn: MIDINoteNumber(note), velocity: MIDIVelocity(vel), channel: 1))
    }
    
    func updateAmp(idx: Int, valDouble: Double, mixer: Double){
        
        if oscillators.count < 1 {
            return
        }
        
        let normalisedVal = Double(1 - (abs(valDouble)/distanceThresh))
        let midiVal = Int(max(normalisedVal * 127, 0))
            
        if midiVal > 0 {
            noteOn(note: midiNotes[idx], vel: midiVal)
            if !tubularBells[idx].triggered{
                tubularBells[idx].trigger(frequency: 110 + (110*idx), amplitude: 1)
                tubularBells[idx].triggered = true
            }
        } else {
            conductor.midi.sendNoteOffMessage(noteNumber: MIDINoteNumber(midiNotes[idx]), velocity: 0)
            tubularBells[idx].triggered = false
        }
        //oscillators[idx].amplitude = normalisedVal
        
        if samplers.count > 0 {
            samplers[idx].volume = normalisedVal
        }
        
        
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
    
    func disconnectOscillators() {
        mute()
        for osc in oscillators {
            osc.detach()
        }
        for sampler in samplers {
            sampler.detach()
        }
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
