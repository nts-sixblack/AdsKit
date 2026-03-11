//
//  ContentView.swift
//  AdsExample
//
//  Created by Sau Nguyen on 11/3/26.
//

import AdsKit
import SwiftUI

struct ContentView: View {
  @ObservedObject var adsManager: AdsKitManager

  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        List {
          Section("Inline Ads") {
            NavigationLink("Banner Ad") {
              BannerDemoView(adsManager: adsManager)
            }
            NavigationLink("Native Ad Styles") {
              NativeDemoView(adsManager: adsManager)
            }
          }

          Section("Fullscreen Ads") {
            NavigationLink("Interstitial Ad") {
              InterstitialDemoView(adsManager: adsManager)
            }
            NavigationLink("Rewarded Ad") {
              RewardedDemoView(adsManager: adsManager)
            }
            NavigationLink("App Open Ad") {
              AppOpenDemoView(adsManager: adsManager)
            }
          }
        }

        BannerAdsView(
          slotKey: "home_banner",
          manager: adsManager
        )
      }
      .navigationTitle("AdsKit Demo")
    }
  }
}
