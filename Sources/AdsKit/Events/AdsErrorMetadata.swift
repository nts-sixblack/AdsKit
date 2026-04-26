import Foundation
@preconcurrency import GoogleMobileAds

enum AdsErrorMetadata {
    static func make(
        from error: Error,
        responseInfo explicitResponseInfo: ResponseInfo? = nil
    ) -> [String: String] {
        let nsError = error as NSError
        var metadata: [String: String] = [
            "error_domain": nsError.domain,
            "error_code": "\(nsError.code)"
        ]

        if let underlyingError = nsError.userInfo[NSUnderlyingErrorKey] as? NSError {
            metadata["underlying_error_domain"] = underlyingError.domain
            metadata["underlying_error_code"] = "\(underlyingError.code)"
            metadata["underlying_error_message"] = underlyingError.localizedDescription
        }

        let responseInfo = explicitResponseInfo
            ?? nsError.userInfo[GADErrorUserInfoKeyResponseInfo] as? ResponseInfo
        if let responseInfo {
            metadata["response_identifier"] = responseInfo.responseIdentifier ?? ""
            metadata["adapter_response_count"] = "\(responseInfo.adNetworkInfoArray.count)"

            if let loadedAdapter = responseInfo.loadedAdNetworkResponseInfo {
                metadata["loaded_adapter_name"] = loadedAdapter.adNetworkClassName
                metadata["loaded_ad_source_name"] = loadedAdapter.adSourceName ?? ""
            } else if let firstAdapter = responseInfo.adNetworkInfoArray.first {
                metadata["first_adapter_name"] = firstAdapter.adNetworkClassName
                if let adapterError = firstAdapter.error {
                    let nsAdapterError = adapterError as NSError
                    metadata["first_adapter_error_domain"] = nsAdapterError.domain
                    metadata["first_adapter_error_code"] = "\(nsAdapterError.code)"
                    metadata["first_adapter_error_message"] = nsAdapterError.localizedDescription
                }
            }
        }

        return metadata
    }
}
