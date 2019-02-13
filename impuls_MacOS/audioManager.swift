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
    
    let numOscs = 2
    var oscillators = [AKOscillator]()
    var mixer = AKMixer()
    
    func setup() {
        
        AKSettings.playbackWhileMuted = true
        
        for i in 0 ..< numOscs {
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
        
        if input.first == "b" {
            oscToUpdate = oscillators[1]
        }
        
        var _input = input
        _input.remove(at: _input.startIndex)
        let parsed = _input.components(separatedBy: " ")
        let valDouble = Double(parsed[0])
        
        if valDouble != nil {
            oscToUpdate.amplitude = Double(1 - (abs(valDouble!)/4))}
        
    }
    
    func mute(){
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
    
    
}
