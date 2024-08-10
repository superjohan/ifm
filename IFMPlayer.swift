//
//  IFMPlayer.swift
//  IFM
//
//  Created by Johan Halin on 28.1.2024.
//

import Foundation
import AVFoundation
import MediaPlayer
import Combine

@objc
class IFMPlayer : NSObject {
    private(set) var state: IFMPlayerState
    
    private let stations = IFMStations()
    private let nowPlayingUpdater = IFMNowPlaying()
    private let statePublisher = PassthroughSubject<IFMPlayerState, Never>()
    
    private var player: AVPlayer? = nil
    private var nowPlayingTimer: Timer? = nil
    private var nowPlayingText: String? = nil
    private var currentStation: IFMStation? = nil
    
    var stateObservable: AnyPublisher<IFMPlayerState, Never> {
        self.statePublisher.eraseToAnyPublisher()
    }
    
    override init() {
        self.state = .stopped
        self.stations.update()
        
        try? AVAudioSession.sharedInstance().setCategory(.playback)
        try? AVAudioSession.sharedInstance().setActive(true)
        
        super.init()
        
        registerRemoteControlEvents()
    }
    
    // MARK: - Public
    
    @objc func play(channelIndex: Int) {
        stop()
        
        guard let station = self.stations.station(for: channelIndex) else { return }
        
        let playerItem = AVPlayerItem(url: station.url)
        playerItem.preferredForwardBufferDuration = 1

        let player = AVPlayer(playerItem: playerItem)
        player.automaticallyWaitsToMinimizeStalling = true
        player.currentItem?.addObserver(self, forKeyPath: "status", options: [.old, .new], context: nil)
        player.currentItem?.addObserver(self, forKeyPath: "error", options: [.old, .new], context: nil)
        player.addObserver(self, forKeyPath: "status", options: [.old, .new], context: nil)
        player.addObserver(self, forKeyPath: "rate", options: [.old, .new], context: nil)
        player.addObserver(self, forKeyPath: "reasonForWaitingToPlay", options: [.old, .new], context: nil)
        player.play()
        
        self.player = player
        self.currentStation = station

        updateNowPlaying()
        updateState(.waiting(nowPlaying: self.nowPlayingText, stationIndex: self.stations.uiIndex(for: station)))
    }
    
    @objc func stop() {
        self.player?.currentItem?.removeObserver(self, forKeyPath: "status")
        self.player?.currentItem?.removeObserver(self, forKeyPath: "error")
        self.player?.removeObserver(self, forKeyPath: "status")
        self.player?.removeObserver(self, forKeyPath: "rate")
        self.player?.removeObserver(self, forKeyPath: "reasonForWaitingToPlay")
        self.player?.pause()
        
        self.player = nil
        
        self.nowPlayingTimer?.invalidate()
        self.nowPlayingTimer = nil
        self.nowPlayingText = nil
        
        updateState(.stopped)
    }
    
    // MARK: - Private
    
    // channelIndex is only used for .waiting and .playing, it can be anything for other states
    private func updateState(_ state: IFMPlayerState) {
        self.state = state
        
        self.statePublisher.send(state)
    }
    
    private func updateNowPlaying() {
        guard let currentStation = self.currentStation, !self.nowPlayingUpdater.updating else { return }
        
        self.nowPlayingUpdater.update(with: currentStation) { nowPlaying in
            // Was the player stopped while waiting for now playing info?
            if self.player == nil {
                return
            }
            
            self.nowPlayingText = nowPlaying
            
            self.updateState(self.state.copy(newNowPlaying: nowPlaying))
            
            MPNowPlayingInfoCenter.default().nowPlayingInfo = [
                MPMediaItemPropertyTitle: "Intergalactic FM - \(currentStation.name)",
                MPMediaItemPropertyArtist: nowPlaying ?? "",
                MPNowPlayingInfoPropertyIsLiveStream: true,
                MPMediaItemPropertyArtwork: MPMediaItemArtwork(
                    boundsSize: currentStation.artwork.size,
                    requestHandler: { _ in currentStation.artwork }
                ),
            ]
        }
    }
    
