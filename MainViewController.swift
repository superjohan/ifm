//
//  MainViewController.swift
//  IFM
//
//  Created by Johan Halin on 28.1.2024.
//

import Foundation

class MainViewController : UIViewController, IFMPlayerStatusListener {
    @IBOutlet var channel1Button: UIButton!
    @IBOutlet var channel2Button: UIButton!
    @IBOutlet var channel3Button: UIButton!
    @IBOutlet var channel1StopButton: UIButton!
    @IBOutlet var channel2StopButton: UIButton!
    @IBOutlet var channel3StopButton: UIButton!
    @IBOutlet var channel1Spinner: UIActivityIndicatorView!
    @IBOutlet var channel2Spinner: UIActivityIndicatorView!
    @IBOutlet var channel3Spinner: UIActivityIndicatorView!
    @IBOutlet var infoButton: UIButton!

    private let nowPlayingLabel = UILabel(frame: .zero)
    private let player: IFMPlayer
    private var playButtons = [UIButton]()
    private var stopButtons = [UIButton]()
    private var spinners = [UIActivityIndicatorView]()
    
    private let channelsMax = 3
    
    // MARK: - Public
    
    @objc init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?, player: IFMPlayer) {
        self.player = player
        
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("not supported")
    }
    
    @objc func resetAnimation() {
        self.nowPlayingLabel.sizeToFit()
        self.nowPlayingLabel.frame = CGRect(
            x: self.view.frame.size.width,
            y: self.nowPlayingLabel.frame.origin.y,
            width: self.nowPlayingLabel.bounds.size.width,
            height: self.nowPlayingLabel.bounds.size.height
        )
        
        UIView.animate(
            withDuration: ((640.0 + self.nowPlayingLabel.frame.size.width) / 60.0),
            delay: 0,
            options: [.repeat, .curveLinear],
            animations: { self.nowPlayingLabel.frame.origin.x = -self.nowPlayingLabel.frame.size.width }
        )
    }
    
    // MARK: - IBActions
    
    @IBAction func showInfo() {
        UIApplication.shared.open(URL(string: "https://www.intergalactic.fm")!)
    }
    
    @IBAction func channel1ButtonPressed() {
        self.player.play(channelIndex: 0)
    }
    
    @IBAction func channel2ButtonPressed() {
        self.player.play(channelIndex: 1)
    }
    
    @IBAction func channel3ButtonPressed() {
        self.player.play(channelIndex: 2)
    }
    
    @IBAction func stopButtonPressed() {
        self.player.stop()
    }
    
    // MARK: - IFMPlayerStatusListener
    
    func update(state: IFMPlayerState) {
        if state == .error {
            let alert = UIAlertController(
                title: "Unable to load playlist",
                message: "The internet connection may be down, or the servers aren't responding.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Dismiss", style: .default))
            present(alert, animated: true)
        }
        
        for channel in 0..<self.channelsMax {
            let isWaiting = state.isWaiting(channel: channel)
            let isPlaying = state.isPlaying(channel: channel)
            
            self.spinners[channel].isHidden = !isWaiting
            self.playButtons[channel].isEnabled = !isWaiting
            self.stopButtons[channel].isEnabled = isPlaying || isWaiting
            self.stopButtons[channel].isHidden = !isPlaying && !isWaiting
        }
        
        if state.nowPlayingText != self.nowPlayingLabel.text {
            self.nowPlayingLabel.text = state.nowPlayingText

            resetAnimation()
        }
    }
    
    // MARK: - UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.player.addListener(self)
        
        self.playButtons.append(self.channel1Button)
        self.playButtons.append(self.channel2Button)
        self.playButtons.append(self.channel3Button)
        self.stopButtons.append(self.channel1StopButton)
        self.stopButtons.append(self.channel2StopButton)
        self.stopButtons.append(self.channel3StopButton)
        self.spinners.append(self.channel1Spinner)
        self.spinners.append(self.channel2Spinner)
        self.spinners.append(self.channel3Spinner)
        
        let state = self.player.state
        update(state: state)
        
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] ?? "- now with exciting bugs"
        let introText = "Intergalactic FM for iPhone \(version) - https://www.intergalactic.fm/ - Developed by Aero Deko and IFM dev corps"
        
        self.nowPlayingLabel.text = introText
        self.nowPlayingLabel.font = UIFont(name: "Michroma", size: 20)
        self.nowPlayingLabel.backgroundColor = .clear
        self.nowPlayingLabel.textColor = .red
        self.nowPlayingLabel.sizeToFit()
        
        let height = CGRectGetMinY(self.infoButton.frame) - CGRectGetMaxY(self.channel3Button.frame)
        let y = CGRectGetMaxY(self.channel3Button.frame) + (height / 2.0) - (CGRectGetHeight(self.nowPlayingLabel.bounds) / 2.0)
        let yOffset = 6.0
        self.nowPlayingLabel.frame = CGRect(
            x: 0,
            y: y + yOffset,
            width: CGRectGetWidth(self.view.bounds),
            height: CGRectGetHeight(self.nowPlayingLabel.bounds)
        )
        self.view.addSubview(self.nowPlayingLabel)

        resetAnimation()
        
        // If the player is already doing something, then update the UI state again with the status so the now playing label is correct
        switch state {
        case .playing, .waiting:
            update(state: state)
        default:
            break
        }
    }
}
