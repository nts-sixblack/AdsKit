import Foundation

enum AdsPlacementResolver {
    static func preferredPlacement(for slot: AdsSlot) -> AdsPlacement? {
        if slot.primaryPlacement.isEnabled {
            return slot.primaryPlacement
        }
        if let fallbackPlacement = slot.fallbackPlacement, fallbackPlacement.isEnabled {
            return fallbackPlacement
        }
        return nil
    }

    static func loadOrder(for slot: AdsSlot) -> [AdsPlacement] {
        var placements: [AdsPlacement] = []
        if slot.primaryPlacement.isEnabled {
            placements.append(slot.primaryPlacement)
        }
        if let fallbackPlacement = slot.fallbackPlacement,
           fallbackPlacement.isEnabled,
           fallbackPlacement.id != slot.primaryPlacement.id {
            placements.append(fallbackPlacement)
        }
        return placements
    }
}
