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
    
    let midiNotes = [36, 68]
    let numOscs = 2
    var oscillators = [AKOscillator]()
    var mixer = AKMixer()
    
    func setup() {
        
        AKSettings.playbackWhileMuted = true
        
        midi.openOutput()
        
        for _ in 0 ..< numOscs {
            oscillators.append(AKOscillator())
        }
        
        oscillators[0].frequency = 440
        oscillators[1].frequency = 660
        
        for osc in oscillators {
            osc.amplitude = 0
            
            osc >>> mixer
        }
        
        mixer.volume = 1.0
        AudioKit.output = mixer
        
        do {try AudioKit.start()} catch {print(error.localizedDescription)}
        
        for osc in oscillators {
            osc.start()
        }
        
    }
    
    func updateAmp(input: String){
        
        var oscToUpdate = oscillators[0]
        var note = midiNotes[0]
        
        if input.first == "b" {
            oscToUpdate = oscillators[1]
            note = midiNotes[1]
        }
        
        var _input = input
        _input.remove(at: _input.startIndex)
        let parsed = _input.components(separatedBy: " ")
        let valDouble = Double(parsed[0])
        
        if valDouble != nil {
            let normalisedVal = Double(1 - (abs(valDouble!)/4))
            let midiVal = Int(max(normalisedVal * 127, 0))
            
            noteOn(note: note, vel: midiVal)
            
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
        
        
        do {
            try AudioKit.stop()
        } catch {print(error.localizedDescription)}
    }
    
    func noteOn(note: Int, vel: Int) {
        midi.sendEvent(AKMIDIEvent(noteOn: MIDINoteNumber(note), velocity: MIDIVelocity(vel), channel: 1))
    }
    
}
