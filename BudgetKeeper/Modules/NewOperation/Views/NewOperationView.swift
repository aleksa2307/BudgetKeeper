import UIKit
import SnapKit

final class NewOperationView: UIView {

    let cancelButton  = UIButton(type: .system)
    let titleLabel    = UILabel()
    let saveButton    = UIButton(type: .system)
    let dragHandle    = UIView()
    let typeSegment   = UISegmentedControl(items: ["Витрата", "Дохід"])
    let currencyLabel = UILabel()
    let amountLabel   = UILabel()
    let formCard      = UIView()

    let categoryRow = FormRowView(icon: "tag",        label: "Категорія", value: "Виберіть категорію")
    let accountRow  = FormRowView(icon: "creditcard", label: "Рахунок",   value: "Виберіть рахунок")
    let dateRow     = FormRowView(icon: "calendar",   label: "Дата",      value: Date().formattedUkrainian)
    let noteRow     = FormRowView(icon: "doc.text",   label: "Нотатка",   value: "Додати нотатку...")

    let keypadView = NumericKeypadView()

    private var amountString = "0"

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
    }

    required init?(coder: NSCoder) { fatalError() }

    func appendDigit(_ digit: String) {
        if amountString == "0" { amountString = digit }
        else if amountString.count < 12 { amountString += digit }
        updateAmountDisplay()
    }

    func appendDecimal() {
        if !amountString.contains(",") { amountString += "," }
        updateAmountDisplay()
    }

    func deleteLastDigit() {
        if amountString.count > 1 { amountString.removeLast() }
        else { amountString = "0" }
        updateAmountDisplay()
    }

    var currentAmountDouble: Double {
        Double(amountString.replacingOccurrences(of: ",", with: ".")) ?? 0
    }

    func setAmount(_ value: Double) {
        amountString = value == value.rounded()
            ? String(Int(value))
            : String(value).replacingOccurrences(of: ".", with: ",")
        updateAmountDisplay()
    }

    private func updateAmountDisplay() { amountLabel.text = amountString }

    func setType(_ index: Int) {
        switch index {
        case 0: amountLabel.textColor = AppColors.red
        case 1: amountLabel.textColor = AppColors.green
        default: break
        }
    }
}

private extension NewOperationView {
    func setupUI() {
        backgroundColor = .white
        layer.cornerRadius = 24
        clipsToBounds = true

        dragHandle.backgroundColor = AppColors.separator
        dragHandle.layer.cornerRadius = 2

        cancelButton.setTitle("Скасувати", for: .normal)
        cancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        cancelButton.tintColor = AppColors.primary

        titleLabel.text = "Нова операція"
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = AppColors.textPrimary
        titleLabel.textAlignment = .center
        titleLabel.setContentHuggingPriority(.required, for: .vertical)

        saveButton.setTitle("Зберегти", for: .normal)
        saveButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        saveButton.tintColor = AppColors.primary

        typeSegment.selectedSegmentIndex = 0
        typeSegment.backgroundColor = AppColors.background

        currencyLabel.text = "₴"
        currencyLabel.font = UIFont.systemFont(ofSize: 28, weight: .light)
        currencyLabel.textColor = AppColors.textSecondary

        amountLabel.text = "0"
        amountLabel.font = UIFont.systemFont(ofSize: 48, weight: .bold)
        amountLabel.textColor = AppColors.red
        amountLabel.setContentHuggingPriority(.required, for: .vertical)

        formCard.backgroundColor = AppColors.background
        formCard.layer.cornerRadius = 16
        formCard.clipsToBounds = true
    }

    func setupConstraints() {
        [dragHandle, cancelButton, titleLabel, saveButton,
         typeSegment, currencyLabel, amountLabel, formCard, keypadView].forEach { addSubview($0) }

        dragHandle.snp.makeConstraints {
            $0.top.equalToSuperview().offset(8)
            $0.centerX.equalToSuperview()
            $0.width.equalTo(40)
            $0.height.equalTo(4)
        }
        titleLabel.snp.makeConstraints {
            $0.top.equalTo(dragHandle.snp.bottom).offset(10)
            $0.centerX.equalToSuperview()
        }
        cancelButton.snp.makeConstraints { $0.centerY.equalTo(titleLabel); $0.leading.equalToSuperview().offset(16) }
        saveButton.snp.makeConstraints { $0.centerY.equalTo(titleLabel); $0.trailing.equalToSuperview().offset(-16) }

        typeSegment.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(42)
        }
        currencyLabel.snp.makeConstraints { $0.centerY.equalTo(amountLabel); $0.trailing.equalTo(amountLabel.snp.leading).offset(-4) }
        amountLabel.snp.makeConstraints {
            $0.top.equalTo(typeSegment.snp.bottom).offset(16)
            $0.centerX.equalToSuperview().offset(20)
        }

