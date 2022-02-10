public protocol SomeProtocol {
    func someFunc() -> Bool
}
public class SomeImpl: SomeProtocol {
    public func someFunc() -> Bool {
        return true
    }
}
