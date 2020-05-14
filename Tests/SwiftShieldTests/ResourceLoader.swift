import Foundation

func path(forResource resource: String) -> URL {
    let thisSourceFile = URL(fileURLWithPath: #file)
    let thisDirectory = thisSourceFile.deletingLastPathComponent().deletingLastPathComponent()
    return thisDirectory.appendingPathComponent("Resources").appendingPathComponent(resource)
}
