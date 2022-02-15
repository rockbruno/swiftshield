public protocol SomeProtocol {
    func someFunc() -> Bool
}
class SomeImpl: SomeProtocol {
    func someFunc() -> Bool {
        return true
    }
}