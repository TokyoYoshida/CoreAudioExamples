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
    static let sampleRate: Float = 44100.0
    static let toneA: Float = 440.0
    class RefConData {
        var frame: Float = 0
    }
    var refData: RefConData = RefConData()

    let renderCallBack: AURenderCallback = {(
        inRefCon: UnsafeMutableRawPointer,
        ioActionFlags: UnsafeMutablePointer<AudioUnitRenderActionFlags>,
        inTimeStamp: UnsafePointer<AudioTimeStamp>,
        inBusNumber: UInt32,
        inNumberFrames: UInt32,
        ioData: UnsafeMutablePointer<AudioBufferList>?) -> OSStatus in
        
        let refData = unsafeBitCast( inRefCon, to: WaveGenerater.RefConData.self)

        let abl = UnsafeMutableAudioBufferListPointer(ioData)
        let capacity = Int(abl![0].mDataByteSize) / MemoryLayout<Float>.size
        
        if let buffer = abl![0].mData?.bindMemory(to: Float.self, capacity: capacity) {
            for i in 0..<Int(inNumberFrames) {
                buffer[i] = sin(refData.frame * toneA * 2.0 * Float(Double.pi) / sampleRate)
                refData.frame += 1
            }
        }
        
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
            
            AudioUnitSetProperty(audioUnit!, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, 0, &callBackStruct, UInt32(MemoryLayout.size(ofValue: callBackStruct)))
        }
        func setAudioInputFormat() {
            var asbd = AudioStreamBasicDescription()
            
            asbd.mSampleRate = Float64(WaveGenerater.sampleRate)
            asbd.mFormatID = kAudioFormatLinearPCM
            asbd.mFormatFlags = kAudioFormatFlagIsFloat
            asbd.mChannelsPerFrame = 1
            asbd.mBytesPerPacket = UInt32(MemoryLayout<Float32>.size)
            asbd.mBytesPerFrame = UInt32(MemoryLayout<Float32>.size)
            asbd.mFramesPerPacket = 1
            asbd.mBitsPerChannel = UInt32(8 * MemoryLayout<Float32>.size)
            asbd.mReserved = 0

            AudioUnitSetProperty(audioUnit!, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &asbd, UInt32(MemoryLayout.size(ofValue: asbd)))
        }
        initAudioUnit()
        setRenderCallBack()
        setAudioInputFormat()
    }
    
    func start() {
        refData.frame = 0
        AudioOutputUnitStart(audioUnit!)
    }

    func stop() {
        AudioOutputUnitStop(audioUnit!)
    }
    
    func dispose() {
        AudioUnitUninitialize(audioUnit!)
        AudioComponentInstanceDispose(audioUnit!)
    }
}
