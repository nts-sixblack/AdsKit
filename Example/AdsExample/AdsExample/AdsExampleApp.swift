//
//  AdsExampleApp.swift
//  AdsExample
//
//  Created by Sau Nguyen on 11/3/26.
//

import AdsKit
import SwiftUI

@main
struct AdsExampleApp: App {
  @StateObject private var adsManager = makeAdsManager()

  var body: some Scene {
    WindowGroup {
      ContentView(adsManager: adsManager)
        .onAppear {
          adsManager.startGoogleMobileAds()
          adsManager.preloadConfiguredSlots()
        }
    }
  }
}
