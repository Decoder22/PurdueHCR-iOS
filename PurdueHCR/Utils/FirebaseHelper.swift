//
//  FirebaseHelper.swift
//  Platinum Points
//
//  Created by Brian Johncox on 7/9/18.
//  Copyright © 2018 DecodeProgramming. All rights reserved.
//

import Foundation
import Firebase


class FirebaseHelper {
    
    let db: Firestore
    let storage: Storage
    let FIRST_NAME = "FirstName"
	let LAST_NAME = "LastName"
    let PERMISSION_LEVEL = "Permission Level"
    let HOUSE = "House"
    let POINTS = "Points"
    let USERS = "Users"
    let TOTAL_POINTS = "TotalPoints"
    let FLOOR_ID = "FloorID"
    
    init(){
        db = Firestore.firestore()
        storage = Storage.storage()
        let settings = db.settings
        settings.areTimestampsInSnapshotsEnabled = true
        db.settings = settings
    }
    
    //assume that user is saved in cely
    func createUser(onDone:@escaping (_ err: Error?) -> Void){
        let userRef = db.collection("Users").document(User.get(.id) as! String)
        userRef.setData([
            self.FIRST_NAME: User.get(.firstName)!,
			self.LAST_NAME: User.get(.lastName)!,
            self.PERMISSION_LEVEL: User.get(.permissionLevel)! as! Int,
            self.HOUSE:User.get(.house)!,
            self.FLOOR_ID:User.get(.floorID)!,
            self.TOTAL_POINTS:0
        ]){ err in
            onDone(err)
        }
    }
    
