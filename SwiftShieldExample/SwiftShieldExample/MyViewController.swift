import UIKit
import Cartography
import Unbox

final class MyView: UILabel {}

class MyViewController: UIViewController {

// Properties disabled due to Codable issues.
//    let myLet = 1
//    var myProp = 1
//    class var myClassVar: Int {
//        return 10
//    }
//    static let myStaticLet = 1
//    static var myStaticVar = 1

    struct Foo {
        func barbar(view: MyView) -> MyViewController {
            print(view)
            return MyViewController(nibName: nil, bundle: nil)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
//        myProp = myLet * 10
//        MyViewController.myStaticVar = MyViewController.myClassVar + MyViewController.myStaticLet * 5
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
        _ = self + self
    }

    public static func +(lhs: MyViewController, rhs: MyViewController) -> MyViewController {
        return lhs
    }
}
