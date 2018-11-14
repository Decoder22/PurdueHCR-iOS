//
//  DataManager.swift
//  Platinum Points
//
//  Created by Brian Johncox on 6/30/18.
//  Copyright © 2018 DecodeProgramming. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import NotificationBannerSwift
import Cely




class DataManager {
    
    public static let sharedManager = DataManager()
    private var firstRun = true;
    private let fbh = FirebaseHelper();
    private var _pointTypes: [PointType]? = nil
    private var _unconfirmedPointLogs: [PointLog]? = nil
    private var _houses: [House]? = nil
    private var _rewards: [Reward]? = nil
    private var _houseCodes: [HouseCode]? = nil
    private var _links: LinkList? = nil
    
    private init(){}
    

    
    func getPoints() ->[PointType]? {
        return self._pointTypes
    }
    
    
    func getPointType(value:Int)->PointType{
        for pt in self._pointTypes!{
            if(pt.pointID == value){
                return pt
            }
        }
        return PointType(pv: 0, pd: "Unkown Point Type", rcs: false, pid: -1, permissionLevel: 3, isEnabled:false) // The famous this should never happen comment
    }
    

    
    func createUser(onDone:@escaping (_ err:Error?)->Void ){
        fbh.createUser(onDone: onDone)
    }
    
    func getUserWhenLogginIn(id:String, onDone:@escaping (_ success:Bool) ->Void ){
        fbh.getUserWhenLogIn(id: id, onDone: onDone)
    }
    
    func refreshPointTypes(onDone:@escaping ([PointType])-> Void) {
        fbh.retrievePointTypes(onDone: {(pointTypes:[PointType]) in
            self._pointTypes = pointTypes
            onDone(self._pointTypes!)
        })
    }
    
    func confirmOrDenyPoints(log:PointLog, approved:Bool, onDone:@escaping (_ err:Error?)->Void){
        fbh.approvePoint(log: log, approved: approved, onDone:{[weak self] (_ err :Error?) in
            if(err != nil){
                print("Failed to confirm or deny point")
            }
            else{
                if let index = self?._unconfirmedPointLogs!.index(of: log) {
                    self?._unconfirmedPointLogs!.remove(at: index)
                }
            }
            onDone(err)
        })
    }
    
    func writePoints(log:PointLog, preApproved:Bool = false, onDone:@escaping (_ err:Error?)->Void){
        // take in a point log, write it to house then write the ref to the user
        fbh.addPointLog(log: log, preApproved:preApproved, onDone: onDone)
    }
    
    func getUnconfirmedPointLogs()->[PointLog]?{
        return self._unconfirmedPointLogs
    }
    
    func refreshUser(onDone:@escaping (_ err:Error?)->Void){
        fbh.refreshUserInformation(onDone: onDone)
    }
    
    func refreshUnconfirmedPointLogs(onDone:@escaping (_ pointLogs:[PointLog])->Void ){
        fbh.getUnconfirmedPoints(onDone: {[weak self] (pointLogs:[PointLog]) in
            if let strongSelf = self {
                strongSelf._unconfirmedPointLogs = pointLogs
            }
            onDone(pointLogs)
        })
    }
    
    func refreshHouses(onDone:@escaping ( _ houses:[House]) ->Void){
        print("House refersh")
        fbh.refreshHouseInformation(onDone: { (houses:[House],codes:[HouseCode]) in
            self._houses = houses
            self._houseCodes = codes
            onDone(houses)
        })
    }
    
    func getHouseCodes() -> [HouseCode]?{
        return self._houseCodes
    }
    
    func getHouses() -> [House]?{
        return self._houses
    }
    
    func refreshRewards(onDone:@escaping ( _ rewards:[Reward])-> Void){
        fbh.refreshRewards(onDone: { ( rewards:[Reward]) in
            let total = rewards.count
            let counter = AppUtils.AtomicCounter(identifier: "refreshRewards")
            for reward in rewards {
                self.getImage(filename: reward.fileName, onDone: {(image:UIImage) in
                    reward.image = image
                    counter.increment()
                    if(counter.value == total){
                        self._rewards = rewards
                        onDone(rewards)
                    }
                })
            }
            
        })
    }
    
    func getRewards() -> [Reward]?{
        return self._rewards
    }
    
