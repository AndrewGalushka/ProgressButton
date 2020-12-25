//
//  ProgressButton.swift
//  ProgressButton
//
//  Created by Andrii Halushka on 23.12.2020.
//

import UIKit

class AdvertSkipButton: UIView {
    
    // MARK: - Public API
    
    enum Props {
        case idle
        case start(for: Int,
                   timeBeforeSkip: Int,
                   onSkip: () -> Void,
                   onFinish:() -> Void)
    }
    
    func render(props: Props) {
        switch props {
        case .idle:
            reset()
        case .start(let time, let timeBeforeSkip, let onSkip, let onFinish):
            self.start(for: time,
                       timeBeforeSkip: timeBeforeSkip,
                       onSkip: onSkip,
                       onFinish: onFinish)
        }
    }
    
    // MARK: - Private
    
    private var timer: AdvertisementTimer?
    private var onSkip: (() -> Void)?
        
    private func start(for duration: Int,
                       timeBeforeSkip: Int,
                       onSkip: @escaping () -> Void,
                       onFinish: @escaping () -> Void) {
        self.onSkip = onSkip
        setCountdownLabelHidden(false)
        countDownNumberLabel.text = "\(duration)"
        animateStroke(duration: duration)
        
        self.timer = AdvertisementTimer(advertDuration: duration, timeBeforeSkip: timeBeforeSkip)
        
        self.timer?.startTimer(onTick: { [weak self] (tickType) in
            guard let self = self else { return }
            
            switch tickType {
            case .beforeSkip(timeLeft: let timeLeft):
                self.countDownNumberLabel.text = "\(timeLeft)"
            case .reachedSkip:
                self.setCountdownLabelHidden(true)
                self.setXMarkEnabled(true)
            case .afterSkip:
                break
            }
        },
        onFullDurationFinish: {
            onFinish()
        })
    }
    
    private func reset() {
        onSkip = nil
        timer = nil
        setCountdownLabelHidden(true)
        setXMarkEnabled(false)
        resetStroke()
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
        animation.fromValue = 1.0
        animation.toValue = 0.0
        animation.duration = CFTimeInterval(duration)
        animation.fillMode = .forwards
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        animation.isRemovedOnCompletion = false
        
        strokeCircle.add(animation, forKey: C.strokeAnimationKey)
    }
    
    private func resetStroke() {
        strokeCircle.strokeEnd = 1.0
        strokeCircle.removeAnimation(forKey: C.strokeAnimationKey)
    }
    
    private func setCountdownLabelHidden(_ isHidden: Bool, animated: Bool = false) {
        countDownNumberLabel.isHidden = isHidden
    }
    
    private func setXMarkEnabled(_ isEnabled: Bool, animated: Bool = false) {
        xMarkImageView.isHidden = !isEnabled
        skipControl.isUserInteractionEnabled = isEnabled
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
    
    private func setup() {
        self.backgroundColor = .clear
        
        updateFilledCircleFrame()
        updateStrokeCircleFrame()
        
        countDownNumberLabel.isHidden = true
        skipControl.isUserInteractionEnabled = false
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
        layer.strokeEnd = 1.0
        layer.lineCap = .round
        layer.lineWidth = C.progressWidth
        self.layer.addSublayer(layer)
        return layer
    }()
    
    private lazy var countDownNumberLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 13)
        
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        
        NSLayoutConstraint.activate([
            label.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: 0.5, constant: 0),
            label.heightAnchor.constraint(equalTo: label.widthAnchor, multiplier: 1.0, constant: 0),
            label.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        ])
        
        return label
    }()
    
    private lazy var skipControl: UIControl = {
        let control = UIControl()
        
        control.translatesAutoresizingMaskIntoConstraints = false
        control.addTarget(self, action: #selector(skipTapped), for: .touchUpInside)
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
        let inset = C.progressInsets
        let layerFrame = filledCircle.bounds.insetBy(dx: inset, dy: inset)
        
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
    
    @objc
    private func skipTapped() {
        onSkip?()
    }
    
    private enum C {
        static let strokeAnimationKey = "strokeEnd"
        static let xMarkImageName = "x_mark_vector"
        static let circleFillColor = UIColor.black.withAlphaComponent(0.7).cgColor
        static let progressColor = UIColor.white.cgColor
        static let progressWidth: CGFloat = 3
        static let progressInsets: CGFloat = 4
    }
}

private class AdvertisementTimer {
    let advertDuration: Int
    let skipThreshold: Int
    
    init(advertDuration: Int, timeBeforeSkip: Int) {
        self.advertDuration = advertDuration
        self.skipThreshold = advertDuration - timeBeforeSkip
    }
    
    deinit {
        invalidateTimer()
    }
    
    private lazy var currentDuration: Int = advertDuration
    private weak var timer: Timer?
    
    enum TickType {
        case beforeSkip(timeLeft: Int)
        case reachedSkip(atTime: Int)
        case afterSkip(time: Int)
    }
    
    func startTimer(onTick: @escaping (TickType) -> Void,
                    onFullDurationFinish: @escaping  () -> Void) {
        invalidateTimer()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1,
                                     repeats: true,
                                     block: { [weak self] (timer) in
                                        guard let self = self else { return }
                                        self.currentDuration -= 1
                                        
                                        guard self.currentDuration > 0 else {
                                            self.reset()
                                            onFullDurationFinish()
                                            return
                                        }
                                        
                                        if self.currentDuration > self.skipThreshold {
                                            onTick(.beforeSkip(timeLeft: self.currentDuration))
                                        } else if self.currentDuration == self.skipThreshold  {
                                            onTick(.reachedSkip(atTime: self.currentDuration))
                                        } else {
                                            onTick(.afterSkip(time: self.currentDuration))
                                        }
                                     })
    }
    
    /// Return everting to the initial state and invalidate timer
    private func reset() {
        currentDuration = advertDuration
        invalidateTimer()
    }
    
    private func invalidateTimer() {
        timer?.invalidate()
        timer = nil
    }
}
