import UIKit

final class NewOperationViewController: UIViewController {

    private var operationView: NewOperationView { view as! NewOperationView }

    var transactionToEdit: Transaction?

    private var selectedCategoryId: UUID?
    private var selectedAccountId: UUID?
    private var selectedDate: Date = Date()
    private var noteText: String = ""

    override func loadView() { view = NewOperationView() }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        operationView.dateRow.setValue(selectedDate.formattedUkrainian)
        setupActions()
        if let t = transactionToEdit { prefill(with: t) }
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
        operationView.accountRow.onTap  = { [weak self] in self?.pickAccount() }
        operationView.dateRow.onTap     = { [weak self] in self?.pickDate() }
        operationView.noteRow.onTap     = { [weak self] in self?.pickNote() }
    }

    func prefill(with t: Transaction) {
        operationView.titleLabel.text = "Редагувати операцію"
        let segIdx = t.type == .income ? 1 : 0
        operationView.typeSegment.selectedSegmentIndex = segIdx
        operationView.setType(segIdx)
        operationView.setAmount(t.amount)

        selectedCategoryId = t.categoryId
        operationView.categoryRow.setValue(DataStore.shared.category(for: t.categoryId)?.name ?? "Інше")

        selectedAccountId = t.accountId
        operationView.accountRow.setValue(DataStore.shared.account(for: t.accountId)?.name ?? "Рахунок")

        selectedDate = t.date
        operationView.dateRow.setValue(t.date.formattedUkrainian)

        noteText = t.note
        operationView.noteRow.setValue(t.note.isEmpty ? "Додати нотатку..." : t.note)
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
        let type: TransactionType = segIdx == 0 ? .expense : .income

        let t = Transaction(
            id: transactionToEdit?.id ?? UUID(),
            type: type,
            amount: amount,
            categoryId: categoryId,
            accountId: accountId,
            toAccountId: nil,
            date: selectedDate,
            note: noteText
        )
        if transactionToEdit != nil {
            DataStore.shared.updateTransaction(t)
        } else {
            DataStore.shared.addTransaction(t)
        }
        dismiss(animated: true)
    }

    @objc func typeChanged(_ sender: UISegmentedControl) {
        operationView.setType(sender.selectedSegmentIndex)
        selectedCategoryId = nil
        operationView.categoryRow.setValue("Виберіть категорію")
    }

    func pickCategory() {
        let segIdx = operationView.typeSegment.selectedSegmentIndex
        let type: TransactionType = segIdx == 0 ? .expense : .income
        let cats = DataStore.shared.categories(for: type)

        let sheet = UIAlertController(title: "Категорія", message: nil, preferredStyle: .actionSheet)
        for cat in cats {
            sheet.addAction(UIAlertAction(title: cat.name, style: .default) { [weak self] _ in
                self?.selectedCategoryId = cat.id
                self?.operationView.categoryRow.setValue(cat.name)
            })
        }
        sheet.addAction(UIAlertAction(title: "Нова категорія…", style: .default) { [weak self] _ in
            self?.createCategory(type: type)
        })
        sheet.addAction(UIAlertAction(title: "Скасувати", style: .cancel))
        present(sheet, animated: true)
    }

    func createCategory(type: TransactionType) {
        let alert = UIAlertController(title: "Нова категорія", message: nil, preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Назва категорії" }
        alert.addAction(UIAlertAction(title: "Додати", style: .default) { [weak self] _ in
            let name = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespaces) ?? ""
            guard !name.isEmpty else { return }
            let colors = ["#FF9500", "#5856D6", "#34C759", "#0066FF", "#FF3B30", "#8A8A8E"]
            let cat = Category(id: UUID(), name: name, icon: "tag.fill",
                               colorHex: colors[DataStore.shared.customCategories.count % colors.count],
                               type: type)
            DataStore.shared.addCategory(cat)
            self?.selectedCategoryId = cat.id
            self?.operationView.categoryRow.setValue(cat.name)
        })
        alert.addAction(UIAlertAction(title: "Скасувати", style: .cancel))
        present(alert, animated: true)
    }

    func pickAccount() {
        let accounts = DataStore.shared.accounts
        guard !accounts.isEmpty else {
            showError("Спочатку додайте рахунок у розділі «Ще → Рахунки»")
            return
        }
        let sheet = UIAlertController(title: "Рахунок", message: nil, preferredStyle: .actionSheet)
        for acc in accounts {
            sheet.addAction(UIAlertAction(title: "\(acc.name) (\(acc.balance.hryvnia))", style: .default) { [weak self] _ in
                self?.selectedAccountId = acc.id
                self?.operationView.accountRow.setValue(acc.name)
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
