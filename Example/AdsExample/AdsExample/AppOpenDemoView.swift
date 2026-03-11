//
//  AppOpenDemoView.swift
//  AdsExample
//

import AdsKit
import SwiftInjected
import SwiftUI

struct AppOpenDemoView: View {
  @InjectedObservable var adsManager: AdsKitManager

  @State private var statusMessage = "Tap \"Load\" to load an app open ad."
  @State private var isLoaded = false

  var body: some View {
    VStack(spacing: 24) {
      Spacer()

      Image(systemName: "app.badge.fill")
        .font(.system(size: 60))
        .foregroundStyle(.blue)

      Text("App Open Ad")
        .font(.title2.bold())

      Text(statusMessage)
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
        .padding(.horizontal, 32)

      HStack(spacing: 16) {
        Button {
          statusMessage = "Loading..."
          adsManager.loadAppOpen(slotKey: "demo_app_open") {
            statusMessage = "Ready! Tap \"Show\" to present."
            isLoaded = true
          }
        } label: {
          Label("Load", systemImage: "arrow.down.circle")
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)

        Button {
          adsManager.showAppOpen(
            slotKey: "demo_app_open",
            onDismissed: {
              statusMessage = "Ad dismissed. Tap \"Load\" again."
              isLoaded = false
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
    .navigationTitle("App Open")
    .navigationBarTitleDisplayMode(.inline)
  }
}
