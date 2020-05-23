import DifferentModule
import UIKit

func globalMethod() {}
var globalProp = 0

struct SomeStruct {
    static func staticMethod() {}
    func method() {}
    static let singleton = SomeStruct()
    var instanceProp = 0
}

enum SomeEnum {
    case a
    case b
    case c

    var bla: String {
        switch self {
        case .a:
            break
        case .b:
            break
        case .c:
            break
        }
        return ""
    }
}

class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .green
        StructFromDifferentModule.methodFromDifferentModule()
    }

    func method(_: SomeEnum) {
        globalMethod()
    }

    func anotherMethod() {
        method(SomeEnum.a)
        method(SomeEnum.b)
        method(SomeEnum.c)
        globalMethod()
    }
}
