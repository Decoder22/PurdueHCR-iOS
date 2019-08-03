//
//  TypeSubmitView.swift
//  Platinum Points
//
//  Created by Brian Johncox on 6/30/18.
//  Copyright © 2018 DecodeProgramming. All rights reserved.
//

import UIKit
import ValueStepper
import Firebase

class TypeSubmitViewController: UIViewController, UITextViewDelegate {

    @IBOutlet var typeLabel: UILabel!
	@IBOutlet weak var nameLabel: UILabel!
	@IBOutlet var descriptionField: UITextView!
	@IBOutlet weak var houseImage: UIImageView!
	@IBOutlet weak var submitButton: UIButton!
	@IBOutlet weak var descriptionLabel: UILabel!
	@IBOutlet weak var datePicker: UIDatePicker!
	
	
    var type:PointType?
    var user:User?
	
	let placeholder = "Tell us what you did!"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        typeLabel.text? = type!.pointName
		descriptionLabel.text = type!.pointDescription
		let firstName = User.get(.firstName) as! String
		let lastName = User.get(.lastName) as! String
		nameLabel.text = firstName + " " + lastName
        //descriptionField.layer.borderColor = UIColor.black.cgColor
        //descriptionField.layer.borderWidth = 1
		descriptionField.layer.cornerRadius = 10
		descriptionField.text = placeholder
		descriptionField.textColor = UIColor.lightGray
		descriptionField.selectedTextRange = descriptionField.textRange(from: descriptionField.beginningOfDocument, to: descriptionField.beginningOfDocument)
		descriptionField.becomeFirstResponder()
		submitButton.layer.cornerRadius = 10
		
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard (_:)))
        self.view.addGestureRecognizer(tapGesture)
		let houseName = User.get(.house) as! String
		if(houseName == "Platinum"){
			houseImage.image = #imageLiteral(resourceName: "Platinum")
		}
		else if(houseName == "Copper"){
			houseImage.image = #imageLiteral(resourceName: "Copper")
		}
		else if(houseName == "Palladium"){
			houseImage.image = #imageLiteral(resourceName: "Palladium")
		}
		else if(houseName == "Silver"){
			houseImage.image = #imageLiteral(resourceName: "Silver")
		}
		else if(houseName == "Titanium"){
			houseImage.image = #imageLiteral(resourceName: "Titanium")
		}
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
	@IBAction func submit(_ sender: Any) {
        submitButton.isEnabled = false;
        guard let description = descriptionField.text, !description.isEmpty, !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else{
            notify(title: "Failure", subtitle: "Please enter a description", style: .danger)
            submitButton.isEnabled = true;
            return
        }
        guard let pointType = type else{
            notify(title: "Failure", subtitle: "Please reselect your point type", style: .danger)
            submitButton.isEnabled = true;
            return
        }
        if(description == placeholder){
            notify(title: "Failure", subtitle: "Please tell us more about what you did!", style: .danger)
            submitButton.isEnabled = true;
            return
        }
        submitPointLog(pointType: pointType, logDescription: description)
    }
    
    
    /// Submit Point Log to DataHandler. 
    ///
    /// - Parameters:
    ///   - pointType: Point Type to have a log created of
    ///   - descriptions: String text describing what the residents did
    func submitPointLog(pointType:PointType, logDescription:String){
		
		// TODO: Update reported time of point
		
		let firstName = User.get(.firstName) as! String
		let lastName = User.get(.lastName) as! String
        let preApproved = ((User.get(.permissionLevel) as! Int) == 1 )
        let floor = User.get(.floorID) as! String
        let residentRef = DataManager.sharedManager.getUserRefFromUserID(id: User.get(.id) as! String)
		let residentId = User.get(.id) as! String
		
		// TODO: FIX DIS CUZ IT PROBLY AINT RAIGHT
		datePicker.maximumDate = Date()
		let dateOccurred = Timestamp.init(date: datePicker.date)
        let pointLog = PointLog(pointDescription: logDescription, firstName: firstName, lastName: lastName, type: pointType, floorID: floor, residentRef:residentRef, residentId: residentId, dateOccurred: dateOccurred)
        DataManager.sharedManager.writePoints(log: pointLog, preApproved: preApproved) { (err:Error?) in
            if(err != nil){
                if(err!.localizedDescription == "The operation couldn’t be completed. (Could not submit points because point type is disabled. error 1.)"){
                    self.notify(title: "Failed to submit", subtitle: "Point Type is no longer enabled.", style: .danger)
                }
                else{
                    self.notify(title: "Failed to submit", subtitle: "Database Error.", style: .danger)
                    print("Error in posting: ",err!.localizedDescription)
                }
                
                self.submitButton.isEnabled = true;
                return
            }
            else{
                self.navigationController?.popViewController(animated: true)
                if(preApproved){
                    self.notify(title: "Way to Go RHP", subtitle: "Congrats, \(pointLog.type.pointValue) points submitted.", style: .success)
                }
                else{
                    self.notify(title: "Submitted for approval!", subtitle: pointLog.pointDescription, style: .success)
                }
            }
        }
    }

	func textViewDidChangeSelection(_ textView: UITextView) {
		if self.view.window != nil {
			if textView.textColor == UIColor.lightGray {
				textView.selectedTextRange = textView.textRange(from: textView.beginningOfDocument, to: textView.beginningOfDocument)
			}
		}
	}
	
	func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
		
		let currentText:String = textView.text
		let updatedText = (currentText as NSString).replacingCharacters(in: range, with: text)
		
		if updatedText.isEmpty {
			
			textView.text = placeholder
			textView.textColor = UIColor.lightGray
			
			textView.selectedTextRange = textView.textRange(from: textView.beginningOfDocument, to: textView.beginningOfDocument)
		}
			
		else if textView.textColor == UIColor.lightGray && !text.isEmpty {
			textView.textColor = UIColor.black
			textView.text = ""
		}

		return updatedText.count <= 240
	}
	
    @objc func dismissKeyboard (_ sender: UITapGestureRecognizer) {
        self.descriptionField.resignFirstResponder()
    }
/*    // MARK: - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
 // Get the new view controller using segue.destinationViewController.
 // Pass the selected object to the new view controller.
 }
 */
}
