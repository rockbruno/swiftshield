import UIKit
import Cartography
import Unbox

final class MyView: UILabel {}

class ViewController: UIViewController {
    struct Foo {
        func barbar(view: MyView) -> ViewController {
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
        view.textAlignment = .center
        view.numberOfLines = 0
        self.view.addSubview(view)
        view.backgroundColor = .green
        constrain(view, self.view) { view, superview in
            view.edges == inset(superview.edges, 16)
        }
        let dict: [String: Any] = ["text": "ViewController name: " + String(describing: type(of: self))]
        let box = Unboxer(dictionary: dict)
        let text: String = try! box.unbox(key: "text")
        view.text = text
    }
}