    func getImage(filename:String, onDone:@escaping ( _ image:UIImage) ->Void ){
        let url = getDocumentsDirectory()
        let fileManager = FileManager.default
        let imagePath = url.appendingPathComponent(filename)
        if fileManager.fileExists(atPath: imagePath.absoluteString){
            onDone(UIImage(contentsOfFile: imagePath.absoluteString)!)
        }else{
            fbh.retrievePictureFromFilename(filename: filename, onDone: {(image:UIImage) in
                if let data = UIImagePNGRepresentation(image) {
                    try? data.write(to: imagePath)
                }
                onDone(image)
            })
        }
    }
    
    func initializeData(finished:@escaping ()->Void){
        print("INITIALIZE")
        let counter = AppUtils.AtomicCounter(identifier: "initializer")
        guard let _ = User.get(.name) else{
            print("FAILED INIT")
            return;
        }
        if let id = User.get(.id) as! String?{
            getUserWhenLogginIn(id: id, onDone: {(done:Bool) in
                self.refreshPointTypes(onDone: {(onDone:[PointType]) in
                    counter.increment()
                    if((User.get(.permissionLevel) as! Int) == 1){
                        //Check if user is an RHP
                        self.refreshUnconfirmedPointLogs(onDone:{(pointLogs:[PointLog]) in
                            counter.increment()
                            if(counter.value == 4){
                                finished();
                            }
                        })
                    }
                    else{
                        counter.increment()
                        if(counter.value == 4){
                            finished();
                        }
                    }
                    
                })
                self.refreshHouses(onDone:{(onDone:[House]) in
                    // Check if user is an REC, in which case you need to get the top scorers
                    if((User.get(.permissionLevel) as! Int) == 2){
                        self.getHouseScorers {
                            counter.increment()
                            if(counter.value == 4){
                                finished();
                            }
                        }
                    }
                    //User is not REC, so they do not need house Scorers (yet)
                    else{
                        counter.increment()
                        if(counter.value == 4){
                            finished();
                        }
                    }
                    
                })
                self.refreshRewards(onDone: {(rewards:[Reward]) in
                    counter.increment()
                    if(counter.value == 4){
                        finished();
                    }
                })
                
            })
        }
        
        
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }

    func getUserRefFromUserID(id:String) -> DocumentReference {
        return fbh.getDocumentReferenceFromID(id: id)
    }
    
    func createQRCode(link:Link, onDone:@escaping(_ id:String?)->Void){
        fbh.createQRCode(link: link, onDone: onDone)
    }
    
    func handlePointLink(id:String){
        //Make sure that the user submitting a QR point is a Resident or an RHP
        let userLevel = User.get(.permissionLevel) as! Int
        if(userLevel != 0 && userLevel != 1){
            DispatchQueue.main.async {
                let banner = NotificationBanner(title: "Failure", subtitle: "Only residents can submit points.", style: .danger)
                banner.duration = 2
                banner.show()
            }
            return
        }
        
        fbh.findLinkWithID(id: id, onDone: {(linkOptional:Link?) in
            let group = DispatchGroup()
            group.enter()
            
            DispatchQueue.global().async {
                while(!DataManager.sharedManager.isInitialized()){}
                group.leave()
            }
            group.notify(queue: .main) {
                guard let link = linkOptional else {
                    DispatchQueue.main.async {
                        let banner = NotificationBanner(title: "Failure", subtitle: "Could not submit points.", style: .danger)
                        banner.duration = 2
                        banner.show()
                    }
                    return
                }
                if(!link.enabled){
                    DispatchQueue.main.async {
                        let banner = NotificationBanner(title: "Failure: Code is not enabled.", subtitle: "Talk to owner to change status.", style: .danger)
                        banner.duration = 2
                        banner.show()
                    }
                    return
                }
                else{
                    let pointType = self.getPointType(value: link.pointTypeID)
                    let resident = User.get(.name) as! String
                    let floorID = User.get(.floorID) as! String
                    let ref = self.getUserRefFromUserID(id: User.get(.id) as! String)
                    let log = PointLog(pointDescription: link.description, resident: resident, type: pointType, floorID: floorID, residentRef: ref)
                    var documentID = ""
                    if(link.singleUse){
                        documentID = id
                    }
                    //NOTE: preApproved is now changed to SingleUseCodes only
                    self.fbh.addPointLog(log: log, documentID: documentID, preApproved: link.singleUse, onDone: {(err:Error?) in
                        if(err == nil){
                            DispatchQueue.main.async {
                                let banner = NotificationBanner(title: "Success", subtitle: log.pointDescription, style: .success)
                                banner.duration = 2
                                banner.show()
                            }
                            
                        }
                        else{
                            if(err!.localizedDescription == "The operation couldn’t be completed. (Document Exists error 0.)"){
                                DispatchQueue.main.async {
                                    let banner = NotificationBanner(title: "Failure", subtitle: "You have already scanned this code.", style: .danger)
                                    banner.duration = 2
                                    banner.show()
                                }
                            }
                            else{
                                DispatchQueue.main.async {
                                    let banner = NotificationBanner(title: "Failure", subtitle: "Could not submit points due to server error.", style: .danger)
                                    banner.duration = 2
                                    banner.show()
                                }
                            }
                        }
                    })
                }
            }
            
        })
    }
    
