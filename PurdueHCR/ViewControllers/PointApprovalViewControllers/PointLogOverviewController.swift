//
//  PointLogOverviewController.swift
//  Platinum Points
//
//  Created by Brian Johncox on 7/21/18.
//  Copyright © 2018 DecodeProgramming. All rights reserved.
//

import UIKit

class PointLogOverviewController: UIViewController {
    
	@IBOutlet weak var scrollView: UIScrollView!
	
	var indexPath : IndexPath?
	var approveButton : UIButton?
	var rejectButton : UIButton?
    
    var pointLog: PointLog?
    //var index: IndexPath?
    @IBOutlet var pointDescriptionView: PointDescriptionView!
	var preViewContr: RHPApprovalTableViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
		
		let radius : CGFloat = 10
		
		pointDescriptionView.setLog(pointLog: pointLog!)
		pointDescriptionView.layer.cornerRadius = radius
		let height : CGFloat = 60
		let width : CGFloat = (self.view.frame.width - 60) / 2
		let offset : CGFloat = 20
		let heightModifier = height + offset + (self.tabBarController?.tabBar.frame.height)!
		let x = 40 + width
		let y = self.view.frame.height - heightModifier
		let approveOrigin = CGPoint.init(x: x, y: y)
		let rejectOrigin = CGPoint.init(x: 20, y: y)
		let buttonSize = CGSize.init(width: width, height: height)
		
		approveButton = UIButton.init(type: .custom)
		approveButton?.frame = CGRect.init(origin: approveOrigin, size: buttonSize)
		rejectButton = UIButton.init(type: .custom)
		rejectButton?.frame = CGRect.init(origin: rejectOrigin, size: buttonSize)
		
		//approveButton?.setImage(#imageLiteral(resourceName: "approve"), for: .normal)
		approveButton?.setTitle("Approve", for: .normal)
		approveButton?.titleLabel?.font = UIFont.boldSystemFont(ofSize: 22)
		approveButton?.layer.cornerRadius = 10
		/*if #available(iOS 13, *) {
			approveButton?.backgroundColor = UIColor.get
		} else {
			
		}*/
		approveButton?.backgroundColor = UIColor.init(red: 52/255, green: 199/255, blue: 89/255, alpha: 1.00)
		approveButton?.addTarget(self, action: #selector(approvePointLog), for: .touchUpInside)
		
		//rejectButton?.setImage(#imageLiteral(resourceName: "reject"), for: .normal)
		rejectButton?.setTitle("Reject", for: .normal)
		rejectButton?.titleLabel?.font = UIFont.boldSystemFont(ofSize: 22)
		rejectButton?.layer.cornerRadius = 10
		rejectButton?.backgroundColor = UIColor.red
		rejectButton?.addTarget(self, action: #selector(rejectPointLog), for: .touchUpInside)
		
		self.view.addSubview(approveButton!)
		self.view.addSubview(rejectButton!)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
        // Dispose of any resources that can be recreated.
    }
    
    @objc func approvePointLog() {
        approveButton?.isEnabled = false
        //preViewContr?.displayedLogs.remove(at:index!.row)
		if (pointLog?.wasHandled == true) {
			if let pointSubmittedViewContr = (preViewContr as! PointsSubmittedViewController?) {
				pointSubmittedViewContr.updatePointLogStatus(log: pointLog!, approve: true, updating: true, indexPath: indexPath!)
			}
		} else {
			preViewContr?.updatePointLogStatus(log: pointLog!, approve: true, updating: false, indexPath: indexPath!)
		}
		
        self.navigationController?.popViewController(animated: true)
    }
	
    @objc func rejectPointLog() {
        rejectButton?.isEnabled = false
        //preViewContr?.displayedLogs.remove(at: index!.row)
		if (pointLog?.wasHandled == true) {
			if let pointSubmittedViewContr = (preViewContr as! PointsSubmittedViewController?) {
				pointSubmittedViewContr.updatePointLogStatus(log: pointLog!, approve: false, updating: true, indexPath: indexPath!)
			}
		} else {
			preViewContr?.updatePointLogStatus(log: pointLog!, approve: false, updating: false, indexPath: indexPath!)
		}
        self.navigationController?.popViewController(animated: true)
    }
    

}
