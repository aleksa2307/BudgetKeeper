import UIKit

final class PINUnlockViewController: UIViewController {

    private var pinView: ConfirmPINView { view as! ConfirmPINView }
    private var enteredDigits: [String] = []

    override func loadView() { view = ConfirmPINView() }

    override func viewDidLoad() {
        super.viewDidLoad()
        pinView.titleLabel.text = "Введіть PIN-код"
        pinView.subtitleLabel.text = "Ваш PIN для входу в BudgetKeeper"
        pinView.keypadView.onDigit  = { [weak self] d in self?.appendDigit(d) }
        pinView.keypadView.onDelete = { [weak self] in self?.deleteDigit() }
    }
}

private extension PINUnlockViewController {
    func appendDigit(_ digit: String) {
        guard enteredDigits.count < 4 else { return }
        enteredDigits.append(digit)
        pinView.updateDots(count: enteredDigits.count)
        if enteredDigits.count == 4 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
                self?.validate()
            }
        }
    }

    func deleteDigit() {
        guard !enteredDigits.isEmpty else { return }
        enteredDigits.removeLast()
        pinView.updateDots(count: enteredDigits.count)
    }

    func validate() {
        if enteredDigits.joined() == DataStore.shared.pin {
            let tabBar = MainTabBarController()
            tabBar.modalPresentationStyle = .fullScreen
            present(tabBar, animated: true)
        } else {
            enteredDigits = []
            pinView.shakeAndReset()
        }
    }
}
