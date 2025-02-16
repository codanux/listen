import Foundation

@objc public class Listen: NSObject {
    @objc public func echo(_ value: String) -> String {
        print(value)
        return value
    }
}
