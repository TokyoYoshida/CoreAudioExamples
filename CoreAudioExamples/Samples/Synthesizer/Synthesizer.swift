//
//  Synthesizer.swift
//  CoreAudioExamples
//
//  Created by TokyoYoshida on 2021/03/20.
//

import Foundation
import AVFoundation

class Synthesizer {
    private var audioEngine: AVAudioEngine = AVAudioEngine()
    private var sampleRate: Float = 44100.0
    private var time: Float = 0
    private var deltaTime: Float = 0
    private var mainMixer: AVAudioMixerNode?
    private var outputNode: AVAudioOutputNode?
    private var format: AVAudioFormat?
    private var oscillator: Oscillator?
    
    var volume: Float {
        set {
            audioEngine.mainMixerNode.outputVolume = newValue
        }
        get {
            return audioEngine.mainMixerNode.outputVolume
        }
    }
    
    var tone: Float? {
        set {
            if let newValue = newValue {
                oscillator?.tone = newValue
            }
        }
        get {
            oscillator?.tone
        }
    }

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
        mainMixer?.outputVolume = 0
        
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
        stop()
    }
}

protocol Oscillator {
    var tone: Float {get set}
    func signal(time: Float) -> Float
}

class SinOscillator: Oscillator {
    var tone: Float = 440.0
    func signal(time: Float) -> Float {
        sin(tone * 2.0 * Float(Double.pi) * time)
    }
}

class TriangleOscillator: Oscillator {
    var tone: Float = 440

    func signal(time: Float) -> Float {
        let amplitude: Float = 1
        let periood = 1.0 / Double(tone)
        let currentTime = fmod(Double(time), periood)
        let value = currentTime / periood
        
        var result = 0.0
        
        switch value {
        case 0..<0.25:
            result = value * 4
        case 0.25..<0.75:
            result = 2.0 - (value * 4.0)
        default:
            result = value * 4 - 4.0
        }
        return amplitude * Float(result)
    }
}

class RingBuffer<T> {
    let max: Int
    var data: [T?]
    var head: Int = 0
    var num: Int = 0
    
    init(_ max: Int) {
        self.max = max
        self.data = Array<T?>(repeating: nil, count: max)
    }
    
    func enqueue(_ data: T) -> Bool {
        guard num < max else { return false }
            
        self.data[(head + num) % max] = data
        num += 1
        return true
    }
    
    func dequeue() -> T? {
        guard num > 0 else { return nil }
        
        let ret = self.data[head]
        data[head] = nil
        num -= 1
        head = (head + 1) % max
 
        return ret
    }
}

protocol Effector {
    func signal(waveValue: Float) -> Float
}

class DelayEffector: Effector {
    var delayCount = 100
    lazy var buffer = RingBuffer<Float>(delayCount)
    var index: Int = 0

    func signal(waveValue: Float) -> Float {
        if !buffer.enqueue(waveValue) {
            fatalError("Cannot enqueue buffer.")
        }
        if delayCount > 0 {
            delayCount -= 1
            return waveValue
        }
        if let delayValue = buffer.dequeue() {
            return waveValue + delayValue/10
        }
        fatalError("Cannot dequeue buffer.")
    }
}
