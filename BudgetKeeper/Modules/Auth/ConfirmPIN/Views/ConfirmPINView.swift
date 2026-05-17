import UIKit
import SnapKit

final class ConfirmPINView: UIView {

    let backButton = UIButton(type: .system)
    let titleLabel = UILabel()
    let subtitleLabel = UILabel()
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

    func shakeAndReset() {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.values = [0, -12, 12, -8, 8, -4, 4, 0]
        animation.duration = 0.4
        dotsStackView.layer.add(animation, forKey: "shake")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            self?.updateDots(count: 0)
        }
    }
}

private extension ConfirmPINView {
    func setupUI() {
        backgroundColor = .white

        let cfg = UIImage.SymbolConfiguration(pointSize: 17, weight: .medium)
        backButton.setImage(UIImage(systemName: "chevron.left", withConfiguration: cfg), for: .normal)
        backButton.tintColor = AppColors.textPrimary
        backButton.isHidden = true

        titleLabel.text = "Підтвердьте PIN-код"
        titleLabel.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = AppColors.textPrimary
        titleLabel.textAlignment = .center

        subtitleLabel.text = "Повторіть PIN для підтвердження"
        subtitleLabel.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        subtitleLabel.textColor = AppColors.textSecondary
        subtitleLabel.textAlignment = .center

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
        [backButton, titleLabel, subtitleLabel, dotsStackView, keypadView].forEach { addSubview($0) }

        backButton.snp.makeConstraints {
            $0.top.equalTo(safeAreaLayoutGuide).offset(16)
            $0.leading.equalToSuperview().offset(12)
            $0.size.equalTo(44)
        }
        titleLabel.snp.makeConstraints {
            $0.top.equalTo(safeAreaLayoutGuide).offset(60)
            $0.leading.trailing.equalToSuperview().inset(24)
        }
        subtitleLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(24)
        }
        dotsStackView.snp.makeConstraints {
            $0.top.equalTo(subtitleLabel.snp.bottom).offset(48)
            $0.centerX.equalToSuperview()
        }
        keypadView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(24)
            $0.bottom.equalTo(safeAreaLayoutGuide).offset(-24)
            $0.height.equalTo(280)
        }
    }
}
