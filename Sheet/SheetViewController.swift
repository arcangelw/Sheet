import SnapKit
import SwiftEntryKit
import UIKit

extension SheetViewController {
    /// 样式类型
    enum ActionStyle {
        /// 默认样式
        case `default`
        /// 取消
        case cancel
        /// 警示样式
        case destructive
    }

    /// 事件相关属性
    class Action {
        /// 标题
        let title: String
        /// 样式
        let style: ActionStyle
        /// 回调
        let handler: (() -> Void)?
        /// 自定义标题颜色
        var titleColor: UIColor?
        /// 自定义标题字体
        var titleFont: UIFont?
        /// 默认色
        var normalColor: UIColor?
        /// 高亮色
        var highlightedColor: UIColor?

        /// 初始化配置
        /// - Parameters:
        ///   - title: 标题
        ///   - style: 样式
        ///   - handler: 回调
        init(title: String, style: ActionStyle = .default, handler: (() -> Void)? = nil) {
            self.title = title
            self.style = style
            self.handler = handler
        }
    }

    /// 事件按钮
    private class ActionButton: UIButton {
        /// 背景色环境色视图
        weak var behindColorView: UIView?
        /// 事件
        let action: Action

        /// 创建按钮
        /// - Parameter action: 事件配置
        init(action: Action) {
            self.action = action
            super.init(frame: .zero)
            clipsToBounds = true
            let title = NSAttributedString(string: action.title, attributes: [.font: action.titleFont!, .foregroundColor: action.titleColor!])
            setAttributedTitle(title, for: .normal)
            backgroundColor = action.normalColor
        }

        @available(*, unavailable)
        required init?(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        /// 高亮处理
        override var isHighlighted: Bool {
            didSet {
                if isHighlighted {
                    if action.highlightedColor != nil, currentBackgroundImage == nil {
                        backgroundColor = action.highlightedColor
                    } else {
                        behindColorView?.alpha = 0.9
                    }
                } else {
                    if action.normalColor != nil {
                        backgroundColor = action.highlightedColor
                    } else {
                        behindColorView?.alpha = 1
                    }
                }
            }
        }
    }
}

/// 自定义Sheet
/// 支持简单的Sheet弹窗交互
final class SheetViewController: UIViewController {
    /// 允许点击背景dismiss
    var dismissOnTap: Bool = false

    /// 横向间隙
    var horizontalPadding: CGFloat = 0

    /// 蒙层颜色
    var maskColor: UIColor = .clear
    /// 背景色
    var backgrounColor: UIColor = .clear
    /// 环境色
    var ambientColor: UIColor = .white
    /// 小间隙分割线色
    var smallFragmentSeparatorColor: UIColor = .separator
    /// 大间隙分割线色
    var bigFragmentSeparatorColor: UIColor = .clear

    /// 背景圆角
    var roundCorners: EKAttributes.RoundCorners = .none
    /// 按钮圆角
    var actionCornerRadius: CGFloat = 0

    /// 按钮高度
    var actionHeight: CGFloat = 56
    /// 大间隙
    var bigFragment: CGFloat = 8
    /// 小间隙
    var smallFragment: CGFloat = 0.5

    /// 默认按钮颜色
    var buttonColor: UIColor = .black
    /// 警示按钮颜色
    var destructiveButtonColor: UIColor = .red
    /// 取消按钮颜色
    var cancelButtonColor: UIColor = .black

    /// 标题颜色
    var titleColor: UIColor = .label {
        didSet {
            titleLabel.textColor = titleColor
        }
    }

    /// 消息颜色
    var messageColor: UIColor = .secondaryLabel {
        didSet {
            messageLabel.textColor = messageColor
        }
    }

    /// 按钮字体
    var buttonFont: UIFont = UIFont.systemFont(ofSize: UIFont.buttonFontSize)

    /// 标题字体
    var titleFont: UIFont = UIFont.systemFont(ofSize: UIFont.labelFontSize, weight: .bold) {
        didSet {
            titleLabel.font = titleFont
        }
    }

    /// 消息字体
    var messageFont: UIFont = UIFont.systemFont(ofSize: UIFont.labelFontSize) {
        didSet {
            messageLabel.font = messageFont
        }
    }

    /// 标题纵向padding
    var titleVerticalPadding: CGFloat = 10
    /// 标题横向padding
    var titleHorizontalPadding: CGFloat = 10
    /// 标题行间隙
    var titleLineSpacing: CGFloat = 10

