//
//  RewardedDemoView.swift
//  AdsExample
//

import AdsKit
import GoogleMobileAds
import SwiftInjected
import SwiftUI

struct RewardedDemoView: View {
  @InjectedObservable var adsManager: AdsKitManager

  @State private var statusMessage = "Tap \"Load\" to load a rewarded ad."
  @State private var isLoaded = false
  @State private var rewardText: String?

  var body: some View {
    VStack(spacing: 24) {
      Spacer()

      Image(systemName: "gift.fill")
        .font(.system(size: 60))
        .foregroundStyle(.orange)

      Text("Rewarded Ad")
        .font(.title2.bold())

      Text(statusMessage)
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
        .padding(.horizontal, 32)

      if let rewardText {
        Label(rewardText, systemImage: "star.fill")
          .font(.headline)
          .foregroundStyle(.orange)
          .padding()
          .background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
      }

      HStack(spacing: 16) {
        Button {
          statusMessage = "Loading..."
          rewardText = nil
          adsManager.loadRewarded(slotKey: "demo_rewarded") {
            statusMessage = "Ready! Tap \"Show\" to earn a reward."
            isLoaded = true
          }
        } label: {
          Label("Load", systemImage: "arrow.down.circle")
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(.orange)

        Button {
          adsManager.showRewarded(
            slotKey: "demo_rewarded",
            onDismissed: {
              statusMessage = "Ad dismissed. Tap \"Load\" again."
              isLoaded = false
            },
            onReward: { reward in
              if let reward {
                rewardText = "Earned \(reward.amount) \(reward.type)"
              } else {
                rewardText = "No reward received"
              }
            }
          )
        } label: {
          Label("Show", systemImage: "play.circle")
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(.green)
        .disabled(!isLoaded)
      }
      .padding(.horizontal, 32)

      Spacer()
    }
    .navigationTitle("Rewarded")
    .navigationBarTitleDisplayMode(.inline)
  }
}