    private func registerRemoteControlEvents() {
        let commandCenter = MPRemoteCommandCenter.shared()

        commandCenter.playCommand.addTarget { _ in
            guard let currentStation = self.currentStation else { return .noActionableNowPlayingItem }

            self.play(channelIndex: self.stations.uiIndex(for: currentStation))
            
            return .success
        }
        
        commandCenter.pauseCommand.addTarget { _ in
            self.stop()

            return .success
        }
        
        commandCenter.togglePlayPauseCommand.addTarget { _ in
            if (self.player?.rate ?? 0) > 0.0001 {
                self.stop()
            } else if (self.player?.rate ?? 0) < 0.0001, let currentStation = self.currentStation {
                self.play(channelIndex: self.stations.uiIndex(for: currentStation))
            }
            
            return .success
        }
        
        commandCenter.nextTrackCommand.addTarget { _ in
            guard let currentStation = self.currentStation else { return .noActionableNowPlayingItem }
            var index = self.stations.uiIndex(for: currentStation)
            
            if index < (self.stations.numberOfStations - 1) {
                index += 1
            } else {
                index = 0
            }
            
            self.currentStation = self.stations.station(for: index)
            
            self.play(channelIndex: index)
            
            return .success
        }
        
        commandCenter.previousTrackCommand.addTarget { _ in
            guard let currentStation = self.currentStation else { return .noActionableNowPlayingItem }
            var index = self.stations.uiIndex(for: currentStation)
            
            if index == 0 {
                index = self.stations.numberOfStations - 1
            } else {
                index -= 1
            }
            
            self.currentStation = self.stations.station(for: index)
            
            self.play(channelIndex: index)
            
            return .success
        }
    }

    // MARK: - NSKeyValueObserving
    
    override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey : Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        if let player = object as? AVPlayer {
            if keyPath == "rate" {
                if player.rate < 0.00001 {
                    stop()
                }
            } else if keyPath == "reasonForWaitingToPlay" {
                if player.reasonForWaitingToPlay != nil, let station = self.currentStation {
                    updateState(.waiting(nowPlaying: self.nowPlayingText, stationIndex: self.stations.uiIndex(for: station)))
                } else if let station = self.currentStation {
                    self.nowPlayingTimer = Timer.scheduledTimer(
                        withTimeInterval: 15,
                        repeats: true,
                        block: { _ in self.updateNowPlaying() }
                    )
                    
                    updateNowPlaying()
                    updateState(.playing(nowPlaying: self.nowPlayingText, stationIndex: self.stations.uiIndex(for: station)))
                }
            } else if keyPath == "status" {
                if player.status == .failed {
                    stop()
                    updateState(.error)
                }
            }
        } else if let playerItem = object as? AVPlayerItem {
            if playerItem.status == .failed || keyPath == "error" {
                stop()
                updateState(.error)
            }
        } else {
            // Not interested.
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
}

enum IFMPlayerState: Equatable {
    case stopped
    case waiting(nowPlaying: String?, stationIndex: Int)
    case playing(nowPlaying: String?, stationIndex: Int)
    case error
    
    func isWaiting(channel: Int) -> Bool {
        if case .waiting(_, let stationIndex) = self {
            stationIndex == channel
        } else {
            false
        }
    }
    
    func isPlaying(channel: Int) -> Bool {
        if case .playing(_, let stationIndex) = self {
            stationIndex == channel
        } else {
            false
        }
    }

    var nowPlayingText: String? {
        switch self {
        case .playing(let nowPlaying, _), .waiting(let nowPlaying, _):
            nowPlaying
        default:
            nil
        }
    }
    
    func copy(newNowPlaying: String?) -> IFMPlayerState {
        switch self {
        case .waiting(_, let stationIndex):
            .waiting(nowPlaying: newNowPlaying, stationIndex: stationIndex)
        case .playing(_, let stationIndex):
            .playing(nowPlaying: newNowPlaying, stationIndex: stationIndex)
        default:
            self
        }
    }
}