    /// 标题
    override var title: String? {
        get { super.title }
        set {}
    }

    /// 消息
    let message: String?

    /// 初始化
    /// - Parameters:
    ///   - title: 标题
    ///   - message: 消息
    init(title: String? = nil, message: String? = nil) {
        self.message = message
        super.init(nibName: nil, bundle: nil)
        super.title = title
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 容器
    private let contentView = UIView()
    /// 圆角layer
    private let mask = CAShapeLayer()
    /// 按钮事件存储
    private var actions: [Action] = []
    /// 取消事件
    private var cancelAction: Action? {
        didSet {
            assert(oldValue == nil, "cancelAction only one")
        }
    }

    /// 标题
    private var titleLabel = UILabel()
    /// 消息
    private var messageLabel = UILabel()

    /// 添加操作
    /// - Parameter action: action事件
    func addAction(_ action: Action) {
        action.titleFont = action.titleFont ?? buttonFont
        switch action.style {
        case .cancel:
            action.titleColor = action.titleColor ?? cancelButtonColor
            cancelAction = action
            return
        case .destructive:
            action.titleColor = action.titleColor ?? destructiveButtonColor
        case .default:
            action.titleColor = action.titleColor ?? buttonColor
        }
        actions.append(action)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        contentView.backgroundColor = .clear
        view.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        titleLabel.text = title
        messageLabel.text = message
        titleLabel.textColor = titleColor
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center
        titleLabel.font = titleFont
        messageLabel.textColor = messageColor
        messageLabel.font = messageFont
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center

        setupContent()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard isViewLoaded, view.bounds.size != .zero else {
            return
        }
        /// 圆角配置
        mask.frame = contentView.bounds
        switch roundCorners {
        case .none:
            contentView.layer.mask = nil
        case let .all(radius):
            mask.path = UIBezierPath(roundedRect: mask.bounds, byRoundingCorners: .allCorners, cornerRadii: .init(width: radius, height: radius)).cgPath

        case let .top(radius):
            mask.path = UIBezierPath(roundedRect: mask.bounds, byRoundingCorners: [.topLeft, .topRight], cornerRadii: .init(width: radius, height: radius)).cgPath
            contentView.layer.mask = mask
        case let .bottom(radius):
            mask.path = UIBezierPath(roundedRect: mask.bounds, byRoundingCorners: [.bottomLeft, .bottomRight], cornerRadii: .init(width: radius, height: radius)).cgPath
            contentView.layer.mask = mask
        }
    }

    /// 内容布局配置
    private func setupContent() {
        let mainStack = UIStackView()
        mainStack.axis = .vertical
        mainStack.spacing = 0
        mainStack.alignment = .fill

        let hasTitle = !(super.title?.isEmpty ?? true)
        let hasMessage = !(message?.isEmpty ?? true)
        if hasTitle || hasMessage || !actions.isEmpty {
            let actionStack = UIStackView()
            actionStack.axis = .vertical
            actionStack.spacing = 0
            actionStack.alignment = .fill
            actionStack.layer.cornerRadius = actionCornerRadius
            actionStack.layer.masksToBounds = true

            if hasTitle || hasMessage {
                let textStack = UIStackView()
                textStack.axis = .vertical
                textStack.spacing = titleLineSpacing
                textStack.alignment = .fill
                textStack.addArrangedSubview(titleLabel)
                textStack.addArrangedSubview(messageLabel)
                let behindColorView = UIView()
                behindColorView.backgroundColor = ambientColor
                behindColorView.addSubview(textStack)
                textStack.snp.makeConstraints { make in
                    make.edges.equalTo(UIEdgeInsets(top: titleVerticalPadding, left: titleHorizontalPadding, bottom: titleVerticalPadding, right: titleHorizontalPadding))
                }
                actionStack.addArrangedSubview(behindColorView)
                if !actions.isEmpty {
                    let separatorView = UIView()
                    separatorView.backgroundColor = smallFragmentSeparatorColor
                    separatorView.heightAnchor.constraint(equalToConstant: smallFragment).isActive = true
                    actionStack.addArrangedSubview(separatorView)
                }
            }

            for (index, action) in actions.enumerated() {
                let behindColorView = UIView()
                behindColorView.heightAnchor.constraint(equalToConstant: actionHeight).isActive = true
                behindColorView.backgroundColor = ambientColor
                let actionButton = ActionButton(action: action)
                actionButton.behindColorView = behindColorView
                actionButton.addTarget(self, action: #selector(tapActionButton(_:)), for: .touchUpInside)
                behindColorView.addSubview(actionButton)
                actionButton.snp.makeConstraints { make in
                    make.edges.equalToSuperview()
                }
                actionStack.addArrangedSubview(behindColorView)
                if index < actions.count - 1 {
                    let separatorView = UIView()
                    separatorView.backgroundColor = smallFragmentSeparatorColor
                    separatorView.heightAnchor.constraint(equalToConstant: smallFragment).isActive = true
                    actionStack.addArrangedSubview(separatorView)
                }
            }
            mainStack.addArrangedSubview(actionStack)
        }

        if let cancelAction = cancelAction {
            if !actions.isEmpty {
                let separatorView = UIView()
                separatorView.backgroundColor = bigFragmentSeparatorColor
                separatorView.heightAnchor.constraint(equalToConstant: bigFragment).isActive = true
                mainStack.addArrangedSubview(separatorView)
            }
            let behindColorView = UIView()
            behindColorView.heightAnchor.constraint(equalToConstant: actionHeight).isActive = true
            behindColorView.backgroundColor = ambientColor
            behindColorView.layer.cornerRadius = actionCornerRadius
            behindColorView.layer.masksToBounds = true
            let actionButton = ActionButton(action: cancelAction)
            actionButton.behindColorView = behindColorView
            actionButton.addTarget(self, action: #selector(tapActionButton(_:)), for: .touchUpInside)
            behindColorView.addSubview(actionButton)
            actionButton.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            mainStack.addArrangedSubview(behindColorView)
        }
        contentView.addSubview(mainStack)
        mainStack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    /// 点击事件
    @objc
    private func tapActionButton(_ action: ActionButton) {
        /// 内存地址标记查询弹窗并dismiss
        SwiftEntryKit.dismiss(.specific(entryName: "\(self)")) {
            action.action.handler?()
        }
    }
}

extension SheetViewController {
    /// 展示
    /// - Parameter isOverridden: 是否覆盖安全区
    func show(safeArea isOverridden: Bool = true) {
        guard !actions.isEmpty || cancelAction != nil else { return }
        var attributes: EKAttributes = .bottomFloat
        /// 绘制样式配置
        attributes.displayMode = .inferred
        attributes.displayDuration = .infinity
        /// 蒙层 背景 阴影颜色配置
        attributes.screenBackground = .color(color: .init(light: maskColor, dark: maskColor))
        attributes.entryBackground = .color(color: .init(light: backgrounColor, dark: backgrounColor))
        attributes.shadow = .none
        /// 圆角 页面手势交互配置
        attributes.roundCorners = roundCorners
        attributes.screenInteraction = dismissOnTap ? .dismiss : .absorbTouches
        attributes.entryInteraction = .absorbTouches
        attributes.scroll = .disabled
        /// 展示动画配置
        attributes.entranceAnimation = .init(
            translate: .init(
                duration: 0.3,
                spring: .init(damping: 1, initialVelocity: 0)
            )
        )
        attributes.exitAnimation = .init(
            translate: .init(duration: 0.25)
        )
        attributes.popBehavior = .animated(
            animation: .init(
                translate: .init(duration: 0.25)
            )
        )
        /// 计算尺寸 配置安全区 状态栏
        let screenBounds = UIScreen.main.bounds
        let width = min(screenBounds.width, screenBounds.height) - horizontalPadding * 2
        titleLabel.preferredMaxLayoutWidth = width - titleHorizontalPadding * 2
        messageLabel.preferredMaxLayoutWidth = width - titleHorizontalPadding * 2
        let size = view.systemLayoutSizeFitting(.init(width: width, height: .greatestFiniteMagnitude))
        attributes.positionConstraints.size = .init(width: .constant(value: width), height: .constant(value: size.height))
        attributes.positionConstraints.verticalOffset = 0
        attributes.positionConstraints.safeArea = isOverridden ? .overridden : .empty(fillSafeArea: true)
        attributes.statusBar = .currentStatusBar
        /// 使用内存地址标记
        attributes.name = "\(self)"
        /// 配置弹窗队列
        attributes.precedence = .enqueue(priority: .normal)
        SwiftEntryKit.display(entry: self, using: attributes)
    }
}
