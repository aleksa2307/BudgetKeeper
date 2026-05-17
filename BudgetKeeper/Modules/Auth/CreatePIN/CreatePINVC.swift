import UIKit

final class CreatePINViewController: UIViewController {

    private var createPINView: CreatePINView { view as! CreatePINView }
    private var enteredDigits: [String] = []

    override func loadView() { view = CreatePINView() }

    override func viewDidLoad() {
        super.viewDidLoad()
        createPINView.keypadView.onDigit = { [weak self] digit in self?.appendDigit(digit) }
        createPINView.keypadView.onDelete = { [weak self] in self?.deleteDigit() }
    }
}

private extension CreatePINViewController {
    func appendDigit(_ digit: String) {
        guard enteredDigits.count < 4 else { return }
        enteredDigits.append(digit)
        createPINView.updateDots(count: enteredDigits.count)
        if enteredDigits.count == 4 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
                self?.proceedToConfirm()
            }
        }
    }

    func deleteDigit() {
        guard !enteredDigits.isEmpty else { return }
        enteredDigits.removeLast()
        createPINView.updateDots(count: enteredDigits.count)
    }

    func proceedToConfirm() {
        let vc = ConfirmPINViewController(pin: enteredDigits.joined())
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true)
    }
}
