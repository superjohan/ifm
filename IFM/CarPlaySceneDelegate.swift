//
//  CarPlaySceneDelegate.swift
//  IFM
//
//  Created by Johan Halin on 8.9.2024.
//

import CarPlay
import Combine
import UIKit

class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
	var interfaceController: CPInterfaceController?
	
	private let player = IFMPlayerHolder.ensurePlayer()
	private var cancellables = Set<AnyCancellable>()

	// MARK: - CPTemplateApplicationSceneDelegate
	
	func templateApplicationScene(
		_ templateApplicationScene: CPTemplateApplicationScene,
		didConnect interfaceController: CPInterfaceController
	) {
		self.interfaceController = interfaceController
		let listTemplate = CPListTemplate(title: "Intergalactic FM", sections: [stationList()])
		interfaceController.setRootTemplate(listTemplate, animated: true, completion: nil)
		
		self.player.stateObservable
			.sink { _ in listTemplate.updateSections([self.stationList()]) }
			.store(in: &self.cancellables)
	}

	func templateApplicationScene(
		_ templateApplicationScene: CPTemplateApplicationScene,
		didDisconnectInterfaceController interfaceController: CPInterfaceController
	) {
		self.interfaceController = nil
		
		for cancellable in self.cancellables {
			cancellable.cancel()
		}
		
		self.cancellables.removeAll()
	}
	
	// MARK: - Private
	
	private func stationList() -> CPListSection {
		let player = IFMPlayerHolder.ensurePlayer()
		let stationNames = player.stationNames

		return CPListSection(items: stationNames.map { stationName in
			let stationIndex = stationNames.firstIndex(of: stationName)!

			let item = CPListItem(text: stationName, detailText: nil)
			item.accessoryType = .disclosureIndicator
			item.isPlaying = player.state.isPlaying(channel: stationIndex)
			item.handler = { item, completion in
				if !player.state.isPlaying(channel: stationIndex) {
					player.play(channelIndex: stationIndex)
				}
				
				self.interfaceController?.pushTemplate(CPNowPlayingTemplate.shared, animated: true, completion: nil)

				completion()
			}

			return item
		})
	}
}
