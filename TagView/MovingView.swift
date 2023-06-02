import UIKit

enum MovingViewState {
    case began
    case ended
}

class MovingView: UIView {
    
    var state: MovingViewState = .began {
        didSet {
            handleStateChange()
        }
    }
    
    private var dragStartLocation: CGPoint = .zero
    private var originalPosition: CGPoint = .zero
    private let dashedBorder = CAShapeLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }
    
    private func setupView() {
        layer.cornerRadius = 10
        
        setupGesture()
    }
    
    private func setupGesture() {
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        addGestureRecognizer(longPressGesture)
    }
    
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            state = .began
            dragStartLocation = gesture.location(in: self)
            originalPosition = frame.origin
        case .changed:
            updatePosition(with: gesture)
        case .ended, .cancelled:
            state = .ended
        default:
            break
        }
    }
    
    private func updatePosition(with gesture: UILongPressGestureRecognizer) {
        let locationInSuperview = gesture.location(in: superview)
        frame.origin = CGPoint(x: locationInSuperview.x - dragStartLocation.x,
                                y: locationInSuperview.y - dragStartLocation.y)
    }
    
    private func handleStateChange() {
        switch state {
        case .began:
            alpha = 0.5
            addDashedBorder()
        case .ended:
            alpha = 1.0
            removeDashedBorder()
        }
    }
    
    private func addDashedBorder() {
        let path = UIBezierPath(roundedRect: bounds, cornerRadius: layer.cornerRadius)
        dashedBorder.path = path.cgPath
        dashedBorder.fillColor = nil
        dashedBorder.strokeColor = UIColor.lightGray.cgColor
        dashedBorder.lineDashPattern = [4, 4]
        dashedBorder.lineWidth = 2
        layer.addSublayer(dashedBorder)
    }
    
    private func removeDashedBorder() {
        dashedBorder.removeFromSuperlayer()
    }
    
}
