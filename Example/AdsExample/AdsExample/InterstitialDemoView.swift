//
//  InterstitialDemoView.swift
//  AdsExample
//

import AdsKit
import SwiftUI

struct InterstitialDemoView: View {
  @ObservedObject var adsManager: AdsKitManager

  @State private var statusMessage = "Tap \"Load\" to load an interstitial ad."
  @State private var isLoaded = false

  var body: some View {
    VStack(spacing: 24) {
      Spacer()

      Image(systemName: "rectangle.inset.filled.and.person.filled")
        .font(.system(size: 60))
        .foregroundStyle(.secondary)

      Text("Interstitial Ad")
        .font(.title2.bold())

      Text(statusMessage)
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
        .padding(.horizontal, 32)

      HStack(spacing: 16) {
        Button {
          statusMessage = "Loading..."
          adsManager.loadInterstitial(slotKey: "demo_inter") {
            statusMessage = "Loaded! Tap \"Show\" to present."
            isLoaded = true
          }
        } label: {
          Label("Load", systemImage: "arrow.down.circle")
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)

        Button {
          adsManager.showInterstitial(
            slotKey: "demo_inter",
            onDismissed: {
              statusMessage = "Ad dismissed. Tap \"Load\" again."
              isLoaded = false
            },
            onFailed: { error in
              statusMessage = "Failed: \(error.localizedDescription)"
              isLoaded = false
            },
            onShown: {
              statusMessage = "Showing ad..."
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
    .navigationTitle("Interstitial")
    .navigationBarTitleDisplayMode(.inline)
  }
}
