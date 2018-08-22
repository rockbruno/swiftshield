import UIKit
import Cartography
import Unbox

final class MyView: UILabel {}

class ViewController: UIViewController {
    struct Foo {
        func bar(view: MyView) -> ViewController {
            print(view)
            return ViewController(nibName: nil, bundle: nil)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        render()
    }

    func render() {
        let view = MyView()
        view.backgroundColor = .red
        constrain(view, self.view) { view, superview in
            view.edges == superview.edges
        }
        let dict: [String: Any] = ["text": String(describing: type(of: self))]
        let box = Unboxer(dictionary: dict)
        let text: String = try! box.unbox(key: "text")
        view.text = text
    }
}
