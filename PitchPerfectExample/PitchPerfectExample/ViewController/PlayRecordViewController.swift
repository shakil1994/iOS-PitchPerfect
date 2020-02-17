

import UIKit
import AVFoundation

class RecordViewController: UIViewController {
    
    @IBOutlet weak var slowButton: UIButton!
    @IBOutlet weak var fastButton: UIButton!
    @IBOutlet weak var highPitchButton: UIButton!
    @IBOutlet weak var lowPitchButton: UIButton!
    @IBOutlet weak var echoButton: UIButton!
    @IBOutlet weak var reverbButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    
    
    var audioURL: URL!
    var audioFile: AVAudioFile!
    var audioEngine: AVAudioEngine!
    var audioPlayerNode: AVAudioPlayerNode!
    var stopTimer: Timer!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupAudio()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureUI(.notPlaying)
    }
    
    private func configureUI(_ playState: PlayerState) {
        switch playState {
        case .playing:
            enableAudioNodeButton(false)
            stopButton.isEnabled = true
        case .notPlaying:
            enableAudioNodeButton(true)
            stopButton.isEnabled = false
        }
    }
    
    private func enableAudioNodeButton(_ enabled: Bool){
        fastButton.isEnabled = enabled
        slowButton.isEnabled = enabled
        highPitchButton.isEnabled = enabled
        lowPitchButton.isEnabled = enabled
        echoButton.isEnabled = enabled
        reverbButton.isEnabled = enabled
    }
    
    private func setupAudio(){
        do {
            self.audioFile = try AVAudioFile(forReading: audioURL)
        }
        catch{
            showAlert()
        }
    }
    
    private func showAlert(){
        let alert = UIAlertController(title: "Recording Failed", message: "Something went wrong with yourrecording file", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func playRecord(_ sender: UIButton) {
        switch (ButtonType(rawValue: sender.tag)!) {
        case .slow:
            playAudio(rate: 0.5)
        case .fast:
            playAudio(rate: 1.5)
            
            case .highPitch:
            playAudio(pitch: 1000)
            
            case .lowPitch:
            playAudio(pitch: -1000)
            
            case .echo:
            playAudio(echo: true)
            
            case .reverb:
                playAudio(reverb: true)
        }
        configureUI(.playing)
    }
    
    private func playAudio(rate: Float? = nil, pitch: Float? = nil, echo: Bool = false, reverb: Bool = false){
        audioEngine = AVAudioEngine()
        audioPlayerNode = AVAudioPlayerNode()
        audioEngine.attach(audioPlayerNode)
        
        let changeRatePitchNode = AVAudioUnitTimePitch()
        if let pitch = pitch {
            changeRatePitchNode.pitch = pitch
        }
        if let rate = rate {
            changeRatePitchNode.rate = rate
        }
        audioEngine.attach(changeRatePitchNode)
        
        let echoNode = AVAudioUnitDistortion()
        echoNode.loadFactoryPreset(.multiEcho1)
        audioEngine.attach(echoNode)
        
        let reverbNode = AVAudioUnitReverb()
        reverbNode.loadFactoryPreset(.cathedral)
        reverbNode.wetDryMix = 50
        audioEngine.attach(reverbNode)
        
        if echo == true && reverb == true {
            connectAudioNodes(audioPlayerNode, changeRatePitchNode, echoNode, reverbNode, audioEngine.outputNode)
        }
        else if echo == true {
            connectAudioNodes(audioPlayerNode, changeRatePitchNode, echoNode, audioEngine.outputNode)
        }
        else if reverb == true {
            connectAudioNodes(audioPlayerNode, changeRatePitchNode, reverbNode, audioEngine.outputNode)
        }
        else {
            connectAudioNodes(audioPlayerNode, changeRatePitchNode, audioEngine.outputNode)
        }
        
        audioPlayerNode.stop()
        audioPlayerNode.scheduleFile(audioFile, at: nil){
            var delayInSeconds: Double = 0
            if let lastRenderTime = self.audioPlayerNode.lastRenderTime, let playerTime = self.audioPlayerNode.playerTime(forNodeTime: lastRenderTime) {
                if let rate = rate {
                    delayInSeconds = Double(self.audioFile.length - playerTime.sampleTime) / Double(self.audioFile.processingFormat.sampleRate) / Double(rate)
                }
                else {

                    delayInSeconds = Double(self.audioFile.length - playerTime.sampleTime) / Double(self.audioFile.processingFormat.sampleRate)
                    
                }
            }
            self.stopTimer = Timer(timeInterval: delayInSeconds, target: self, selector: #selector(RecordViewController.stopAudio), userInfo: nil, repeats: false)
            RunLoop.main.add(self.stopTimer, forMode: .default)
        }
        
        do{
            try audioEngine.start()
        }
        catch{
            showAlert()
            return
        }
        audioPlayerNode.play()
    }
    
    private func connectAudioNodes(_ nodes: AVAudioNode...){
        for X in 0..<nodes.count - 1 {
            audioEngine.connect(nodes[X], to: nodes[X+1], format: audioFile.processingFormat)
        }
    }
    
    @IBAction func stopRecordButton(_ sender: UIButton) {
        stopAudio()
    }
    
    @objc private func stopAudio(){
        if let audioPlayerNode = audioPlayerNode {
            audioPlayerNode.stop()
        }
        if let stopTimer = stopTimer {
            stopTimer.invalidate()
        }
        configureUI(.notPlaying)
        if let audioEngine = audioEngine {
            audioEngine.stop()
            audioEngine.reset()
        }
    }
    
}
