//
//  ViewController.swift
//  gymme
//
//  Created by Salah Eddin Alshaal on 24/06/16.
//  Copyright © 2016 Salah Eddin Alshaal. All rights reserved.
//

import UIKit

class ViewController: UIViewController, ESTBeaconManagerDelegate {
    
    var band: MSBClient?
    @IBOutlet weak var GalvanicLabel: UILabel!
    @IBOutlet weak var HeartRateLabel: UILabel!
    @IBOutlet weak var AccelerometerLabel: UILabel!
    @IBOutlet weak var calibratingLabel: UILabel!
    @IBOutlet weak var calibratingProgressBar: UIProgressView!
    
    var calibGalvanicAvg: Double = 0
    var currGalvanicAvg: Double = 0
    var prevGalvanicAvg: Double = 0
    
    var calibHeartRateAvg: Double = 0
    var currHeartRateAvg: Double = 0
    var prevHeartRateAvg: Double = 0
    
    var calibAccelerometerStdDev: Double = 0
    var currAccelerometerStdDev: Double = 0
    var prevAccelerometerStdDev: Double = 0
    
    var GalvanicArr = [UInt]()
    var HeartRateArr = [UInt]()
    var AccelerometerArr = [Double]()
    var HeartRateLocked = false
    
    var excitement = 50
    var calibratingPasses = 10
    var calibrating = true
    
    //MARK: Estimote
    var venueId: Int = 1 // default venue
    let beaconManager = ESTBeaconManager()
    let beaconRegion = CLBeaconRegion(
        proximityUUID: NSUUID(UUIDString: "B9407F30-F5F8-466E-AFF9-25556B57FE6D")!,
        identifier: "")
    
    let venuesByBeacons = [
        "42601:47751":1,
        "50693:56686":2,
        "20015:51325":3,
        "62270:31254":4
    ]
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // 3. Set the beacon manager's delegate
        self.beaconManager.delegate = self
        // 4. We need to request this authorization for every beacon manager
        self.beaconManager.requestAlwaysAuthorization()
        
        // call static request
        //getRequestStatic()
        //getExcitementByVenue(1)
        // Set up ClientManager and its delegate
        MSBClientManager.sharedManager().delegate = self
        
        // Get a list of attached Clients
        let attachedClients:Array = MSBClientManager.sharedManager().attachedClients()
        
        // Connect to the Band Client
        if let client = attachedClients.first as? MSBClient {
            self.band = client
            MSBClientManager.sharedManager().connectClient(self.band)
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}

extension ViewController : MSBClientManagerDelegate {
    
    ////////////////////////////////
    //MARK: Protocol Conformation
    ////////////////
    
