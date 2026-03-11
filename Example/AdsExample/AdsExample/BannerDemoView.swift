//
//  BannerDemoView.swift
//  AdsExample
//

import AdsKit
import SwiftInjected
import SwiftUI

struct BannerDemoView: View {
  @InjectedObservable var adsManager: AdsKitManager

  var body: some View {
    VStack(spacing: 24) {
      Spacer()

      Image(systemName: "rectangle.bottomhalf.inset.filled")
        .font(.system(size: 60))
        .foregroundStyle(.secondary)

      Text("Banner Ad")
        .font(.title2.bold())

      Text("The banner ad is displayed below using the `BannerAdsView` component.")
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
        .padding(.horizontal, 32)

      Spacer()

      BannerAdsView(
        slotKey: "home_banner",
        manager: adsManager
      )
    }
    .navigationTitle("Banner")
    .navigationBarTitleDisplayMode(.inline)
  }
}
