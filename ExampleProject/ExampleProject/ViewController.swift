import DifferentModule
import UIKit

func globalMethod() {}

struct SomeStruct {
    static func staticMethod() {}
    func method() {}
}

enum SomeEnum {
    case a
    case b
    case c
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
