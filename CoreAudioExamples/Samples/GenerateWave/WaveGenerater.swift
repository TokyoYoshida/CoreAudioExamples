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
    class RefConData {
    }
    var refData: RefConData = RefConData()

    let renderCallBack: AURenderCallback = {(
        inRefCon: UnsafeMutableRawPointer,
        ioActionFlags: UnsafeMutablePointer<AudioUnitRenderActionFlags>,
        inTimeStamp: UnsafePointer<AudioTimeStamp>,
        inBusNumber: UInt32,
        inNumberFrames: UInt32,
        ioData: UnsafeMutablePointer<AudioBufferList>?) -> OSStatus in
        return noErr
    }
    
    func prepare() {
        func initAudioUnit() {
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
        func setRenderCallBack() {
            var callBackStruct = AURenderCallbackStruct(inputProc: renderCallBack, inputProcRefCon: Unmanaged<WaveGenerater.RefConData>.passRetained(refData).toOpaque() )
        }
        initAudioUnit()
        setRenderCallBack()
    }
    
}
