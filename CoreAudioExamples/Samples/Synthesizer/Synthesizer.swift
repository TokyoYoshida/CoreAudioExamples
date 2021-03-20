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
    var oscillator: Oscillator?

    lazy var sourceNode = AVAudioSourceNode { [self] (_, _, frameCount, audioBufferList) -> OSStatus in
        let abl = UnsafeMutableAudioBufferListPointer(audioBufferList)
        guard let oscillator = self.oscillator else {fatalError("Oscillator is nil")}
        for frame in 0..<Int(frameCount) {
            let sampleVal: Float = oscillator.signal(time: self.time)
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
    
    func setOscillator(oscillator: Oscillator) {
        self.oscillator = oscillator
    }

    func stop() {
        audioEngine.stop()
    }
    
    func dispose() {
    }
}

protocol Oscillator {
    func signal(time: Float) -> Float
}

class SinOscillator: Oscillator {
    func signal(time: Float) -> Float {
        sin(Synthesizer.toneA * 2.0 * Float(Double.pi) * time)
    }
}