    func getQRCodeFor(ownerID:String, withRefresh refresh:Bool, withCompletion onDone:@escaping ( _ links:LinkList?)->Void){
        if(refresh || self._links == nil){
            fbh.getQRCodeFor(ownerID: ownerID, withCompletion: {(links:[Link]?) in
                self._links = LinkList(links!)
                onDone(self._links)
            })
        }
        else{
            onDone(self._links)
        }
    }
    
    func setLinkActivation(link:Link, withCompletion onDone:@escaping ( _ err:Error?) ->Void){
        fbh.setLinkActivation(link: link, withCompletion: onDone)
    }
    
    func setLinkArchived(link:Link, withCompletion onDone:@escaping ( _ err:Error?) ->Void){
        fbh.setLinkArchived(link: link, withCompletion: onDone)
    }
    
    func getAllPointLogsForHouse(house:String, onDone:@escaping (([PointLog]) -> Void)){
        fbh.getAllPointLogsForHouse(house: house, onDone: onDone)
    }
    
    func createPointType(pointType:PointType, onDone:@escaping ((_ err:Error?) ->Void)){
        fbh.addPointType(pointType: pointType, onDone: onDone)
    }
    
    func updatePointType(pointType:PointType, onDone:@escaping ((_ err:Error?) ->Void)){
        fbh.updatePointType(pointType: pointType, onDone: onDone)
    }
    
    func getTopScorersForHouse(house:House, onDone:@escaping () -> Void){
        fbh.getTopScorersForHouse(house: house.houseID, onDone: {
            models in
            house.topScoreUsers = models
            onDone()
        })
    }
    
    func getHouseScorers(onDone:@escaping ()->Void){
        //This must be called after the houses are initialized
        let counter = AppUtils.AtomicCounter.init(identifier: "TopScorersCounter")
        for house in self._houses!{
            getTopScorersForHouse(house: house) {
                counter.increment()
                if(counter.value == 5){
                    onDone()
                }
            }
        }
    }
    
    func createReward(reward:Reward, image:UIImage, onDone:@escaping(_ err:Error?) ->Void){
        fbh.uploadImageWithFilename(filename: reward.fileName, img: image) { (err) in
            if(err == nil){
                self.fbh.createReward(reward: reward, onDone: { (error) in
                    onDone(error)
                })
            }
            else{
                onDone(err)
            }
        }
    }
    
    func deleteReward(reward:Reward, onDone:@escaping (_ err:Error?) -> Void ){
        fbh.deletePictureWithFilename(filename: reward.fileName) { (error) in
            if(error == nil){
                self.fbh.deleteReward(reward: reward, onDone: { (err) in
                    onDone(err)
                })
            }
            else{
                onDone(error)
            }
        }
    }
    

    //Used for handling link to make sure all necessairy information is there
    func isInitialized() -> Bool {
        return getHouses() != nil && getPoints() != nil && Cely.currentLoginStatus() == .loggedIn && User.get(.id) != nil && User.get(.name) != nil && User.get(.permissionLevel) != nil
        
    }
}


//class DataManager {
//
//    func retrievePointTypes() -> [PointGroup] {
//        return nil;
//    }
//}
