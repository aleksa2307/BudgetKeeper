import UIKit

final class OnboardingViewController: UIViewController {

    private var onboardingView: OnboardingView { view as! OnboardingView }
    private var currentPage = 0
    private let totalPages = 3

    override func loadView() {
        view = OnboardingView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        onboardingView.update(page: 0, animated: false)
        onboardingView.nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
    }
}

private extension OnboardingViewController {
    @objc func nextTapped() {
        if currentPage < totalPages - 1 {
            currentPage += 1
            onboardingView.update(page: currentPage, animated: true)
        } else {
            let vc = CreatePINViewController()
            vc.modalPresentationStyle = .fullScreen
            present(vc, animated: true)
        }
    }
}
