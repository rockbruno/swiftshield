import Foundation

struct Project: Hashable {
    let xcodeProjFile: File
    var pbxProj: File {
        File(path: "\(xcodeProjFile.path)/project.pbxproj")
    }

    func markAsSwiftShielded() throws -> String {
        var data = try pbxProj.read()
        let matches = data.match(regex: "buildSettings = \\{")
        for match in matches.reversed() {
            let value = match.captureGroup(0, originalString: data)
            let range = match.captureGroupRange(0, originalString: data)
            let newValue = value + "\n" + "SWIFTSHIELDED = true;"
            data = data.replacingCharacters(in: range, with: newValue)
        }
        return data
    }
}
