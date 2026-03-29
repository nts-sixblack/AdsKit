import Foundation
import UIKit

private final class AdsKitBundleFinder: NSObject {}

enum AdsKitImageAsset {
    static func image(named name: String, compatibleWith traitCollection: UITraitCollection? = nil) -> UIImage? {
        for bundle in candidateBundles {
            if let image = UIImage(named: name, in: bundle, compatibleWith: traitCollection) {
                return image
            }
        }

        return nil
    }

    private static let candidateBundles: [Bundle] = {
        var bundles: [Bundle] = []

        #if SWIFT_PACKAGE
        bundles.append(.module)
        #endif

        bundles.append(Bundle(for: AdsKitBundleFinder.self))
        bundles.append(Bundle.main)
        bundles.append(contentsOf: Bundle.allFrameworks)
        bundles.append(contentsOf: Bundle.allBundles)

        let resourceBundleNames = [
            "AdsKit_AdsKit",
            "AdsKit"
        ]

        for bundle in Array(bundles) {
            for resourceBundleName in resourceBundleNames {
                if let resourceBundleURL = bundle.url(forResource: resourceBundleName, withExtension: "bundle"),
                   let resourceBundle = Bundle(url: resourceBundleURL) {
                    bundles.append(resourceBundle)
                }
            }
        }

        var seenURLs = Set<URL>()
        return bundles.filter { bundle in
            let url = bundle.bundleURL.resolvingSymlinksInPath()
            return seenURLs.insert(url).inserted
        }
    }()
}
