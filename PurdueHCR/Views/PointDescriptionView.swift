//
//  PointDescriptionView.swift
//  Platinum Points
//
//  Created by Brian Johncox on 7/26/18.
//  Copyright © 2018 DecodeProgramming. All rights reserved.
//

import UIKit

class PointDescriptionView: UIView {
    @IBOutlet var residentLabel: UILabel!
    @IBOutlet var pointTypeDescriptionLabel: UILabel!
    @IBOutlet var descriptionLabel: UILabel!
    @IBOutlet var backgroundView: UIView!
	@IBOutlet weak var icon: UIImageView!
	
    
    override init(frame: CGRect){
        super.init(frame: frame)
        commonInit()
    }
    
    required init(coder aDecoder: NSCoder){
        super.init(coder: aDecoder)!
        commonInit()
    }
    
    private func commonInit(){
        Bundle.main.loadNibNamed("PointDescriptionView", owner: self, options: nil)
        addSubview(backgroundView)
        backgroundView.frame = self.bounds
		self.backgroundView.layer.cornerRadius = 10
        backgroundView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
		icon.backgroundColor = UIColor.blue
		icon.layer.cornerRadius = icon.layer.frame.height / 2 
    }
    
    func setLog(pointLog:PointLog) {
        residentLabel.text = pointLog.firstName + " " + pointLog.lastName
        pointTypeDescriptionLabel.text = pointLog.type.pointDescription
        descriptionLabel.text = pointLog.pointDescription
    }
    

    
}
