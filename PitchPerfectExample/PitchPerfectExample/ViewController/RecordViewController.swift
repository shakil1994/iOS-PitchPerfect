import UIKit
import AVFoundation

class ViewController: UIViewController, AVAudioRecorderDelegate {
    
    @IBOutlet weak var playBtn: UIButton!
    @IBOutlet weak var txtLabel: UILabel!
    @IBOutlet weak var stopBtn: UIButton!

    var avRecorder: AVAudioRecorder!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        stopBtn.isEnabled = false
    }

    @IBAction func playButton(_ sender: Any) {
        txtLabel.text = "Recording in progress"
        configUI(false)
        
        let dirPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
        let recordName = "abc.wav"
        let pathArray = [dirPath, recordName]
        let filePath = URL(string: pathArray.joined(separator: "/"))
        
        let session = AVAudioSession.sharedInstance()
        try! session.setCategory(AVAudioSession.Category.playAndRecord, options: AVAudioSession.CategoryOptions.defaultToSpeaker)

        try! avRecorder = AVAudioRecorder(url: filePath!, settings: [:])
        avRecorder.delegate = self
        avRecorder.isMeteringEnabled = true
        avRecorder.prepareToRecord()
        avRecorder.record()
    }
    
    @IBAction func stopButton(_ sender: Any) {
        
        self.txtLabel.text = "Tap to start"
        configUI(true)
        avRecorder.stop()
        let audioSession = AVAudioSession.sharedInstance()
        try! audioSession.setActive(false)
    }
    
    private func configUI(_ enabled: Bool){
        self.playBtn.isEnabled = enabled
        self.stopBtn.isEnabled = !enabled
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag {
            performSegue(withIdentifier: "playAudio", sender: avRecorder.url)
        }
        else{
            print("Recording was not successfull")
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "playAudio" {
            let playVC = segue.destination as! RecordViewController
            playVC.audioURL = sender as? URL
        }
    }
}

