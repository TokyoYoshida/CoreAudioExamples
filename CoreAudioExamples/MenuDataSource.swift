//
//  MenuDataSource.swift
//  ExampleOfiOSLiDAR
//
//  Created by TokyoYoshida on 2021/01/31.
//

import UIKit

struct MenuItem {
    let title: String
    let description: String
    let prefix: String
    
    func viewController() -> UIViewController {
        let storyboard = UIStoryboard(name: prefix, bundle: nil)
        let vc = storyboard.instantiateInitialViewController()!
        vc.title = title

        return vc
    }
}

class MenuViewModel {
    private let dataSource = [
        MenuItem (
            title: "AudioUnit Recording",
            description: "Sound recording using AudioUnit.",
            prefix: "AudioUnitRecording"
        ),
        MenuItem (
            title: "AudioUnit Generate Wave",
            description: "Generate sin wave using AudioUnit.",
            prefix: "AudioUnitGenerateWave"
        ),
        MenuItem (
            title: "AVAudioEngene Generate Wave",
            description: "Generate sin wave using AVAudioEngene.",
            prefix: "AudioEngeneGenerateWave"
        )
    ]
    
    var count: Int {
        dataSource.count
    }
    
    func item(row: Int) -> MenuItem {
        dataSource[row]
    }
    
    func viewController(row: Int) -> UIViewController {
        dataSource[row].viewController()
    }
}
