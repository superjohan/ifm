//
//  CarPlaySceneDelegate.swift
//  IFM
//
//  Created by Johan Halin on 8.9.2024.
//

import CarPlay
import UIKit

class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
	var interfaceController: CPInterfaceController?
	
	func templateApplicationScene(
		_ templateApplicationScene: CPTemplateApplicationScene,
		didConnect interfaceController: CPInterfaceController
	) {
		let player = IFMPlayerHolder.ensurePlayer()
		let stationNames = player.stationNames

		self.interfaceController = interfaceController
		let listTemplate = CPListTemplate(title: "IFM", sections: [
			CPListSection(items: stationNames.map { stationName in
				let stationIndex = stationNames.firstIndex(of: stationName)!

				let item = CPListItem(text: stationName, detailText: nil)
				item.handler = { item, completion in
					if !player.state.isPlaying(channel: stationIndex) {
						player.play(channelIndex: stationIndex)
					}
					
					self.interfaceController?.pushTemplate(CPNowPlayingTemplate.shared, animated: true, completion: nil)

					completion()
				}
				item.accessoryType = .disclosureIndicator
				item.isPlaying = player.state.isPlaying(channel: stationIndex)

				return item
			})
		])
		interfaceController.setRootTemplate(listTemplate, animated: true, completion: nil)
	}

	func templateApplicationScene(
		_ templateApplicationScene: CPTemplateApplicationScene,
		didDisconnectInterfaceController interfaceController: CPInterfaceController
	) {
		self.interfaceController = nil
	}
}
