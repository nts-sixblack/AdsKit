//
//  ContentView.swift
//  AdsExample
//
//  Created by Sau Nguyen on 11/3/26.
//

import AdsKit
import SwiftInjected
import SwiftUI

struct ContentView: View {
  @InjectedObservable var adsManager: AdsKitManager

  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        List {
          Section("Inline Ads") {
            NavigationLink("Banner Ad") {
              BannerDemoView()
            }
            NavigationLink("Native Collapse Ad") {
              NativeCollapseDemoView()
            }
            NavigationLink("Native Ad Styles") {
              NativeDemoView()
            }
          }

          Section("Fullscreen Ads") {
            NavigationLink("Interstitial Ad") {
              InterstitialDemoView()
            }
            NavigationLink("Rewarded Ad") {
              RewardedDemoView()
            }
            NavigationLink("App Open Ad") {
              AppOpenDemoView()
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
