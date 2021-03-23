//
//  SynthesizerViewController.swift
//  CoreAudioExamples
//
//  Created by TokyoYoshida on 2021/03/20.
//

import UIKit

class SynthesizerViewController: UIViewController {
    enum EffectorSwitch: Int {
        case Delay = 0
        case Phaser
        case Flanger
        case Distortion
    }
    @IBOutlet weak var playButton: UIButton!
    var isPlaying = false
    let waveGenerator = Synthesizer()
    var mixer = AudioMixer(TriangleOscillator())
    var effectorTable:[Int:Int] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()

        waveGenerator.prepare()
        // Do any additional setup after loading the view.
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        waveGenerator.dispose()
    }

    @IBAction func tappedPlayButton(_ sender: Any) {
        func start() {
            playButton.setTitle("Stop", for: .normal)
//            mixer.addEffector(effector: FlangerEffector())
//            mixer.addEffector(effector: DelayEffector())
            waveGenerator.setAudioSource(audioSource: mixer)
            waveGenerator.start()
            waveGenerator.volume = 0.5
        }
        func stop() {
            playButton.setTitle("Play", for: .normal)
            waveGenerator.stop()
        }
        if isPlaying {
            isPlaying = false
            stop()
        } else {
            isPlaying = true
            start()
        }
    }

    @IBAction func movedSlider(_ sender: UISlider) {
        waveGenerator.volume = sender.value
    }
    
    @IBAction func movedTone(_ sender: UISlider) {
        let toneA0: Float = 27.50
        let toneA5: Float = 880.0
        
        waveGenerator.tone = (toneA5-toneA0) * sender.value + toneA0
    }
    
    @IBAction func tappedOscillator(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            mixer.setOscillator(oscillator: SinOscillator())
        } else {
            mixer.setOscillator(oscillator: TriangleOscillator())
        }
    }
    
    @IBAction func tappedEffector(_ sender: UISwitch) {
        func addEffector(_ tag:Int, _ effector: Effector) {
            let index = mixer.addEffector(effector: effector)
            effectorTable[tag] = index
        }
        func removeEffector(_ tag:Int) {
            guard let index = effectorTable[tag] else { fatalError("Wrong tag.") }
            mixer.removeEffector(at: index)
        }
        let effector = EffectorSwitch(rawValue: sender.tag)
        switch effector {
        case .Delay:
            if sender.isOn {
                addEffector(sender.tag, DelayEffector())
            } else {
                removeEffector(sender.tag)
            }
        case .Phaser:
            break
        case .Flanger:
            break
        case .Distortion:
            break
        case .none:
            break
        }
    }
}
