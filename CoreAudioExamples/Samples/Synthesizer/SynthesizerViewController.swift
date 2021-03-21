//
//  SynthesizerViewController.swift
//  CoreAudioExamples
//
//  Created by TokyoYoshida on 2021/03/20.
//

import UIKit

class SynthesizerViewController: UIViewController {
    @IBOutlet weak var playButton: UIButton!
    var isPlaying = false
    let waveGenerator = Synthesizer()
    
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
            waveGenerator.setAudioSource(audioSource: TriangleOscillator())
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
}
