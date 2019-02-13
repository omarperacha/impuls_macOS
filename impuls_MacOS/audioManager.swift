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
    
    
    let Osc1 = AKOscillator()
    let Osc2 = AKOscillator()
    var mixer = AKMixer()
    
    func setup() {
        
        AKSettings.playbackWhileMuted = true
        
        Osc1.frequency = 440
        Osc2.frequency = 660
        mixer = AKMixer(Osc1, Osc2)
        mixer.volume = 1.0
        AudioKit.output = mixer
        
        do {try AudioKit.start()} catch {print(error.localizedDescription)}
        
        Osc1.start()
        Osc2.start()
        
    }
    
    func updateAmp(input: String){
        
        var oscToUpdate = Osc1
        
        if input.first == "b" {
            oscToUpdate = Osc2
        }
        
        var _input = input
        _input.remove(at: _input.startIndex)
        let valDouble = Double(_input)
        
        if valDouble != nil {
            oscToUpdate.amplitude = Double(1 - (abs(valDouble!)/4))}
        
    }
    
    
}