        formCard.snp.makeConstraints {
            $0.top.equalTo(amountLabel.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(16)
        }

        let rows: [FormRowView] = [categoryRow, accountRow, dateRow, noteRow]
        var prev: UIView? = nil
        for (i, row) in rows.enumerated() {
            formCard.addSubview(row)
            row.snp.makeConstraints {
                $0.leading.trailing.equalToSuperview()
                $0.top.equalTo(prev?.snp.bottom ?? formCard.snp.top)
                $0.height.equalTo(54)
            }
            if i > 0 {
                let sep = UIView(); sep.backgroundColor = AppColors.separator
                formCard.addSubview(sep)
                sep.snp.makeConstraints {
                    $0.leading.equalToSuperview().offset(52)
                    $0.trailing.equalToSuperview()
                    $0.top.equalTo(prev!.snp.bottom)
                    $0.height.equalTo(0.5)
                }
            }
            prev = row
        }
        if let last = prev {
            formCard.snp.makeConstraints { $0.bottom.equalTo(last.snp.bottom) }
        }

        keypadView.snp.makeConstraints {
            $0.top.equalTo(formCard.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalTo(safeAreaLayoutGuide).offset(-8)
        }
    }
}

final class FormRowView: UIView {
    var onTap: (() -> Void)?

    private let iconImg    = UIImageView()
    private let labelText  = UILabel()
    private let valueText  = UILabel()
    private let chevron    = UIImageView()

    init(icon: String, label: String, value: String) {
        super.init(frame: .zero)
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .regular)
        iconImg.image = UIImage(systemName: icon, withConfiguration: config)
        iconImg.tintColor = AppColors.textSecondary
        iconImg.contentMode = .scaleAspectFit

        labelText.text = label
        labelText.font = UIFont.systemFont(ofSize: 15)
        labelText.textColor = AppColors.textSecondary

        valueText.text = value
        valueText.font = UIFont.systemFont(ofSize: 15)
        valueText.textColor = AppColors.textPrimary
        valueText.textAlignment = .right
        valueText.setContentHuggingPriority(.required, for: .horizontal)

        let chevronConfig = UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold)
        chevron.image = UIImage(systemName: "chevron.right", withConfiguration: chevronConfig)
        chevron.tintColor = AppColors.textSecondary.withAlphaComponent(0.5)

        [iconImg, labelText, valueText, chevron].forEach { addSubview($0) }
        iconImg.snp.makeConstraints { $0.leading.equalToSuperview().offset(16); $0.centerY.equalToSuperview(); $0.size.equalTo(20) }
        labelText.snp.makeConstraints { $0.leading.equalTo(iconImg.snp.trailing).offset(12); $0.centerY.equalToSuperview() }
        chevron.snp.makeConstraints { $0.trailing.equalToSuperview().offset(-16); $0.centerY.equalToSuperview() }
        valueText.snp.makeConstraints {
            $0.trailing.equalTo(chevron.snp.leading).offset(-6)
            $0.centerY.equalToSuperview()
            $0.leading.greaterThanOrEqualTo(labelText.snp.trailing).offset(8)
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
        addGestureRecognizer(tap)
        isUserInteractionEnabled = true
    }

    required init?(coder: NSCoder) { fatalError() }

    func setValue(_ value: String) { valueText.text = value }

    @objc private func tapped() { onTap?() }
}

final class NumericKeypadView: UIView {

    var onDigit:   ((String) -> Void)?
    var onDecimal: (() -> Void)?
    var onDelete:  (() -> Void)?

    override init(frame: CGRect) { super.init(frame: frame); setupUI() }
    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        let mainStack = UIStackView()
        mainStack.axis = .vertical
        mainStack.spacing = 8
        mainStack.distribution = .fillEqually
        addSubview(mainStack)
        mainStack.snp.makeConstraints { $0.edges.equalToSuperview() }

        let rows: [[String]] = [
            ["7", "8", "9"],
            ["4", "5", "6"],
            ["1", "2", "3"],
            ["0", ",", "⌫"],
        ]
        for row in rows {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.spacing = 8
            rowStack.distribution = .fillEqually
            mainStack.addArrangedSubview(rowStack)
            for key in row { rowStack.addArrangedSubview(buildKey(key)) }
        }
    }

    private func buildKey(_ key: String) -> UIButton {
        let btn = UIButton(type: .system)
        btn.layer.cornerRadius = 16
        if key == "⌫" {
            let cfg = UIImage.SymbolConfiguration(pointSize: 18, weight: .regular)
            btn.setImage(UIImage(systemName: "delete.left", withConfiguration: cfg), for: .normal)
            btn.tintColor = AppColors.textPrimary
            btn.backgroundColor = AppColors.background
            btn.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)
        } else if key == "," {
            btn.setTitle(",", for: .normal)
            btn.titleLabel?.font = UIFont.systemFont(ofSize: 22, weight: .regular)
            btn.setTitleColor(AppColors.textPrimary, for: .normal)
            btn.backgroundColor = AppColors.background
            btn.addTarget(self, action: #selector(decimalTapped), for: .touchUpInside)
        } else {
            btn.setTitle(key, for: .normal)
            btn.titleLabel?.font = UIFont.systemFont(ofSize: 22, weight: .regular)
            btn.setTitleColor(AppColors.textPrimary, for: .normal)
            btn.backgroundColor = AppColors.background
            btn.addTarget(self, action: #selector(digitTapped(_:)), for: .touchUpInside)
        }
        return btn
    }

    @objc private func digitTapped(_ sender: UIButton) { onDigit?(sender.titleLabel?.text ?? "") }
    @objc private func deleteTapped() { onDelete?() }
    @objc private func decimalTapped() { onDecimal?() }
}
