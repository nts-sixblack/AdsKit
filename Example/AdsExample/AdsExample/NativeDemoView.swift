//
//  NativeDemoView.swift
//  AdsExample
//

import AdsKit
import SwiftInjected
import SwiftUI

struct NativeDemoView: View {
  @InjectedObservable var adsManager: AdsKitManager

  private let styles: [(String, NativeAdViewStyle)] = [
    ("Large", .large()),
    ("Medium", .medium),
    ("Banner", .banner),
    ("Basic", .basic),
  ]

  var body: some View {
    ScrollView {
      VStack(spacing: 20) {
        ForEach(styles, id: \.0) { name, style in
          VStack(alignment: .leading, spacing: 8) {
            Text(name)
              .font(.headline)
              .padding(.horizontal, 16)

            NativeAdsView(
              slotKey: "demo_native",
              manager: adsManager,
              style: style
            )
            .padding(.horizontal, 16)
          }
        }
      }
      .padding(.vertical, 16)
    }
    .navigationTitle("Native Styles")
    .navigationBarTitleDisplayMode(.inline)
  }
}
