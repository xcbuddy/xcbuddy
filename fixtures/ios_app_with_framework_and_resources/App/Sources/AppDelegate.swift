import Framework1
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func applicationDidFinishLaunching(_: UIApplication) {
        let framework1 = Framework1File()

        print(hello())
        print("AppDelegate -> \(framework1.hello())")
        print("Image: \(UIImage(named: "tuist"))")
    }

    func hello() -> String {
        return "AppDelegate.hello()"
    }
}
