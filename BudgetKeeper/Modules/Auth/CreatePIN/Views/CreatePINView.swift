import UIKit
import SnapKit

final class CreatePINView: UIView {

    let titleLabel = UILabel()
    let dotsStackView = UIStackView()
    var dotViews: [UIView] = []
    let keypadView = PINKeypadView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateDots(count: Int) {
        for (i, dot) in dotViews.enumerated() {
            dot.backgroundColor = i < count ? AppColors.primary : .clear
            dot.layer.borderColor = i < count ? AppColors.primary.cgColor : AppColors.separator.cgColor
        }
    }
}

private extension CreatePINView {
    func setupUI() {
        backgroundColor = .white

        titleLabel.text = "Створіть PIN-код"
        titleLabel.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = AppColors.textPrimary
        titleLabel.textAlignment = .center

        dotsStackView.axis = .horizontal
        dotsStackView.spacing = 20
        dotsStackView.distribution = .equalSpacing
        dotsStackView.alignment = .center

        for _ in 0..<4 {
            let dot = UIView()
            dot.layer.cornerRadius = 10
            dot.layer.borderWidth = 2
            dot.layer.borderColor = AppColors.separator.cgColor
            dot.backgroundColor = .clear
            dotViews.append(dot)
            dotsStackView.addArrangedSubview(dot)
            dot.snp.makeConstraints { $0.size.equalTo(20) }
        }
    }

    func setupConstraints() {
        [titleLabel, dotsStackView, keypadView].forEach { addSubview($0) }

        titleLabel.snp.makeConstraints {
            $0.top.equalTo(safeAreaLayoutGuide).offset(60)
            $0.leading.trailing.equalToSuperview().inset(24)
        }
        dotsStackView.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(48)
            $0.centerX.equalToSuperview()
        }
        keypadView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(24)
            $0.bottom.equalTo(safeAreaLayoutGuide).offset(-24)
            $0.height.equalTo(280)
        }
    }
}

final class PINKeypadView: UIView {

    var onDigit: ((String) -> Void)?
    var onDelete: (() -> Void)?
    var onBiometric: (() -> Void)?

    private let keys: [[String]] = [
        ["1", "2", "3"],
        ["4", "5", "6"],
        ["7", "8", "9"],
        ["biometric", "0", "delete"]
    ]

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        let mainStack = UIStackView()
        mainStack.axis = .vertical
        mainStack.spacing = 12
        mainStack.distribution = .fillEqually
        addSubview(mainStack)
        mainStack.snp.makeConstraints { $0.edges.equalToSuperview() }

        for row in keys {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.spacing = 12
            rowStack.distribution = .fillEqually
            mainStack.addArrangedSubview(rowStack)

            for key in row {
                let btn = buildKeyButton(key: key)
                rowStack.addArrangedSubview(btn)
            }
        }
    }

    private func buildKeyButton(key: String) -> UIButton {
        let btn = UIButton(type: .system)
        btn.backgroundColor = AppColors.background
        btn.layer.cornerRadius = 16

        switch key {
        case "biometric":
            let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .regular)
            btn.setImage(UIImage(systemName: "faceid", withConfiguration: config), for: .normal)
            btn.tintColor = AppColors.textPrimary
            btn.addTarget(self, action: #selector(biometricTapped), for: .touchUpInside)
        case "delete":
            let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)
            btn.setImage(UIImage(systemName: "delete.left", withConfiguration: config), for: .normal)
            btn.tintColor = AppColors.textPrimary
            btn.tag = -1
            btn.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)
        default:
            btn.setTitle(key, for: .normal)
            btn.titleLabel?.font = UIFont.systemFont(ofSize: 28, weight: .regular)
            btn.setTitleColor(AppColors.textPrimary, for: .normal)
            btn.tag = Int(key) ?? 0
            btn.addTarget(self, action: #selector(digitTapped(_:)), for: .touchUpInside)
        }
        return btn
    }

    @objc private func digitTapped(_ sender: UIButton) {
        onDigit?(sender.titleLabel?.text ?? "")
    }

    @objc private func deleteTapped() {
        onDelete?()
    }

    @objc private func biometricTapped() {
        onBiometric?()
    }
}
