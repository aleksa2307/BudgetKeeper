import UIKit
import SnapKit

final class OnboardingViewController: UIViewController {
    
    private var onboardingView: OnboardingView {
        return view as! OnboardingView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func loadView() {
        view = OnboardingView()
    }
}

private extension OnboardingViewController {
    
}
