//
//  ViewController.swift
//  DeclarativePageView
//
//  Created by Andrii Halushka on 20.11.2020.
//

import UIKit

let advDuration = 10

class ViewController: UIViewController {
    @IBOutlet weak var controllContainer: UIView!
    @IBOutlet weak var youCanTapLabel: UILabel!
    
    private lazy var circle: CircleStroker = {
        let circle = CircleStroker()
        circle.translatesAutoresizingMaskIntoConstraints = true
        circle.frame = controllContainer.bounds.inset(by: UIEdgeInsets(top:10, left: 10, bottom: 10, right: 10))
        controllContainer.addSubview(circle)
        
        return circle
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        controllContainer.backgroundColor = .black
        circle.addTarget(self, action: #selector(onSkip), for: .touchDown)
    }
    
    @IBAction func onStart(_ sender: Any) {
        removeSkippableLeftOvers()
        shadeBackground(false)
        startTimer()
        circle.render(.start(forDuration: advDuration))
    }
    
    @IBAction func onReset(_ sender: Any) {
        resetCircle()
        shadeBackground(false)
    }
    
    @objc
    private func onSkip(event: UIControl.Event) {
        print("\(#function)")
        youCanTapLabel.backgroundColor = .blue
    }
    
    // MARK: - Timer
    
    private weak var timer: Timer? {
        didSet {
            print("timer set \(timer)")
        }
    }
    private var counter = advDuration {
        didSet {
            print("\(counter)")
        }
    }
    private var skipThreshold = 5
    
    private func startTimer() {
        resetCircle()
        timer = Timer.scheduledTimer(withTimeInterval: 1,
                                     repeats: true,
                                     block: { [weak self] (timer) in
                                        guard let self = self else { return }
                                        self.counter -= 1
                                        
                                        guard self.counter > 0 else {
                                            self.resetCircle()
                                            self.shadeBackground(true)
                                            return
                                        }
                                        
                                        if self.counter > self.skipThreshold {
                                            self.circle.render(.update(time: self.counter))
                                        } else if self.counter == self.skipThreshold  {
                                            self.transitToSkippable()
                                        }
                                     })
    }
    
    private func resetCircle() {
        removeSkippableLeftOvers()
        timer?.invalidate()
        timer = nil
        counter = advDuration
        self.circle.render(.idle)
    }
    
    private func shadeBackground(_ flag: Bool) {
        if flag {
            UIView.animate(withDuration: 1) {
                self.view.backgroundColor = UIColor.red.withAlphaComponent(0.8)
            }
        } else {
            self.view.backgroundColor = .white
        }
    }
    
    private func transitToSkippable() {
        self.circle.render(.transitToSkippable)
        self.youCanTapLabel.isHidden = false
    }
    
    private func removeSkippableLeftOvers() {
        self.youCanTapLabel.isHidden = true
    }
}

// MARK: ----

class CircleStroker: UIView {
    
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
        layer.fillColor = .init(gray: 1, alpha: 0.7)
        layer.position = CGPoint(x: self.frame.midX, y: self.frame.midY)
        self.layer.addSublayer(layer)
        return layer
    }()
    
    private lazy var strokeCircle: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.fillColor = UIColor.clear.cgColor
        layer.strokeColor = UIColor.white.cgColor//CGColor(gray: 0.0, alpha: 1.0)
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
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        updateFilledCircleFrame()
        updateStrokeCircleFrame()
        _ = countDownNumberLabel
    }
    
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
        static let xMarkImageName = "x_mark_vector"
    }
}

// MARK: ----
