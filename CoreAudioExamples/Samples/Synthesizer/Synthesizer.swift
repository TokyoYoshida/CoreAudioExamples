//
//  Synthesizer.swift
//  CoreAudioExamples
//
//  Created by TokyoYoshida on 2021/03/20.
//

import Foundation
import AVFoundation

class Synthesizer {
    var audioUnit: AudioUnit?
    var audioEngine: AVAudioEngine = AVAudioEngine()
    var sampleRate: Float = 44100.0
    var time: Float = 0
    var deltaTime: Float = 0
    static let toneA: Float = 440.0
    var mainMixer: AVAudioMixerNode?
    var outputNode: AVAudioOutputNode?
    var format: AVAudioFormat?

    lazy var sourceNode = AVAudioSourceNode { [self] (_, _, frameCount, audioBufferList) -> OSStatus in
        let abl = UnsafeMutableAudioBufferListPointer(audioBufferList)
        for frame in 0..<Int(frameCount) {
            let sampleVal: Float = sin(Synthesizer.toneA * 2.0 * Float(Double.pi) * self.time)
            self.time += self.deltaTime
            for buffer in abl {
                let buf: UnsafeMutableBufferPointer<Float> = UnsafeMutableBufferPointer(buffer)
                buf[frame] = sampleVal
            }
        }
        return noErr
    }
    
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
        
        let refData = unsafeBitCast( inRefCon, to: Synthesizer.RefConData.self)

        let abl = UnsafeMutableAudioBufferListPointer(ioData)
        let capacity = Int(abl![0].mDataByteSize) / MemoryLayout<Float>.size
        
        if let buffer = abl![0].mData?.bindMemory(to: Float.self, capacity: capacity) {
            for i in 0..<Int(inNumberFrames) {
//                buffer[i] = sin(refData.frame * toneA * 2.0 * Float(Double.pi) / sampleRate)
                refData.frame += 1
            }
        }
        
        return noErr
    }
    func prepare() {
        func initAudioEngene() {
            mainMixer = audioEngine.mainMixerNode
            outputNode = audioEngine.outputNode
            format = outputNode!.inputFormat(forBus: 0)


            sampleRate = Float(format!.sampleRate)
            deltaTime = 1 / Float(sampleRate)
                                            
        }
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
            var callBackStruct = AURenderCallbackStruct(inputProc: renderCallBack, inputProcRefCon: Unmanaged<Synthesizer.RefConData>.passRetained(refData).toOpaque() )
            
            AudioUnitSetProperty(audioUnit!, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, 0, &callBackStruct, UInt32(MemoryLayout.size(ofValue: callBackStruct)))
        }
        func setAudioInputFormat() {
            var asbd = AudioStreamBasicDescription()
            
            asbd.mSampleRate = Float64(sampleRate)
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
        initAudioEngene()
//        initAudioUnit()
//        setRenderCallBack()
//        setAudioInputFormat()
    }
    
    func start() {
        refData.frame = 0
        let inputFormat = AVAudioFormat(commonFormat: format!.commonFormat, sampleRate: Double(sampleRate), channels: 1, interleaved: format!.isInterleaved)
        audioEngine.attach(sourceNode)
        audioEngine.connect(sourceNode, to: mainMixer!, format: inputFormat!)
        audioEngine.connect(mainMixer!, to: outputNode!, format: nil)
        mainMixer?.outputVolume = 1
        
        do {
            try audioEngine.start()
        } catch {
            fatalError("Coud not start engine: \(error.localizedDescription)")
        }
        
//        AudioOutputUnitStart(audioUnit!)
    }

    func stop() {
        audioEngine.stop()
//        AudioOutputUnitStop(audioUnit!)
    }
    
    func dispose() {
//        AudioUnitUninitialize(audioUnit!)
//        AudioComponentInstanceDispose(audioUnit!)
    }
}
