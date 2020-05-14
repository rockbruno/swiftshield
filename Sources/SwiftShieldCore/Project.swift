import Foundation

struct Project: Hashable {
    let xcodeProjFile: File
    var pbxProj: File {
        File(path: "\(xcodeProjFile.path)/project.pbxproj")
    }

    func markAsSwiftShielded() throws -> String {
        var data = try pbxProj.read()
        let matches = data.match(regex: "PRODUCT_NAME = \".*\";")
        for match in matches.reversed() {
            let value = match.captureGroup(0, originalString: data)
            let range = match.captureGroupRange(0, originalString: data)
            let newValue = value + "SWIFTSHIELDED = true;"
            data = data.replacingCharacters(in: range, with: newValue)
        }
        return data
    }
}