    // MARK: Client Manager Delegates
    internal func clientManager(clientManager: MSBClientManager!, clientDidConnect client: MSBClient!) {
        // debug mesage
        print("Band connected.")
        HeartRateLabel.text = "Connected"
        // check current user heart rate consent
        
        if(self.band?.sensorManager.heartRateUserConsent() != MSBUserConsent.Granted) {
            // user hasn’t consented, request consent
            // the calling class is an Activity and implements
            // HeartRateConsentListener
            self.band?.sensorManager.requestHRUserConsentWithCompletion({ (consent:Bool, error:NSError!) -> Void in });
        }
        do{
            try self.band?.sensorManager.startHeartRateUpdatesToQueue(nil, withHandler:{
                (HearRateData: MSBSensorHeartRateData!, error: NSError!) in
                
                //print(HearRateData.heartRate)
                if(HearRateData.quality == MSBSensorHeartRateQuality.Locked){
                    self.HeartRateArr.append(HearRateData.heartRate)
                    self.HeartRateLocked = true
                }
            })
        }
        catch{}
        
        do{
            try self.band?.sensorManager.startGSRUpdatesToQueue(nil, withHandler:{
                (gsrData: MSBSensorGSRData!, error: NSError!) in
                
                //print(gsrData.resistance)
                self.GalvanicArr.append(gsrData.resistance)
            })
        }
        catch{ }
        
        do{
            try self.band?.sensorManager.startAccelerometerUpdatesToQueue(nil, withHandler:{
                (accelData: MSBSensorAccelerometerData!, error: NSError!) in
                
                //print(accelData.x)
                let magnitude = sqrt(accelData.x*accelData.x + accelData.y*accelData.y + accelData.z*accelData.z)
                self.AccelerometerArr.append(magnitude)
            })
        }
        catch{}
        
        _ = NSTimer.scheduledTimerWithTimeInterval(4.0, target: self, selector: #selector(ViewController.reportPeriodResult), userInfo: nil, repeats: true)
        
        
    }
    
    internal func reportPeriodResult()-> Void{
        
        if calibrating {
            let passGalvanic = Double(GalvanicArr.reduce(0, combine: +)) / Double(GalvanicArr.count)
            let passHeart = Double(HeartRateArr.reduce(0, combine: +)) / Double(HeartRateArr.count);
            
            var passAccel = 0.0
            
            let AccelCount = AccelerometerArr.count
            if AccelCount != 0 {
                let accelAvg = Double(AccelerometerArr.reduce(0, combine: +)) / Double(AccelCount)
                
                let sumOfSquaredAvgDiff = AccelerometerArr.map { pow($0 - accelAvg, 2.0)}.reduce(0, combine: {$0 + $1})
                passAccel = sqrt(sumOfSquaredAvgDiff / Double(AccelCount))
            }
            
            calibGalvanicAvg = (calibGalvanicAvg*Double(calibratingPasses) + passGalvanic) / Double(calibratingPasses + 1)
            
            if(HeartRateLocked){
                calibHeartRateAvg = (calibHeartRateAvg*Double(calibratingPasses) + passHeart) / Double(calibratingPasses + 1)
            }
            else{
                // todo
            }
            
            calibAccelerometerStdDev = (calibAccelerometerStdDev*Double(calibratingPasses) + passAccel) / Double(calibratingPasses + 1)
            
            self.calibratingPasses += 1
            calibratingProgressBar.progress = 1.0 / Float(calibratingPasses)
            if self.calibratingPasses >= 10 {
                calibratingLabel.hidden = true
                calibratingProgressBar.hidden = true
                calibrating = false
            }
        }
        else{
            currGalvanicAvg = Double(GalvanicArr.reduce(0, combine: +)) / Double(GalvanicArr.count)
            currHeartRateAvg = Double(HeartRateArr.reduce(0, combine: +)) / Double(HeartRateArr.count)
            
            let AccelCount = AccelerometerArr.count
            if AccelCount != 0 {
                let accelAvg = Double(AccelerometerArr.reduce(0, combine: +)) / Double(AccelCount)
                
                let sumOfSquaredAvgDiff = AccelerometerArr.map { pow($0 - accelAvg, 2.0)}.reduce(0, combine: {$0 + $1})
                currAccelerometerStdDev = sqrt(sumOfSquaredAvgDiff / Double(AccelCount))
            }
            
            inferExcitement()
            
        }
        
        // update UI
        // AccelerometerLabel.text = String(currAccelerometerStdDev)
        self.HeartRateLabel.text = "HR: \(String(currHeartRateAvg)), Accel: \(String(currAccelerometerStdDev)) "
        self.GalvanicLabel.text = String(currGalvanicAvg)
        // copy to previous
        prevGalvanicAvg = currGalvanicAvg
        prevHeartRateAvg = currHeartRateAvg
        prevAccelerometerStdDev = currAccelerometerStdDev
        // reset curr
        AccelerometerArr.removeAll()
        GalvanicArr.removeAll()
        HeartRateArr.removeAll()
        currGalvanicAvg = 0.0
        currHeartRateAvg = 0.0
        currAccelerometerStdDev = 0.0
        
    }
    
    internal func inferExcitement(){
        
        let accelDiff = Double(currAccelerometerStdDev - calibAccelerometerStdDev)
        print("accelDiff: \(accelDiff)")
        
        switch accelDiff {
        case _ where accelDiff < -1:
            excitement -= 10
            break
        case _ where accelDiff < -0.70:
            excitement -= 8
            break
        case _ where accelDiff < -0.3:
            excitement -= 6
            break
        case _ where accelDiff < -0.1:
            excitement -= 3
            break
        case _ where accelDiff > 1.2:
            excitement += 20
            break
        case _ where accelDiff > 1:
            excitement += 15
            break
        case _ where accelDiff > 0.70:
            excitement += 10
            break
        case _ where accelDiff > 0.3:
            excitement += 8
            break
        case _ where accelDiff > 0.1:
            excitement += 4
            break
        default:
            break
        }
        let galvanicDiff = Double(calibGalvanicAvg - currGalvanicAvg)
        excitement -= Int(200000.0/(galvanicDiff))
        print("galvanicDiff: \(galvanicDiff)")
        
        var heartDiff: Double
        if(!HeartRateLocked){
            heartDiff = Double(calibHeartRateAvg - currHeartRateAvg)
            print("heartDiff: \(heartDiff)")
            excitement -= Int(heartDiff / 1.2)
        }
    
        excitement = excitement > 100 ? 100 : excitement
        excitement = excitement < 0 ? 0 : excitement
        
        AccelerometerLabel.text = String(excitement)
        print("excitement: \(excitement)")
        self.postExcitement()
        excitement = 0
    }
    
    func combinator(accumulator: UInt, current: UInt) -> UInt {
        return accumulator + current
    }
    
    internal func clientManager(clientManager: MSBClientManager!, clientDidDisconnect client: MSBClient!) {
        print("Band disconnected.")
    }
    
    internal func clientManager(clientManager: MSBClientManager!, client: MSBClient!, didFailToConnectWithError error: NSError!) {
        print("Failed to connect to Band.")
        print(error.description)
    }
    
    internal func getRequestStatic(){
        let configuration = NSURLSessionConfiguration .defaultSessionConfiguration()
        let session = NSURLSession(configuration: configuration)
        
        let urlString = NSString(format: "http://hackcyprus.azurewebsites.net/api/v1")
        
        print("get wallet balance url string is \(urlString)")
        //let url = NSURL(string: urlString as String)
        let request : NSMutableURLRequest = NSMutableURLRequest()
        request.URL = NSURL(string: NSString(format: "%@", urlString) as String)
        request.HTTPMethod = "GET"
        request.timeoutInterval = 30
        
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let dataTask = session.dataTaskWithRequest(request) {
            (let data: NSData?, let response: NSURLResponse?, let error: NSError?) -> Void in
            
            // 1: Check HTTP Response for successful GET request
            guard let httpResponse = response as? NSHTTPURLResponse, receivedData = data
                else {
                    print("error: not a valid http response")
                    return
            }
            
            switch (httpResponse.statusCode)
            {
            case 200:
                
                let response = NSString (data: receivedData, encoding: NSUTF8StringEncoding)
                print("response is \(response)")
                
                
                do {
                    let getResponse = try NSJSONSerialization.JSONObjectWithData(receivedData, options: .AllowFragments) as? [String : AnyObject]
                    
                    //EZLoadingActivity .hide()
                    print(String(getResponse!["message"]))
                    // }
                } catch {
                    print("error serializing JSON: \(error)")
                }
                
                break
            case 400:
                
                break
            default:
                print("wallet GET request got response \(httpResponse.statusCode)")
            }
        }
        dataTask.resume()
    }
    
    internal func getExcitementByVenue(venueId: Int){
        let configuration = NSURLSessionConfiguration .defaultSessionConfiguration()
        let session = NSURLSession(configuration: configuration)
        
        let urlString = NSString(format: "http://hackcyprus.azurewebsites.net/api/v1?venue_id=\(venueId)")
        
        print("get wallet balance url string is \(urlString)")
        //let url = NSURL(string: urlString as String)
        let request : NSMutableURLRequest = NSMutableURLRequest()
        request.URL = NSURL(string: NSString(format: "%@", urlString) as String)
        request.HTTPMethod = "GET"
        request.timeoutInterval = 30
        
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let dataTask = session.dataTaskWithRequest(request) {
            (let data: NSData?, let response: NSURLResponse?, let error: NSError?) -> Void in
            
            // 1: Check HTTP Response for successful GET request
            guard let httpResponse = response as? NSHTTPURLResponse, receivedData = data
                else {
                    print("error: not a valid http response")
                    return
            }
            
            switch (httpResponse.statusCode)
            {
            case 200:
                
                let response = NSString (data: receivedData, encoding: NSUTF8StringEncoding)
                print("response is \(response)")
                
                
                do {
                    let getResponse = try NSJSONSerialization.JSONObjectWithData(receivedData, options: .AllowFragments) as? [String : AnyObject]
                    print(String(getResponse!["message"]))
                } catch {
                    print("error serializing JSON: \(error)")
                }
                break
            case 400:
                
                break
            default:
                print("wallet GET request got response \(httpResponse.statusCode)")
            }
        }
        dataTask.resume()
        
    }
    
    internal func postExcitement(){
        let configuration = NSURLSessionConfiguration .defaultSessionConfiguration()
        let session = NSURLSession(configuration: configuration)
        
        let params = ["phone_ID": 1, "excitement_level": excitement, "venue_id": venueId] as Dictionary<String, AnyObject>
        
        let urlString = NSString(format: "http://hackcyprus.azurewebsites.net/api/v1");
        print("url string is \(urlString)")
        let request : NSMutableURLRequest = NSMutableURLRequest()
        request.URL = NSURL(string: NSString(format: "%@", urlString)as String)
        request.HTTPMethod = "POST"
        request.timeoutInterval = 30
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.HTTPBody  = try! NSJSONSerialization.dataWithJSONObject(params, options: [])
        
        let dataTask = session.dataTaskWithRequest(request)
        {
            (let data: NSData?, let response: NSURLResponse?, let error: NSError?) -> Void in
            // 1: Check HTTP Response for successful GET request
            guard let httpResponse = response as? NSHTTPURLResponse, receivedData = data
                else {
                    print("error: not a valid http response")
                    return
            }
            
            switch (httpResponse.statusCode)
            {
            case 200:
                
                let response = NSString (data: receivedData, encoding: NSUTF8StringEncoding)
                
                
                if response == "SUCCESS"
                {
                    print("success posting")
                }
                
            default:
                print("save profile POST request got response \(httpResponse.statusCode)")
            }
        }
        dataTask.resume()
    }
}

extension ViewController {
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.beaconManager.startRangingBeaconsInRegion(self.beaconRegion)
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        self.beaconManager.stopRangingBeaconsInRegion(self.beaconRegion)
    }
    
    func placesNearBeacon(beacon: CLBeacon) -> [Int]? {
        let beaconKey = "\(beacon.major):\(beacon.minor)"
        if let places = self.venuesByBeacons[beaconKey] {
            let sortedPlaces = Array(arrayLiteral: places).sort() { $0 < $1 }.map { $0 }
            return sortedPlaces
        }
        return nil
    }
    
    func beaconManager(manager: AnyObject, didRangeBeacons beacons: [CLBeacon],
                       inRegion region: CLBeaconRegion) {
        if let nearestBeacon = beacons.first, places = placesNearBeacon(nearestBeacon) {
            //venueLabel.text = String(places)
            // TODO: update the UI here
            venueId = places[0]
            print("venue:\(places)")
        }
    }
    
}

