import UIKit

final class ConfirmPINViewController: UIViewController {

    private var confirmView: ConfirmPINView { view as! ConfirmPINView }
    private let originalPIN: String
    private var enteredDigits: [String] = []

    var onSuccess: (() -> Void)?

    init(pin: String) {
        self.originalPIN = pin
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func loadView() { view = ConfirmPINView() }

    override func viewDidLoad() {
        super.viewDidLoad()
        confirmView.keypadView.onDigit  = { [weak self] digit in self?.appendDigit(digit) }
        confirmView.keypadView.onDelete = { [weak self] in self?.deleteDigit() }

        if onSuccess != nil {
            confirmView.backButton.isHidden = false
            confirmView.backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        }
    }
}

private extension ConfirmPINViewController {
    func appendDigit(_ digit: String) {
        guard enteredDigits.count < 4 else { return }
        enteredDigits.append(digit)
        confirmView.updateDots(count: enteredDigits.count)
        if enteredDigits.count == 4 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
                self?.validatePIN()
            }
        }
    }

    func deleteDigit() {
        guard !enteredDigits.isEmpty else { return }
        enteredDigits.removeLast()
        confirmView.updateDots(count: enteredDigits.count)
    }

    func validatePIN() {
        if enteredDigits.joined() == originalPIN {
            DataStore.shared.pin = originalPIN
            if let onSuccess = onSuccess {
                onSuccess()
            } else {
                let tabBar = MainTabBarController()
                tabBar.modalPresentationStyle = .fullScreen
                present(tabBar, animated: true)
            }
        } else {
            enteredDigits = []
            confirmView.shakeAndReset()
        }
    }

    @objc func backTapped() {
        navigationController?.popViewController(animated: true)
    }
}
