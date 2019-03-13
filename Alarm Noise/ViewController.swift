//
//  ViewController.swift
//  Alarm Noise
//
//  Created by Admin on 1/13/19.
//  Copyright © 2019 Khoi Nguyen. All rights reserved.
//

import UIKit
import AVFoundation
import Foundation

class ViewController: UIViewController, AVAudioPlayerDelegate, AVAudioRecorderDelegate {

    var alarmSound: AVAudioPlayer!
    //var noiseRecordingSession: AVAudioSession!
    var noiseRecorder: AVAudioRecorder!
    var levelTimer = Timer()
    
    let LEVEL_THREHOLD: Float = 90.0
    
    var modeArray = ["noiseAlarm","volummUp","protectEar"]
    var modeIndex: Int = 0
    
    @IBOutlet weak var dbValueLabel: UILabel!
    
    @IBOutlet weak var dbAverageValue: UILabel!
    
    @IBOutlet weak var noiseAlarmModeBtn: UIButton!
    @IBOutlet weak var volummUpBtn: UIButton!
    @IBOutlet weak var protectEarBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        noiseAlarmModeBtn.isSelected = true
        volummUpBtn.isSelected = false
        protectEarBtn.isSelected = false
        modeIndex = 0
    }

    
    @IBAction func toggleNoiseAlarmMode(_ sender: Any) {
        if !noiseAlarmModeBtn.isSelected {
            noiseAlarmModeBtn.isSelected = true
            volummUpBtn.isSelected = false
            protectEarBtn.isSelected = false
            modeIndex = 0
        }
    }
    
    @IBAction func toggleVolummUpMode(_ sender: Any) {
        if !volummUpBtn.isSelected {
            noiseAlarmModeBtn.isSelected = false
            volummUpBtn.isSelected = true
            protectEarBtn.isSelected = false
            modeIndex = 1
        }
    }
    
    @IBAction func toggleProtectEarMode(_ sender: Any) {
        if !protectEarBtn.isSelected {
            noiseAlarmModeBtn.isSelected = false
            volummUpBtn.isSelected = false
            protectEarBtn.isSelected = true
            modeIndex = 2
        }
    }
    
    @IBAction func measureNoise(_ sender: UIButton) {
        startRecordingNoise()
    }
    
    
    func playSound(){
        let path = Bundle.main.path(forResource: "tone_22", ofType: "wav")!
        let url = URL(fileURLWithPath: path)
        
        do {
            alarmSound = try AVAudioPlayer(contentsOf: url)
            alarmSound?.play()
        } catch {
            // couldn't load file :(
        }
    }
    func startRecordingNoise(){
        let audioFilename = getDocumentsDirectory().appendingPathComponent("noise.caf")
        let recordSettings : [String: Any] = [
            AVFormatIDKey: kAudioFormatAppleIMA4,
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 2,
            AVEncoderBitRateKey: 12800,
            AVLinearPCMBitDepthKey: 16,
            AVEncoderAudioQualityKey: AVAudioQuality.max.rawValue
        ]
            
        let noiseRecordingSession = AVAudioSession.sharedInstance()
        do {
            try noiseRecordingSession.setCategory(.playAndRecord, mode: .default)
            try noiseRecordingSession.setActive(true)
            try noiseRecorder = AVAudioRecorder(url: audioFilename, settings: recordSettings)
        } catch {
            return
        }
            
        noiseRecorder.prepareToRecord()
        noiseRecorder.isMeteringEnabled = true
        noiseRecorder.record()
            
        levelTimer = Timer.scheduledTimer(timeInterval: 0.3, target: self, selector: #selector(levelTimerCallback), userInfo: nil, repeats: true)
    }
    
    @objc func levelTimerCallback(){
        noiseRecorder.updateMeters()
        
        // NOTE: seems to be the approx correction to get real decibels
        let correction: Float = 100
        let averageNoise = noiseRecorder.averagePower(forChannel: 0) + correction
        let peakNoise = noiseRecorder.peakPower(forChannel: 0) + correction
        
        //let levelNoise = noiseRecorder.averagePower(forChannel: 0)
        //let dbValue = dBFS_convertTo_dB(dBFSValue: levelNoise)
        let isLoud = averageNoise > LEVEL_THREHOLD
        if isLoud {
            playSound()
        }
        dbValueLabel.text = String(Int(peakNoise))
        dbAverageValue.text = String(Int(averageNoise))
        //print(averageNoise)
    }
        
    func getDocumentsDirectory()->URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated
    }

    func dBFS_convertTo_dB (dBFSValue: Float)->Float {
        var level: Float = 0.0
        let peak_bottom: Float = -60.0 //dBFS -> -160.0..0 so it can be -80 or -60
        if dBFSValue < peak_bottom {
            level = 0.0
        } else if dBFSValue >= 0.0 {
            level = 1.0
        } else {
            let root: Float = 2.0
            let minAmp: Float = powf(10.0, 0.05 * peak_bottom)
            let inverseAmpRange: Float = 1.0 / (1.0 - minAmp)
            let amp: Float = powf(10.0, 0.05 * dBFSValue)
            let adjAmp: Float = (amp - minAmp) * inverseAmpRange
            
            level = powf(adjAmp, 1.0/root)
            
        }
        return level
    }
    
}

