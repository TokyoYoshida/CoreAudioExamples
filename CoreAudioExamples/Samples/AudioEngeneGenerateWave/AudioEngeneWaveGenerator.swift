//
//  AudioEngeneWaveGenerator.swift
//  CoreAudioExamples
//
//  Created by TokyoYoshida on 2021/03/20.
//

import Foundation
import AVFoundation

class AudioEngeneWaveGenerator {
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
            let sampleVal: Float = sin(AudioEngeneWaveGenerator.toneA * 2.0 * Float(Double.pi) * self.time)
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


    func prepare() {
        func initAudioEngene() {
            mainMixer = audioEngine.mainMixerNode
            outputNode = audioEngine.outputNode
            format = outputNode!.inputFormat(forBus: 0)


            sampleRate = Float(format!.sampleRate)
            deltaTime = 1 / Float(sampleRate)
                                            
        }
        initAudioEngene()
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
    }

    func stop() {
        audioEngine.stop()
    }
    
    func dispose() {
        stop()
    }
}
