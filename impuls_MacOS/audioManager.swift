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
    
    
    private let midi = AudioKit.midi
    var audioKitRunning = false
    
    var midiNotes = [Int]()
    let numOscs = 5
    var oscillators = [AKOscillator]()
    var mixer = AKMixer()
    var distanceThresh = 0.15
    
    func setup() {
        
        if audioKitRunning {
            return
        }
        
        AKSettings.playbackWhileMuted = true
        
        midi.openOutput()
        
        for i in 0 ..< numOscs {
            midiNotes.append(36 + i*8)
            oscillators.append(AKOscillator())
            oscillators[i].frequency = 220 + i*220
            oscillators[i].amplitude = 0
            oscillators[i] >>> mixer
        }
        
        mixer.volume = 1.0
        AudioKit.output = mixer
        
        do {try AudioKit.start()} catch {print(error.localizedDescription)}
        
        for osc in oscillators {
            osc.start()
        }
        
        audioKitRunning = true
        
    }
    
    func updateAmp(input: String){
        
        if oscillators.count < 1 {
            return
        }
        
        let alphabet = "abcdefghijklmnopqrstuvwxyz"
        
        let idx = alphabet.distance(from: alphabet.startIndex, to: alphabet.index(of: input.first!)!)
        
        var _input = input
        _input.remove(at: _input.startIndex)
        let parsed = _input.components(separatedBy: " ")
        let valDouble = Double(parsed[0])
        
        if valDouble != nil {
            let normalisedVal = Double(1 - (abs(valDouble!)/distanceThresh))
            let midiVal = Int(max(normalisedVal * 127, 0))
            
            if midiVal > 0 {
                noteOn(note: midiNotes[idx], vel: midiVal)
            } else {
                midi.sendNoteOffMessage(noteNumber: MIDINoteNumber(midiNotes[idx]), velocity: 0)
            }
            //oscillators[idx].amplitude = normalisedVal
            
        }
        
    }
    
    func mute(){
        for note in midiNotes{
            midi.sendNoteOffMessage(noteNumber: MIDINoteNumber(note), velocity: 0)
        }
        for osc in oscillators {
            osc.amplitude = 0
        }
    }
    
    func disconnectOscillatros() {
        mute()
        for osc in oscillators {
            osc.detach()
        }
        oscillators.removeAll()
    }
    
    func tearDown(){
        
        for osc in oscillators {
            osc.detach()
        }
        
        mixer.detach()
        
        oscillators.removeAll()
        midiNotes.removeAll()
        
        
        do {
            try AudioKit.stop()
        } catch {print(error.localizedDescription)}
        
        audioKitRunning = false
    }
    
    func noteOn(note: Int, vel: Int) {
        midi.sendEvent(AKMIDIEvent(noteOn: MIDINoteNumber(note), velocity: MIDIVelocity(vel), channel: 1))
    }
    
}
