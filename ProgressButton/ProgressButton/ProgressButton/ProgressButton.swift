//
//  ProgressButton.swift
//  ProgressButton
//
//  Created by Andrii Halushka on 23.12.2020.
//

import UIKit

// Note: @IBDesignable needed in order to `intrinsicContentSize` work in storyboard
@IBDesignable
class AdvertSkipButton: UIView {
    
    // MARK: - Public API
    
    enum Props {
        case idle
        case start(forDuration: Int)
        case update(time: Int)
        case transitToSkippable
    }
    
    func render(_ props: Props) {
        switch props {
        case .idle:
            setCountdownLabelHidden(true)
            setXMarkEnabled(false)
            resetStroke()
        case .start(forDuration: let duration):
            setCountdownLabelHidden(false)
            countDownNumberLabel.text = "\(duration)"
            animateStroke(duration: duration)
        case .update(time: let time):
            setCountdownLabelHidden(false)
            countDownNumberLabel.text = "\(time)"
        case .transitToSkippable:
            setCountdownLabelHidden(true)
            setXMarkEnabled(true)
        }
    }
    
    func addTarget(_ target: Any?, action: Selector, for controlEvents: UIControl.Event) {
        control.addTarget(target, action: action, for: controlEvents)
    }
    
    func removeTarget(_ target: Any?, action: Selector?, for controlEvents: UIControl.Event) {
        control.removeTarget(target, action: action, for: controlEvents)
    }
    
    var allTargets: Set<AnyHashable> {
        control.allTargets
    }
    
    func pauseAnimations() {
        let pausedTime = layer.convertTime(CACurrentMediaTime(), from: nil)
        layer.speed = 0.0
        layer.timeOffset = pausedTime
    }
    
    func resumeAnimations() {
        let pausedTime = layer.timeOffset
        layer.speed = 1.0
        layer.timeOffset = 0.0
        layer.beginTime = 0.0
        let timeSincePause = layer.convertTime(CACurrentMediaTime(), from: nil) - pausedTime
        layer.beginTime = timeSincePause
    }
    
    // MARK: - Private API
    
    private func animateStroke(duration: Int) {
        let animation = CABasicAnimation(keyPath: #keyPath(CAShapeLayer.strokeEnd))
        animation.fromValue = 0.0
        animation.toValue = 1.0
        animation.duration = CFTimeInterval(duration)
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        
        strokeCircle.add(animation, forKey: C.strokeAnimationKey)
    }
    
    private func resetStroke() {
        strokeCircle.strokeEnd = 0.0
        strokeCircle.removeAnimation(forKey: C.strokeAnimationKey)
    }
    
    private func setCountdownLabelHidden(_ isHidden: Bool, animated: Bool = false) {
        countDownNumberLabel.isHidden = isHidden
    }
    
    private func setXMarkEnabled(_ isEnabled: Bool, animated: Bool = false) {
        xMarkImageView.isHidden = !isEnabled
        control.isUserInteractionEnabled = isEnabled
    }
    
    // MARK: - Guts
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        updateFilledCircleFrame()
        updateStrokeCircleFrame()
        _ = countDownNumberLabel
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: 45, height: 45)
    }
    
    private func setup() {
        self.backgroundColor = .clear
        
        updateFilledCircleFrame()
        updateStrokeCircleFrame()
        
        countDownNumberLabel.isHidden = true
        control.isUserInteractionEnabled = false
        xMarkImageView.isHidden = true
    }
    
    private lazy var filledCircle: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.fillColor = C.circleFillColor
        layer.position = CGPoint(x: self.frame.midX, y: self.frame.midY)
        self.layer.addSublayer(layer)
        return layer
    }()
    
    private lazy var strokeCircle: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.fillColor = UIColor.clear.cgColor
        layer.strokeColor = C.progressColor
        layer.position = CGPoint(x: self.frame.midX, y: self.frame.midY)
        layer.strokeEnd = 0.0
        layer.lineJoin = .round
        layer.lineWidth = 4
        self.layer.addSublayer(layer)
        return layer
    }()
    
    private lazy var countDownNumberLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 32)
        label.minimumScaleFactor = 0.1
        
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        
        NSLayoutConstraint.activate([
            label.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: 0.22, constant: 0),
            label.heightAnchor.constraint(equalTo: label.widthAnchor, multiplier: 1.0, constant: 0),
            label.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        ])
        
        return label
    }()
    
    private lazy var control: UIControl = {
        let control = UIControl()
        
        control.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(control)
        
        NSLayoutConstraint.activate([
            control.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: 1.0, constant: 0),
            control.heightAnchor.constraint(equalTo: control.widthAnchor, multiplier: 1.0, constant: 0),
            control.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            control.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        ])
        
        return control
    }()
    
    private lazy var xMarkImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: C.xMarkImageName)
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(imageView)
        
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: 0.3, constant: 0),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 1.0, constant: 0),
            imageView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        ])
        
        return imageView
    }()
    
    private func updateStrokeCircleFrame() {
        let layerFrame = filledCircle.bounds.inset(by: UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8))
        
        strokeCircle.frame = layerFrame
        let strokeFrame = CGRect(origin: .zero, size: layerFrame.size)
        
        strokeCircle.path = UIBezierPath(arcCenter: CGPoint(x: strokeFrame.midX, y: strokeFrame.midY),
                                         radius: min(strokeFrame.size.width, strokeFrame.size.height) / 2,
                                         startAngle: -CGFloat.pi / 2,
                                         endAngle: 3 * CGFloat.pi / 2,
                                         clockwise: true).cgPath
    }
    
    private func updateFilledCircleFrame() {
        let filledFrame = self.bounds
        filledCircle.frame = filledFrame
        filledCircle.path = UIBezierPath(ovalIn: CGRect(origin: .zero, size: filledFrame.size)).cgPath
    }
    
    private enum C {
        static let strokeAnimationKey = "strokeEnd"
        static let xMarkImageName = I.commonXMarkVector.name
        static let circleFillColor = UIColor.black.withAlphaComponent(0.7).cgColor
        static let progressColor = UIColor.white.cgColor
    }
}

