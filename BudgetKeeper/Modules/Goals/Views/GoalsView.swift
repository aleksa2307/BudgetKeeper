import UIKit
import SnapKit

final class GoalsView: UIView {

    let headerLabel = UILabel()
    let backButton = UIButton(type: .system)
    let addButton = UIButton(type: .system)
    let tableView = UITableView(frame: .zero, style: .plain)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
    }

    required init?(coder: NSCoder) { fatalError() }
}

private extension GoalsView {
    func setupUI() {
        backgroundColor = AppColors.background

        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.setTitle("Ще", for: .normal)
        backButton.tintColor = AppColors.primary

        headerLabel.text = "Цілі"
        headerLabel.font = UIFont.systemFont(ofSize: 34, weight: .bold)
        headerLabel.textColor = AppColors.textPrimary

        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        addButton.setImage(UIImage(systemName: "plus", withConfiguration: config), for: .normal)
        addButton.tintColor = AppColors.primary

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.register(GoalCell.self, forCellReuseIdentifier: GoalCell.id)
    }

    func setupConstraints() {
        [backButton, headerLabel, addButton, tableView].forEach { addSubview($0) }

        backButton.snp.makeConstraints {
            $0.top.equalTo(safeAreaLayoutGuide).offset(8)
            $0.leading.equalToSuperview().offset(8)
        }
        addButton.snp.makeConstraints {
            $0.centerY.equalTo(backButton)
            $0.trailing.equalToSuperview().offset(-16)
        }
        headerLabel.snp.makeConstraints {
            $0.top.equalTo(backButton.snp.bottom).offset(8)
            $0.leading.equalToSuperview().offset(16)
        }
        tableView.snp.makeConstraints {
            $0.top.equalTo(headerLabel.snp.bottom).offset(16)
            $0.leading.trailing.bottom.equalToSuperview()
        }
    }
}

final class GoalCell: UITableViewCell {
    static let id = "GoalCell"

    private let ringView = RingProgressView()
    private let nameLabel = UILabel()
    private let savedLabel = UILabel()
    private let targetLabel = UILabel()
    private let pctLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none
        contentView.backgroundColor = AppColors.card
        contentView.layer.cornerRadius = 16
        contentView.clipsToBounds = true

        nameLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        nameLabel.textColor = AppColors.textPrimary

        savedLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        savedLabel.textColor = AppColors.textSecondary

        targetLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        targetLabel.textColor = AppColors.textSecondary

        pctLabel.font = UIFont.systemFont(ofSize: 13, weight: .bold)
        pctLabel.textColor = AppColors.primary
        pctLabel.textAlignment = .center

        [ringView, nameLabel, savedLabel, targetLabel, pctLabel].forEach { contentView.addSubview($0) }

        ringView.snp.makeConstraints { $0.trailing.equalToSuperview().offset(-16); $0.centerY.equalToSuperview(); $0.size.equalTo(56) }
        pctLabel.snp.makeConstraints { $0.center.equalTo(ringView) }
        nameLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.top.equalToSuperview().offset(20)
            $0.trailing.lessThanOrEqualTo(ringView.snp.leading).offset(-8)
        }
        savedLabel.snp.makeConstraints {
            $0.leading.equalTo(nameLabel)
            $0.top.equalTo(nameLabel.snp.bottom).offset(4)
        }
        targetLabel.snp.makeConstraints {
            $0.leading.equalTo(nameLabel)
            $0.top.equalTo(savedLabel.snp.bottom).offset(2)
            $0.bottom.equalToSuperview().offset(-20)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(name: String, saved: String, target: String, percent: Int, color: UIColor) {
        nameLabel.text = name
        savedLabel.text = "Накоплено: \(saved)"
        targetLabel.text = "Ціль: \(target)"
        pctLabel.text = "\(percent)%"
        ringView.progress = CGFloat(percent) / 100.0
        ringView.color = color
        ringView.setNeedsDisplay()
    }
}

final class RingProgressView: UIView {
    var progress: CGFloat = 0
    var color: UIColor = AppColors.primary

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) { fatalError() }

    override func draw(_ rect: CGRect) {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2 - 4
        let lineWidth: CGFloat = 5

        // Background ring
        let bgPath = UIBezierPath(arcCenter: center, radius: radius,
                                   startAngle: -CGFloat.pi / 2,
                                   endAngle: 3 * CGFloat.pi / 2,
                                   clockwise: true)
        AppColors.separator.setStroke()
        bgPath.lineWidth = lineWidth
        bgPath.lineCapStyle = .round
        bgPath.stroke()

        // Progress ring
        let endAngle = -CGFloat.pi / 2 + 2 * CGFloat.pi * progress
        let fgPath = UIBezierPath(arcCenter: center, radius: radius,
                                   startAngle: -CGFloat.pi / 2,
                                   endAngle: endAngle,
                                   clockwise: true)
        color.setStroke()
        fgPath.lineWidth = lineWidth
        fgPath.lineCapStyle = .round
        fgPath.stroke()
    }
}