    func retrievePointTypes(onDone:@escaping ([PointType])->Void) {
        self.db.collection("PointTypes").getDocuments() { (querySnapshot, err) in
            var pointArray = [PointType]()
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                for pointDocument in querySnapshot!.documents
                {
                    let id = Int(pointDocument.documentID)!
                    let description = pointDocument.data()["Description"] as! String
                    let residentSubmit = pointDocument.data()["ResidentsCanSubmit"] as! Bool
                    let value = pointDocument.data()["Value"] as! Int
                    let permissionLevel = pointDocument.data()["PermissionLevel"] as! Int
                    let isEnabled = pointDocument.data()["Enabled"] as! Bool
					// TODO: Update pn field
					pointArray.append(PointType(pv: value, pn: "", pd: description , rcs: residentSubmit, pid: id, permissionLevel: permissionLevel, isEnabled:isEnabled))
                }
                pointArray.sort(by: {
                    if($0.pointValue == $1.pointValue){
                        return $0.pointID < $1.pointID
                    }
                    else{
                        return $0.pointValue < $1.pointValue
                    }
                    
                })
                onDone(pointArray)
            }
        }
    }
    
    func getUserWhenLogIn(id:String, onDone:@escaping (_ success:Bool)->Void){
        let userRef = db.collection("Users").document(id)
        
        userRef.getDocument { (document, error) in
            if let document = document, document.exists {
                let permissionLevel = document.data()![self.PERMISSION_LEVEL] as! Int
                User.save(permissionLevel as Any, as: .permissionLevel)
                User.save(document.data()![self.FIRST_NAME] as Any, as: .firstName)
				User.save(document.data()![self.LAST_NAME] as Any, as: .lastName)
                if(permissionLevel == 2){ // check if REA/REC
                    
                }
                else{
                    User.save(document.data()![self.HOUSE] as Any, as: .house)
                    User.save(document.data()![self.FLOOR_ID] as Any, as: .floorID)
                    //User.save((document.data()![self.PERMISSION_LEVEL] as! Int) as Any, as: .permissionLevel)
                    User.save(document.data()![self.TOTAL_POINTS] as Any, as: .points)
                }
                onDone(true)
            } else {
                print("Document does not exist")
                onDone(false)
            }
        }
    }
    

    /// Adds Point Log submission to the Database
    ///
    /// - Parameters:
    ///   - log: Point Log that is to be added to the database
    ///   - documentID: specified id for Point Log in the database (Used for Single Use Qr codes)
    ///   - preApproved: Boolean that denotes whether the Log can skip RHP approval or not.
    ///   - house: If the house is different than the saved house for the user (Used for REC Awarding points)
    ///   - isRECGrantingAward: Boolean to denote that this point is being added by the RHP
    ///   - onDone: Closure function the be called once the code hits an error or finishs. err is nil if no errors are found.
    func addPointLog(log:PointLog, documentID:String = "",preApproved:Bool = false, house:String = (User.get(.house) as! String), isRECGrantingAward:Bool = false, onDone:@escaping (_ err:Error?)->Void){
        var ref: DocumentReference? = nil
        //If point type is disabled and it is not an REC granting an award, warn that it is disabled
        if(!log.type.isEnabled && !isRECGrantingAward){
            onDone(NSError(domain: "Could not submit points because point type is disabled.", code: 1, userInfo: nil))
            return
        }
        //If the log is preapproved, update the approval status
        if(preApproved){
            log.updateApprovalStatus(approved: preApproved, preapproved: preApproved)
        }
        
        if(documentID == "" )
        {
            // write the document to the HOUSE table and save the reference
            ref = self.db.collection(self.HOUSE).document(house).collection(self.POINTS).addDocument(data: log.convertToDict()){ err in
                if ( err == nil){
                    //add a document to the table for the user with the reference to the point
                    log.residentRef.collection("Points").document(ref!.documentID).setData(["Point":ref!])
                    {err in
                        if(err == nil && preApproved)
                        {
                            self.updateHouseAndUserPoints(log: log, userRef: log.residentRef, houseRef: self.db.collection(self.HOUSE).document(house), isRECGrantingAward:isRECGrantingAward, updatePointValue: false, onDone: onDone)
                        }
                        else{
                            onDone(err)
                        }
                    }
                }
                else{
                    onDone(err)
                }
            }
        }
        else
        {
            //Adding a point with a specific Document ID
            ref = self.db.collection(self.HOUSE).document(house).collection(self.POINTS).document(log.residentRef.documentID+documentID)
            ref!.getDocument { (document, error) in
                if let document = document, document.exists {
                    onDone(NSError(domain: "Document Exists", code: 1, userInfo: nil))
                } else {
                    ref!.setData(log.convertToDict()){ err in
                        if ( err == nil){
                            //add a document to the table for the user with the reference to the point
                            log.residentRef.collection("Points").document(ref!.documentID).setData(["Point":ref!])
                            {err in
                                if(err == nil && preApproved)
                                {
                                    self.updateHouseAndUserPoints(log: log, userRef: log.residentRef, houseRef: self.db.collection(self.HOUSE).document(house), isRECGrantingAward:isRECGrantingAward, updatePointValue: false, onDone: onDone)
                                }
                                else{
                                    onDone(err)
                                }
                            }
                        }
                        else{
                            onDone(err)
                        }
                    }
                }
            }
        }
    }
    
    /// update the status of the point log if it has been approved, rejected, or updated
    ///
    /// - Parameters:
    ///   - log: Log that is being updated
    ///   - approved: BOOL: Approved (true) rejected(false)
    ///   - updating: Bool: If the log has already been approved or rejected, and you are changing that status, set updating to true
    ///   - onDone: Closure to handle when the function is finished or if there is an error
    func updatePointLogStatus(log:PointLog, approved:Bool, updating:Bool = false, onDone:@escaping (_ err:Error?)->Void){
        //TODO While User.get(house) will work for now, look at doing this a better way
        let house = User.get(.house) as! String
        var housePointRef: DocumentReference?
        var houseRef:DocumentReference?
        var userRef:DocumentReference?
        houseRef = self.db.collection(self.HOUSE).document(house)
        housePointRef = houseRef!.collection(self.POINTS).document(log.logID!)
        userRef = log.residentRef
        log.updateApprovalStatus(approved: approved)
        //TODO: yes this is not entirely thread safe. If some future developer would be so kind as to make this more robust, this would be great
        //Note: The race conditions only happens with Firebase rn, so if in the future we switch to a different database solution, this may no longer be an issue
        housePointRef!.getDocument { (document, error) in
            //make sure that the document exists
            if let document = document, document.exists {
                let oldPointLog = PointLog(id: document.documentID, document: document.data()!)
                //If this is the first handling of this log, check to make sure it was not already approved.
                if(!updating && oldPointLog.wasHandled){
                    // someone has already handled it :(
                    onDone(NSError(domain: "Point request has already been handled", code: 1, userInfo: nil))
                    
                }
                else{
                    //It has either not been approved yet or is being updated, so you are good to go
                    //First we check if it is being updated and the old status equals the new status
                    if(updating && (log.wasRejected() == oldPointLog.wasRejected())){
                        onDone(NSError(domain: "Point request was already changed.", code: 1, userInfo: nil))
                    }
                    else{
                        //Conditions are met for point updating
                        housePointRef!.setData(log.convertToDict(),merge:true){err in
                            //if approved or update, update total points
                            if((approved || updating) && err == nil){
                                self.updateHouseAndUserPoints(log: log, userRef: userRef!, houseRef: houseRef!, updatePointValue: updating, onDone: {(err:Error?) in
                                    onDone(err)
                                })
                            }
                            else{
                                onDone(err)
                            }
                        }
                    }
                }
            } else {
                onDone(NSError(domain: "Document does not exist", code: 2, userInfo: nil))
            }
        }
        
        
    }
	
	/// Retrives the points that have been previously resolved
	///
	/// - Parameter onDone: returns pointLogs
	func getResolvedPoints(onDone: @escaping ( _ pointLogs:[PointLog])->Void) {
		let house = User.get(.house) as! String
		let docRef = db.collection(self.HOUSE).document(house).collection(self.POINTS)
		let userFloorID = User.get(.floorID) as! String
		
		docRef.whereField("PointTypeID", isGreaterThan: 0).getDocuments() { (querySnapshot, error) in
			if error != nil {
				print("Error getting documents: \(String(describing: error))")
				return
			}
			var pointLogs = [PointLog]()
			for document in querySnapshot!.documents {
				let floorID = document.data()["FloorID"] as! String
				// The reason I check this here instead of in the query is because Firestore does not support,
				// at the time of writing, the ability to query the data on more than one field. :(
				if(userFloorID == "6N" || userFloorID == "6S"){
					var otherCode = "6N"
					if(userFloorID == "6N"){
						otherCode = "6S"
					}
					if(floorID != otherCode){
						let id = document.documentID
						let pointLog = PointLog(id: id, document: document.data())
						pointLogs.append(pointLog)
					}
				}
				else{
					if(floorID == userFloorID){
						let id = document.documentID
						let pointLog = PointLog(id: id, document: document.data())
						pointLogs.append(pointLog)
					}
				}
			}
			onDone(pointLogs)
		}
	}
	
    func getUnconfirmedPoints(onDone:@escaping ( _ pointLogs:[PointLog])->Void) {
        let house = User.get(.house) as! String
        let docRef = db.collection(self.HOUSE).document(house).collection(self.POINTS)
        let userFloorID = User.get(.floorID) as! String
        
        docRef.whereField("PointTypeID", isLessThan: 0).getDocuments() { (querySnapshot, error) in
                if error != nil {
                    print("Error getting documents: \(String(describing: error))")
                    return
                }
                var pointLogs = [PointLog]()
                for document in querySnapshot!.documents {
                    let floorID = document.data()["FloorID"] as! String
                    // The reason I check this here instead of in the query is because Firestore does not support,
                    // at the time of writing, the ability to query the data on more than one field. :(
                    if(userFloorID == "6N" || userFloorID == "6S"){
                        var otherCode = "6N"
                        if(userFloorID == "6N"){
                            otherCode = "6S"
                        }
                        if(floorID != otherCode){
                            let id = document.documentID
                            let pointLog = PointLog(id: id, document: document.data())
                            pointLogs.append(pointLog)
                        }
                    }
                    else{
                        if(floorID == userFloorID){
                            let id = document.documentID
                            let pointLog = PointLog(id: id, document: document.data())
                            pointLogs.append(pointLog)
                        }
                    }
                }
                onDone(pointLogs)
        }
    }
    
    func refreshUserInformation(onDone:@escaping (_ err:Error?)->Void){
        let userRef = self.db.collection(self.USERS).document(User.get(.id) as! String)
        userRef.getDocument { (document, error) in
            if let document = document, document.exists {
                User.save(document.data()![self.HOUSE] as Any, as: .house)
                User.save(document.data()![self.FLOOR_ID] as Any, as: .floorID)
                User.save(document.data()![self.FIRST_NAME] as Any, as: .firstName)
				User.save(document.data()![self.LAST_NAME] as Any, as: .lastName)
                User.save(document.data()![self.PERMISSION_LEVEL] as Any, as: .permissionLevel)
                User.save(document.data()![self.TOTAL_POINTS] as Any, as: .points)
                onDone(error)
            } else {
                print("Document does not exist")
                onDone(error)
            }
        }
    }
    
    func refreshHouseInformation(onDone:@escaping ( _ houses:[House],_ code:[HouseCode])->Void){
        let houseRef = self.db.collection(self.HOUSE)
        houseRef.getDocuments() { (querySnapshot, err) in
            var houseArray = [House]()
            var houseKeys = [HouseCode]()
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                for houseDocument in querySnapshot!.documents
                {
                    let points = houseDocument.data()[self.TOTAL_POINTS] as! Int
                    let hex = houseDocument.data()["Color"] as! String
                    let numberOfResidents = houseDocument.data()["NumberOfResidents"] as! Int
                    let id = houseDocument.documentID
                    
                    for key in houseDocument.data().keys
                    {
                        if(key.contains("Code"))
                        {
                            print("Append code: \(key)")
                            let floorID = key.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: true)[0]
                            let houseCode = houseDocument.data()[key] as! String
                            houseKeys.append(HouseCode(code: houseCode, house: id, floorID:String(floorID)))
                        }
                    }
                    houseArray.append(House(id: id, points: points, hexColor:hex, numberOfResidents:numberOfResidents))
                }
                houseArray.sort(by: {$0.totalPoints > $1.totalPoints})
                onDone(houseArray, houseKeys)
            }
        }
    }
    
    func refreshRewards(onDone:@escaping (_ rewards:[Reward])->Void ){
        self.db.collection("Rewards").getDocuments(){ (querySnapshot, err) in
            var rewardArray = [Reward]()
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                for rewardDocument in querySnapshot!.documents
                {
                    let requiredPoints = rewardDocument.data()["RequiredValue"] as! Int
                    let fileName = rewardDocument.data()["FileName"] as! String
                    let name = rewardDocument.documentID
                    rewardArray.append(Reward(requiredValue: requiredPoints, fileName: fileName, rewardName: name))
                }
                rewardArray.sort(by: {$0.requiredValue < $1.requiredValue})
                onDone(rewardArray)
            }
        }
    }
    
    func retrievePictureFromFilename(filename:String,onDone:@escaping ( _ image:UIImage) ->Void ){
        let pathReference = storage.reference(withPath: filename)
        // Download in memory with a maximum allowed size of 100MB (100 * 1024 * 1024 bytes)
        pathReference.getData(maxSize: 20 * 1024 * 1024) { data, error in
            if let error = error {
                // Uh-oh, an error occurred!
                print(error.localizedDescription)
            } else {
                // Data for filename is returned
                onDone(UIImage(data: data!)!)
            }
        }
    }
    
    func getDocumentReferenceFromID(id:String) -> DocumentReference {
        return db.collection(self.USERS).document(id)
        
    }
    
    func findLinkWithID(id:String, onDone:@escaping (_ link:Link?)->Void){
        let linkRef = db.collection("Links").document(id)
        linkRef.getDocument { (document, error) in
            if let document = document, document.exists {
                let descr = document.data()!["Description"] as! String
                let single = document.data()!["SingleUse"] as! Bool
                let pointID = document.data()!["PointID"] as! Int
                let enabled = document.data()!["Enabled"] as! Bool
                let archived = document.data()!["Archived"] as! Bool
                let link = Link(id: id, description: descr, singleUse: single, pointTypeID: pointID,enabled:enabled,archived:archived)
                onDone(link)
            } else {
                print("Document does not exist")
                onDone(nil)
            }
        }
    }
    
    /// Helper function to updateUserPoints
    ///
    /// - Parameters:
    ///   - log: Log to be saved
    ///   - userRef: DocumentReference for firebase user
    ///   - updatePointValue: Bool for if the point is being update. Set this to false if this log has not been previously approved or rejected
    ///   - onDone: Closure to run when the function is finished or errors
    private func updateUserPoints(log:PointLog, userRef:DocumentReference, updatePointValue:Bool, onDone:@escaping (_ err:Error?)->Void) {
        //Start Firebase Transaction - Used to prevent concurrency issues when updating a value
        db.runTransaction({ (transaction, errorPointer) -> Any? in
            //Get the old user document
            let userDocument: DocumentSnapshot
            do {
                try userDocument = transaction.getDocument(userRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }
            //Get the value of the old points total for the user
            guard let oldTotal = userDocument.data()?["TotalPoints"] as? Int else {
                let error = NSError(
                    domain: "AppErrorDomain",
                    code: -1,
                    userInfo: [
                        NSLocalizedDescriptionKey: "Unable to retrieve TotalPoints from snapshot \(userDocument)"
                    ]
                )
                errorPointer?.pointee = error
                return nil
            }
            //Update the value
            var newTotal = oldTotal
            if(updatePointValue){
                if(log.wasRejected()){
                    newTotal -= log.type.pointValue // if log is being updated and is rejected, subtract points
                }
                else{
                    newTotal += log.type.pointValue // if log is being updated and it is approved, add points
                }
            }
            else{
                newTotal += log.type.pointValue // If this is the first time being updated, add points
            }
            //Complete transaction update
            transaction.updateData(["TotalPoints": newTotal], forDocument: userRef)
            return nil
        })
        { (object, error) in
            //handle errors
            if let error = error {
                print("Transaction failed: \(error)")
                onDone(error)
            } else {
                print("Transaction successfully committed!")
                onDone(nil)
            }
        }
    }
    
    /// Helper function that contains the code that will actually update the House's points
    ///
    /// - Parameters:
    ///   - log: PointLog that is being handled/Updated
    ///   - houseRef: DocumentReference that points to house in Firebase
    ///   - updatePointValue: Bool if the pointlog is being updated after already being approved/rejected
    ///   - onDone: Closure to handle what to do when the function is finished or if there was an error
    private func updateHousePoints(log:PointLog, houseRef:DocumentReference, updatePointValue:Bool, onDone:@escaping (_ err:Error?)->Void)
    {
        //Transaction allows multiple firebase calls to occur without fear of concurrency issues
        db.runTransaction({ (transaction, errorPointer) -> Any? in
            //Get the House Document from firebase
            let houseDocument: DocumentSnapshot
            do {
                try houseDocument = transaction.getDocument(houseRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }
            //Get the Total Points number from the object
            guard let oldTotal = houseDocument.data()?["TotalPoints"] as? Int else {
                let error = NSError(
                    domain: "AppErrorDomain",
                    code: -1,
                    userInfo: [
                        NSLocalizedDescriptionKey: "Unable to retrieve TotalPoints from snapshot \(houseDocument)"
                    ]
                )
                errorPointer?.pointee = error
                return nil
            }
            
            //Update a local value with the correct point value
            var newTotal = oldTotal
            if(updatePointValue){ //If log was already approved/rejected and the status has been changed
                if(log.wasRejected()){
                    newTotal -= log.type.pointValue //If log was approved but is now rejected, remove points
                }
                else{
                    newTotal += log.type.pointValue // If log was rejected but is now approved, add points
                }
            }
            else{
                newTotal += log.type.pointValue //If log has not been handled yet, then add the points.
                //NOTE: because the log had to be either updating or approved to call this function,
                //      we do not need to check for the log not being approved
            }
            
            //Update Firebase with new value
            transaction.updateData(["TotalPoints": newTotal], forDocument: houseRef)
            return nil
        }){ (object, error) in
            //Error Handling
            if let error = error {
                print("Transaction failed: \(error)")
                onDone(error)
            } else {
                print("Transaction successfully committed!")
                onDone(nil)
            }
        }
    }
    
    /// Private helper function that will handle the updating of the house points for House and User in firebase
    /// Note this will need to be changed when we switch to API and MySQL database
    ///
    /// - Parameters:
    ///   - log: Point Log that contains points to be given to House and Resident
    ///   - userRef: Reference to the User in Firebase that needs to be awarded points
    ///   - houseRef: Reference to the house that will be given the points
    ///   - isRECGrantingAward: Boolean (defaults to false) true if REC is giving award to entire house
    ///   - updatePointValue: Boolean if this point is being updated. Make this true if log was already approved or disapproved, and this is an update to its status that requires its point value be changed.
    ///   - onDone: Closure function to be called on completion. Err is nil if no errors are thrown.
    private func updateHouseAndUserPoints(log:PointLog,userRef:DocumentReference,houseRef:DocumentReference, isRECGrantingAward:Bool = false, updatePointValue:Bool, onDone:@escaping (_ err:Error?)->Void)
    {
        updateHousePoints(log: log, houseRef: houseRef,updatePointValue: updatePointValue , onDone: {(err:Error?)in
            if(err != nil){
                onDone(err)
            }
            //If REC is giving award to House, dont give the points to a specific user
            else if(!isRECGrantingAward){
                self.updateUserPoints(log: log, userRef: userRef, updatePointValue: updatePointValue, onDone: {(errDeep:Error?) in
                    onDone(errDeep)
                })
            }
            else{
                onDone(nil)
            }
        })
    }
    
    func createQRCode(link:Link,onDone:@escaping ( _ id:String?) -> Void){
        let ref = db.collection("Links")
        var linkID:DocumentReference?
        linkID = ref.addDocument(data: [
            "Description":link.description,
            "PointID":link.pointTypeID,
            "SingleUse":link.singleUse,
            "CreatorID":User.get(.id) as! String,
            "Enabled":link.enabled,
            "Archived":link.archived])
        {err in
            if(err == nil){
                onDone(linkID?.documentID)
            }
            else{
                onDone(nil)
            }
        }
    }
    
    func getQRCodeFor(ownerID:String,withCompletion onDone:@escaping ( _ links:[Link]?)->Void){
        db.collection("Links").whereField("CreatorID", isEqualTo: ownerID).getDocuments()
            { (querySnapshot, error) in
                if error != nil {
                    print("Error getting documenbts: \(String(describing: error))")
                    onDone(nil)
                }
                var links = [Link]()
                for document in querySnapshot!.documents {
                    let id = document.documentID
                    let descr = document.data()["Description"] as! String
                    let single = document.data()["SingleUse"] as! Bool
                    let pointID = document.data()["PointID"] as! Int
                    let enabled = document.data()["Enabled"] as! Bool
                    let archived = document.data()["Archived"] as! Bool
                    let link = Link(id: id, description: descr, singleUse: single, pointTypeID: pointID, enabled:enabled, archived:archived)
                    links.append(link)
                }
                onDone(links)
            }
    }
    
    func setLinkActivation(link:Link, withCompletion onDone:@escaping ( _ err:Error?) ->Void){
        db.collection("Links").document(link.id).updateData(["Enabled":link.enabled]){err in
            onDone(err)
        }
    }
    
    func setLinkArchived(link:Link, withCompletion onDone:@escaping ( _ err:Error?) ->Void){
        db.collection("Links").document(link.id).updateData(["Archived":link.archived]){err in
            onDone(err)
        }
    }
    
    func getAllPointLogsForHouse(house:String, onDone:@escaping (([PointLog]) -> Void)){
        let docRef = db.collection(self.HOUSE).document(house).collection(self.POINTS)
        
        docRef.getDocuments()
            { (querySnapshot, error) in
                if (error != nil) {
                    print("Error getting documents: \(String(describing: error))")
                    return
                }
                var pointLogs = [PointLog]()
                for document in querySnapshot!.documents {
                    let floorID = document.data()["FloorID"] as! String
                    let id = document.documentID
                    let description = document.data()["Description"] as! String
                    let idType = (document.data()["PointTypeID"] as! Int)
					let resident = document.data()["Resident"]
					var name = ""
					if (resident == nil) {
						let first = document.data()["ResidentFirstName"] as! String
						let last = document.data()["ResidentLastName"] as! String
						name = first + last
					} else {
						name = resident as! String
					}
                    if(floorID == "Shreve"){
                        name = "(Shreve) " + name
                    }
                    let residentRefMaybe = document.data()["ResidentRef"]
                    var residentRef = self.db.collection(self.USERS).document("ypT6K68t75hqX6OubFO0HBBTHoy1") // Hard code a ref for when a code doesnt have one. (IE points were Given by REC to no specific user)
                    if(residentRefMaybe != nil ){
                        residentRef = residentRefMaybe as! DocumentReference
                    }
                    let pointType = DataManager.sharedManager.getPointType(value: idType)
                    let pointLog = PointLog(pointDescription: description, resident: name, type: pointType, floorID: floorID, residentRef:residentRef)
                    pointLog.logID = id
                    pointLogs.append(pointLog)
                }
                onDone(pointLogs)
        }
    }
	
	func getAllPointLogsForUser(residentID:String, house:String, onDone:@escaping (([PointLog]) -> Void)){
		let docRef = db.collection(self.HOUSE).document(house).collection(self.POINTS)
		
		docRef.getDocuments()
			{ (querySnapshot, error) in
				if (error != nil) {
					print("Error getting documents: \(String(describing: error))")
					return
				}
				var pointLogs = [PointLog]()
				for document in querySnapshot!.documents {
					let ID = document.data()["ResidentId"]
					if (ID != nil) {
						let resID = ID as! String
						if (resID == residentID) {
							let floorID = document.data()["FloorID"] as! String
							let id = document.documentID
							let description = document.data()["Description"] as! String
							let idType = (document.data()["PointTypeID"] as! Int)
							var name = ""
							let first = document.data()["ResidentFirstName"] as! String
							let last = document.data()["ResidentLastName"] as! String
							name = first + last
							if(floorID == "Shreve"){
								name = "(Shreve) " + name
							}
							let residentRefMaybe = document.data()["ResidentRef"]
							var residentRef = self.db.collection(self.USERS).document("ypT6K68t75hqX6OubFO0HBBTHoy1") // Hard code a ref for when a code doesnt have one. (IE points were Given by REC to no specific user)
							if(residentRefMaybe != nil ){
								residentRef = residentRefMaybe as! DocumentReference
							}
							let pointType = DataManager.sharedManager.getPointType(value: idType)
							let pointLog = PointLog(pointDescription: description, resident: name, type: pointType, floorID: floorID, residentRef:residentRef)
							pointLog.logID = id
							pointLogs.append(pointLog)
						}
					}
				}
				onDone(pointLogs)
		}
	}
    
    func addPointType(pointType:PointType, onDone:@escaping (_ err:Error?)-> Void){
        let highestId = DataManager.sharedManager.getPoints()!.count + 1 // This has the potential for a race condition but oh well
        //Adding a point with a specific Document ID
        let ref = self.db.collection("PointTypes").document(highestId.description)
        ref.getDocument { (document, error) in
            if let document = document, document.exists {
                onDone(NSError(domain: "Document Exists", code: 1, userInfo: nil))
            } else {
                ref.setData([
                    "Description" : pointType.pointDescription,
                    "PermissionLevel" : pointType.permissionLevel,
                    "ResidentsCanSubmit"    : pointType.residentCanSubmit,
                    "Value"  : pointType.pointValue,
                    "Enabled" : pointType.isEnabled
                ]){ err in
                    onDone(err)
                }
            }
        }
    }
    
    func updatePointType(pointType:PointType, onDone:@escaping (_ err:Error?)-> Void){
        //Adding a point with a specific Document ID
        let ref = self.db.collection("PointTypes").document(pointType.pointID.description)
        ref.getDocument { (document, error) in
            if let document = document, document.exists {
                ref.setData([
                    "Description" : pointType.pointDescription,
                    "PermissionLevel" : pointType.permissionLevel,
                    "ResidentsCanSubmit"    : pointType.residentCanSubmit,
                    "Value"  : pointType.pointValue,
                    "Enabled" : pointType.isEnabled
                ]){ err in
                    onDone(err)
                }
            } else {
                onDone(NSError(domain: "Document does not exist", code: 1, userInfo: nil))
            }
        }
    }
    
    func getTopScorersForHouse(house:String, onDone:@escaping ([UserModel]) -> Void){
        let collectionRef = db.collection(self.USERS)
        collectionRef.whereField("House", isEqualTo: house).getDocuments { (querySnapshot, error) in
            if error != nil {
                print("Error getting documents For House: \(String(describing: error))")
                return
            }
            var users = [UserModel]()
            for document in querySnapshot!.documents{
                let name = document.data()["Name"] as! String
                let points = document.data()["TotalPoints"] as! Int
                let model = UserModel(name: name, points: points)
                if(users.count < 5){
                    users.append(model)
                    users.sort(by: { (um, um2) -> Bool in
                        return um.totalPoints > um2.totalPoints
                    })
                }
                else{
                    for i in 0..<5{
                        if(users[i].totalPoints < model.totalPoints){
                            users.insert(model, at: i)
                            users.remove(at: 5)
                            break;
                        }
                    }
                }
                
                
            }
            onDone(users)
        }
    }
    
    func deleteReward(reward:Reward, onDone:@escaping (_ err:Error?) -> Void){
        var ref: DocumentReference? = nil
        ref = self.db.collection("Rewards").document(reward.rewardName)
        ref!.delete { (error) in
            onDone(error)
        }
    }
    
    func deletePictureWithFilename(filename:String,onDone:@escaping ( _ err:Error?) ->Void ){
        let pathReference = storage.reference(withPath: filename)
        pathReference.delete { (error) in
            onDone(error)
        }
    }
    
    func uploadImageWithFilename(filename:String,img:UIImage, onDone:@escaping (_ err:Error?)->Void){
        let ref = self.storage.reference().child(filename)
        let data = img.pngData()!
        print("DATA SIZE: ",data.count)
        if(data.count > 20 * 1024 * 1024){
            onDone(NSError(domain: "Image is too large", code: 1, userInfo: nil))
        }
        else{
            ref.putData(data, metadata: nil) { (storage, error) in
                onDone(error)
            }
        }
        
    }
    
    func createReward(reward:Reward, onDone:@escaping (_ err:Error?)->Void){
        var ref: DocumentReference? = nil
        ref = self.db.collection("Rewards").document(reward.rewardName)
        ref!.getDocument { (document, error) in
            if let document = document, document.exists {
                onDone(NSError(domain: "Document Exists", code: 1, userInfo: nil))
            } else {
                ref!.setData([
                    "FileName" : reward.fileName,
                    "RequiredValue" : reward.requiredValue
                ]){ err in
                    onDone(err)
                }
            }
        }
    }
	
	/// Retrieves the system preferences for the app
	///
	/// - Parameter onDone: returns the system preferences that were retrieved
	func getSystemPreferences(onDone: @escaping (_ sysPref:SystemPreferences?)->Void) {
		let ref: DocumentReference? = self.db.collection("SystemPreferences").document("Preferences")
		ref?.getDocument { (document, error) in
			if let document = document, document.exists {
				let isHouseEnabled = document.data()!["isHouseEnabled"] as! Bool
				let houseEnabledMessage = document.data()!["houseEnabledMessage"] as! String
				let systemPreferences = SystemPreferences(isHouseEnabled: isHouseEnabled, houseEnabledMessage: houseEnabledMessage)
				onDone(systemPreferences)
			} else {
				print("Error: Unabled to retrieve SystemPreferences information")
				onDone(nil)
			}
		}
	}
	
	/// Update System Preferences in Firebase
	///
	/// - Parameters:
	///   - systemPreferences: The updated local system preferences
	///   - onDone: Closure to handle error
	func updateSystemPreferences(systemPreferences: SystemPreferences, withCompletion onDone:@escaping ( _ err:Error?) ->Void){
		db.collection("SystemPreferences").document("Preferences").updateData(systemPreferences.convertToDictionary()){err in
			onDone(err)
		}
	}

}

