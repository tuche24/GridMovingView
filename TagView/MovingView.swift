import UIKit

protocol MovingViewDelegate: AnyObject {
    func tagViewDidMove(_ view: MovingView)
}

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
    
    private var snapPoints: [CGPoint] = []
    private var horizontalSnapCount = 4
    private var verticalSnapCount = 4
    
    var delegate: MovingViewDelegate?

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
        
        setupSnapPoints()
        setupGesture()
    }
    
    private func setupSnapPoints() {
        snapPoints.removeAll()
        let gridSize: CGFloat = 10.0
        
        for i in 0..<horizontalSnapCount {
            for j in 0..<verticalSnapCount {
                let x = CGFloat(i) * (frame.width + gridSize) + gridSize
                let y = CGFloat(j) * (frame.height + gridSize) + gridSize
                snapPoints.append(CGPoint(x: x, y: y))
            }
        }
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
            finishDrag()
        default:
            break
        }
    }
    
    private func updatePosition(with gesture: UILongPressGestureRecognizer) {
        let locationInSuperview = gesture.location(in: superview)
        frame.origin = CGPoint(x: locationInSuperview.x - dragStartLocation.x,
                                y: locationInSuperview.y - dragStartLocation.y)
    }
    
    private func finishDrag() {
        delegate?.tagViewDidMove(self)
        state = .ended
        
        if let closestSnapPoint = snapPoints.min(by: { distance($0, frame.origin) < distance($1, frame.origin) }) {
            UIView.animate(withDuration: 0.2) {
                self.frame.origin = closestSnapPoint
            }
        }
        
        DispatchQueue.main.async { [self] in
            if let superview = superview {
                for subview in superview.subviews {
                    if let tagView = subview as? MovingView, tagView != self, isOverlapping(with: tagView) {
                        UIView.animate(withDuration: 0.2) {
                            self.frame.origin = self.originalPosition
                        }
                    }
                }
            }
        }
    }
    
    private func distance(_ point1: CGPoint, _ point2: CGPoint) -> CGFloat {
        return sqrt(pow(point1.x - point2.x, 2) + pow(point1.y - point2.y, 2))
    }
    
    func isOverlapping(with other: MovingView) -> Bool {
        return frame.intersects(other.frame)
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
