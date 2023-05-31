//
//  TagView.swift
//  TagView
//
//  Created by 이도영 on 2023/05/30.
//

import UIKit

enum TagViewState {
    case began
    case ended
}

protocol TagViewDelegate: AnyObject {
    func tagViewDidMove(_ view: TagView)
}

class TagView: UIView {
    
    var state: TagViewState = .began {
        didSet {
            handleStateChange()
        }
    }
    
    private var dragStartLocation: CGPoint = .zero
    private var originalPosition: CGPoint = .zero
    private let dashedBorder = CAShapeLayer()
    
    private var snapPoints: [CGPoint] = []
    var horizontalSnapCount = 0
    var verticalSnapCount = 0
    
    var delegate: TagViewDelegate?

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
        state = .began
        switch gesture.state {
        case .began:
            state = .began
            dragStartLocation = gesture.location(in: self)
            originalPosition = frame.origin
            
            setupSnapPoints()
        case .changed:
            updatePosition(with: gesture)
        case .ended, .cancelled:
            state = .ended
            finishDrag()
        default:
            break
        }
    }
    
    private func setupSnapPoints() {
        snapPoints.removeAll()
        let gridSize: CGFloat = 20.0
        
        for i in 0..<horizontalSnapCount {
            for j in 0..<verticalSnapCount + 1 { // 한 줄에서 2줄 이상 추가하기 위해 + 1 을 함
                let x = CGFloat(i) * (frame.width + gridSize) + gridSize
                let y = CGFloat(j) * (frame.height + gridSize) + gridSize
                snapPoints.append(CGPoint(x: x, y: y))
            }
        }
    }
    
    private func updatePosition(with gesture: UILongPressGestureRecognizer) {
        let locationInSuperview = gesture.location(in: superview)
                frame.origin = CGPoint(x: locationInSuperview.x - dragStartLocation.x,
                                        y: locationInSuperview.y - dragStartLocation.y)
    }
    
    private func finishDrag() {
        if let closestSnapPoint = snapPoints.min(by: { distance($0, frame.origin) < distance($1, frame.origin) }) {
            UIView.animate(withDuration: 0.2) {
                self.frame.origin = closestSnapPoint
            }
        }
        
        DispatchQueue.main.async { [self] in
            if let superview = superview as? UIScrollView {
                for subview in superview.subviews {
                    if let tagView = subview as? TagView, tagView != self, isOverlapping(with: tagView) {
                        frame.origin = originalPosition
                        delegate?.tagViewDidMove(self)
                        
                        state = .ended
                        return
                    }
                }
            }
            
            delegate?.tagViewDidMove(self)
            
            state = .ended
        }
        
    }
    
    private func distance(_ point1: CGPoint, _ point2: CGPoint) -> CGFloat {
        return sqrt(pow(point1.x - point2.x, 2) + pow(point1.y - point2.y, 2))
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
    
    func isOverlapping(with other: TagView) -> Bool {
        return frame.intersects(other.frame)
    }
    
}
