import UIKit

final class NewOperationViewController: UIViewController {

    private var operationView: NewOperationView { view as! NewOperationView }

    private var selectedCategoryId: UUID?
    private var selectedAccountId: UUID?
    private var selectedToAccountId: UUID?
    private var selectedDate: Date = Date()
    private var noteText: String = ""

    override func loadView() { view = NewOperationView() }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        operationView.dateRow.setValue(selectedDate.formattedUkrainian)
        setupActions()
    }
}

private extension NewOperationViewController {
    func setupActions() {
        operationView.cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        operationView.saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        operationView.typeSegment.addTarget(self, action: #selector(typeChanged(_:)), for: .valueChanged)

        operationView.keypadView.onDigit   = { [weak self] d in self?.operationView.appendDigit(d) }
        operationView.keypadView.onDecimal = { [weak self] in self?.operationView.appendDecimal() }
        operationView.keypadView.onDelete  = { [weak self] in self?.operationView.deleteLastDigit() }

        operationView.categoryRow.onTap = { [weak self] in self?.pickCategory() }
        operationView.accountRow.onTap  = { [weak self] in self?.pickAccount(forDestination: false) }
        operationView.toAccountRow.onTap = { [weak self] in self?.pickAccount(forDestination: true) }
        operationView.dateRow.onTap     = { [weak self] in self?.pickDate() }
        operationView.noteRow.onTap     = { [weak self] in self?.pickNote() }
    }

    @objc func cancelTapped() { dismiss(animated: true) }

    @objc func saveTapped() {
        let amount = operationView.currentAmountDouble
        guard amount > 0 else {
            showError("Введіть суму")
            return
        }
        guard let categoryId = selectedCategoryId else {
            showError("Виберіть категорію")
            return
        }
        guard let accountId = selectedAccountId else {
            showError("Виберіть рахунок")
            return
        }
        let segIdx = operationView.typeSegment.selectedSegmentIndex
        let type: TransactionType = segIdx == 0 ? .expense : segIdx == 1 ? .income : .transfer

        if type == .transfer && selectedToAccountId == nil {
            showError("Виберіть рахунок призначення")
            return
        }

        let t = Transaction(
            id: UUID(),
            type: type,
            amount: amount,
            categoryId: categoryId,
            accountId: accountId,
            toAccountId: selectedToAccountId,
            date: selectedDate,
            note: noteText
        )
        DataStore.shared.addTransaction(t)
        dismiss(animated: true)
    }

    @objc func typeChanged(_ sender: UISegmentedControl) {
        operationView.setType(sender.selectedSegmentIndex)
        selectedCategoryId = nil
        operationView.categoryRow.setValue("Виберіть категорію")
    }

    func pickCategory() {
        let segIdx = operationView.typeSegment.selectedSegmentIndex
        let cats: [Category]
        if segIdx == 0      { cats = DataStore.expenseCategories }
        else if segIdx == 1 { cats = DataStore.incomeCategories }
        else                { cats = DataStore.expenseCategories }

        let sheet = UIAlertController(title: "Категорія", message: nil, preferredStyle: .actionSheet)
        for cat in cats {
            sheet.addAction(UIAlertAction(title: cat.name, style: .default) { [weak self] _ in
                self?.selectedCategoryId = cat.id
                self?.operationView.categoryRow.setValue(cat.name)
            })
        }
        sheet.addAction(UIAlertAction(title: "Скасувати", style: .cancel))
        present(sheet, animated: true)
    }

    func pickAccount(forDestination: Bool) {
        let accounts = DataStore.shared.accounts
        guard !accounts.isEmpty else {
            showError("Спочатку додайте рахунок у розділі «Ще → Рахунки»")
            return
        }
        let sheet = UIAlertController(title: "Рахунок", message: nil, preferredStyle: .actionSheet)
        for acc in accounts {
            sheet.addAction(UIAlertAction(title: "\(acc.name) (\(acc.balance.hryvnia))", style: .default) { [weak self] _ in
                if forDestination {
                    self?.selectedToAccountId = acc.id
                    self?.operationView.toAccountRow.setValue(acc.name)
                } else {
                    self?.selectedAccountId = acc.id
                    self?.operationView.accountRow.setValue(acc.name)
                }
            })
        }
        sheet.addAction(UIAlertAction(title: "Скасувати", style: .cancel))
        present(sheet, animated: true)
    }

    func pickDate() {
        let alert = UIAlertController(title: "Дата", message: "\n\n\n\n\n\n\n\n\n\n", preferredStyle: .alert)
        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.preferredDatePickerStyle = .wheels
        picker.locale = Locale(identifier: "uk_UA")
        picker.date = selectedDate
        picker.frame = CGRect(x: 0, y: 44, width: 270, height: 200)
        alert.view.addSubview(picker)

        alert.addAction(UIAlertAction(title: "Обрати", style: .default) { [weak self] _ in
            self?.selectedDate = picker.date
            self?.operationView.dateRow.setValue(picker.date.formattedUkrainian)
        })
        alert.addAction(UIAlertAction(title: "Скасувати", style: .cancel))
        present(alert, animated: true)
    }

    func pickNote() {
        let alert = UIAlertController(title: "Нотатка", message: nil, preferredStyle: .alert)
        alert.addTextField { [weak self] tf in
            tf.placeholder = "Коментар до операції"
            tf.text = self?.noteText
        }
        alert.addAction(UIAlertAction(title: "Зберегти", style: .default) { [weak self] _ in
            let text = alert.textFields?.first?.text ?? ""
            self?.noteText = text
            self?.operationView.noteRow.setValue(text.isEmpty ? "Додати нотатку..." : text)
        })
        alert.addAction(UIAlertAction(title: "Скасувати", style: .cancel))
        present(alert, animated: true)
    }

    func showError(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
