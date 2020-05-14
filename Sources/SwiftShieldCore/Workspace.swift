import Foundation

struct Workspace: Hashable {
    let workspaceFile: File

    func xcodeProjFiles() throws -> [Project] {
        let workspaceRoot = URL(fileURLWithPath: workspaceFile.path).deletingLastPathComponent().relativePath
        let contentFile = File(path: workspaceFile.path + "/contents.xcworkspacedata")
        let content = try contentFile.read()
        let results = content.match(regex: "group:(.*\\.xcodeproj)")
        var projects = [Project]()
        for result in results {
            let path = result.captureGroup(1, originalString: content)
            let project = Project(xcodeProjFile: File(path: workspaceRoot + "/" + path))
            projects.append(project)
        }
        return projects
    }
}
