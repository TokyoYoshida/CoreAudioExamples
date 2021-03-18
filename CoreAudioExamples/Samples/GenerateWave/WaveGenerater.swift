//
//  WaveGenerater.swift
//  CoreAudioExamples
//
//  Created by TokyoYoshida on 2021/03/18.
//

import Foundation
import AVFoundation

class WaveGenerater {
    var audioUnit: AudioUnit?
    
    func prepare() {
        var acd = AudioComponentDescription()
        acd.componentType = kAudioUnitType_Output
        acd.componentSubType = kAudioUnitSubType_RemoteIO
        acd.componentManufacturer = kAudioUnitManufacturer_Apple
        acd.componentFlags = 0
        acd.componentFlagsMask = 0
        
        let audioComponent = AudioComponentFindNext(nil, &acd)!
        
        AudioComponentInstanceNew(audioComponent, &audioUnit)

        AudioUnitInitialize(audioUnit!)
    }
}
