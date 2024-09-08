//
//  IFMSceneDelegate.swift
//  IFM
//
//  Created by Johan Halin on 5.9.2024.
//

import UIKit

class IFMWindowSceneDelegate: UIResponder, UIWindowSceneDelegate {
	var window: UIWindow?

	private var mainViewController: MainViewController?
	
	func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
		guard let scene = scene as? UIWindowScene else { return }

		let window = UIWindow(windowScene: scene)
		
		self.window = window
		self.mainViewController = MainViewController(nibName: "MainView", bundle: nil, player: IFMPlayerHolder.ensurePlayer())
		self.window?.rootViewController = self.mainViewController
		self.window?.makeKeyAndVisible()
	}
	
	func sceneWillEnterForeground(_ scene: UIScene) {
		self.mainViewController?.resetAnimation()
	}
}
