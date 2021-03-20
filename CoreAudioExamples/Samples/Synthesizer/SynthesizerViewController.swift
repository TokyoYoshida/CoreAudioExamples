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
            waveGenerator.start()
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
}
