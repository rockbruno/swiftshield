import Foundation
import UIKit

@UIApplicationMain
final class AppDelegate: NSObject, UIApplicationDelegate {}

protocol CodableProtocolInAnotherFile: Codable {}

enum CodableEnumeration: String, Codable {
    case case1
    case case2
    case case3
}
