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
    var levelTimerArg = Timer()
    var peakValue: Float = 0
    var argValue: Float = 0
    var maxValue: Float = 0
    
    
    let LEVEL_THREHOLD: Float = 95.0
    let correction: Float = 100.0
    
    var modeArray = ["noiseAlarm","volummUp","protectEar"]
    var modeIndex: Int = 0
    
    @IBOutlet weak var dbValueLabel: UILabel!
    @IBOutlet weak var dbMaxValue: UILabel!
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
        let path = Bundle.main.path(forResource: "signal-alert3", ofType: "mp3")!
        let url = URL(fileURLWithPath: path)
        
        do {
            alarmSound = try AVAudioPlayer(contentsOf: url)
            alarmSound?.play()
        } catch {
            // couldn't load file :(
        }
    }
    func stopSound(){
        alarmSound?.stop()
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
            
        levelTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(levelTimerCallback), userInfo: nil, repeats: true)
        levelTimerArg = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(levelTimerCallbackArg), userInfo: nil, repeats: true)
    }
    
    @objc func levelTimerCallback(){
        
        noiseRecorder.updateMeters()
 
        peakValue = noiseRecorder.peakPower(forChannel: 0) + correction
        if peakValue > maxValue {
            maxValue = peakValue
        }
        
        dbValueLabel.text = String(Int(peakValue))
        dbMaxValue.text = String(Int(maxValue))
    }
    
    @objc func levelTimerCallbackArg(){
        noiseRecorder.updateMeters()
 
        let averageNoise = noiseRecorder.averagePower(forChannel: 0) + correction

        let isLoud = averageNoise > LEVEL_THREHOLD
        if isLoud {
            playSound()
        }

        dbAverageValue.text = String(Int(averageNoise))

    }
        
    func getDocumentsDirectory()->URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated
    }
    
}

