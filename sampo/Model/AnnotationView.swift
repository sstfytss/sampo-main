//
//  AnnotationView.swift
//  sampo
//
//  Created by Shun Sakai on 5/30/21.
//

import Foundation
import UIKit
import HDAugmentedReality

protocol AnnotationViewDelegate {
    func didTouch(annotationView: AnnotationView)
}

class AnnotationView: ARAnnotationView{
    var titleLabel: UILabel?
    var distanceLabel: UILabel?
    var delegate: AnnotationViewDelegate?
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        loadUI()
    }
    
    override func layoutSubviews() {
      super.layoutSubviews()
      titleLabel?.frame = CGRect(x: 10, y: 0, width: self.frame.size.width, height: 30)
      distanceLabel?.frame = CGRect(x: 10, y: 30, width: self.frame.size.width, height: 20)
    }
      
    //2
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
      delegate?.didTouch(annotationView: self)
    }
    
    //4
    func loadUI() {
        titleLabel?.removeFromSuperview()
        distanceLabel?.removeFromSuperview()
        
        let label = UILabel(frame: CGRect(x: 10, y: 0, width: self.frame.size.width, height: 30))
        label.font = UIFont.systemFont(ofSize: 16)
        label.numberOfLines = 0
        label.backgroundColor = UIColor(white: 0.3, alpha: 0.7)
        label.textColor = UIColor.white
        self.addSubview(label)
        self.titleLabel = label
        
        distanceLabel = UILabel(frame: CGRect(x: 10, y: 30, width: self.frame.size.width, height: 20))
        distanceLabel?.backgroundColor = UIColor(white: 0.3, alpha: 0.7)
        distanceLabel?.textColor = UIColor.green
        distanceLabel?.font = UIFont.systemFont(ofSize: 12)
        self.addSubview(distanceLabel!)
        
        if let annotation = annotation as? Place {
            titleLabel?.text = "\(annotation.x) , \(annotation.y)"
            distanceLabel?.text = "distance"
        }
    }
}
