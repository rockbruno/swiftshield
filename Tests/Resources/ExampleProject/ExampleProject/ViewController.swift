import AnotherTarget
import UIKit

class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        let anotherClass = AnotherClass()
        anotherClass.anotherMethod()
    }
}
