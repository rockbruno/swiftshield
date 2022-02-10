import MyInternalLibrary

public struct MyLibrary {
    public private(set) var text: String

    public init() {
        let myInternalLibrary = MyInternalLibrary()
        text = myInternalLibrary.text
    }
}
