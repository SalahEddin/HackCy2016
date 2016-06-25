//
//  ViewController.swift
//  gymme
//
//  Created by Salah Eddin Alshaal on 24/06/16.
//  Copyright © 2016 Salah Eddin Alshaal. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    var band: MSBClient?
    @IBOutlet weak var GalvanicLabel: UILabel!
    @IBOutlet weak var HeartRateLabel: UILabel!
    @IBOutlet weak var AccelerometerLabel: UILabel!
    
    var currGalvanicAvg: Double = 0
    var prevGalvanicAvg: Double = 0
    var currHeartRateAvg: Double = 0
    var prevHeartRateAvg: Double = 0
    var currAccelerometerStdDev: Double = 0
    var prevAccelerometerStdDev: Double = 0
    
    var GalvanicArr = [UInt]()
    var HeartRateArr = [UInt]()
    var AccelerometerArr = [Double]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
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
        // retreive the tile if it exists, or create a new tile
        // getTile();
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
                
                print(HearRateData.heartRate)
                // self.HeartRateLabel.text = String(HearRateData.heartRate)
                self.HeartRateArr.append(HearRateData.heartRate)
            })
        }
        catch{
        }
        
        do{
            try self.band?.sensorManager.startGSRUpdatesToQueue(nil, withHandler:{
                (gsrData: MSBSensorGSRData!, error: NSError!) in
                
                print(gsrData.resistance)
                // self.GalvanicLabel.text = String(gsrData.resistance)
                self.GalvanicArr.append(gsrData.resistance)
            })
        }
        catch{
        }
        
        do{
            try self.band?.sensorManager.startAccelerometerUpdatesToQueue(nil, withHandler:{
                (accelData: MSBSensorAccelerometerData!, error: NSError!) in
                
                print(accelData.x)
                // self.AccelerometerLabel.text = String(accelData.x)
                let magnitude = sqrt(accelData.x*accelData.x + accelData.y*accelData.y + accelData.z*accelData.z)
                self.AccelerometerArr.append(magnitude)
            })
        }
        catch{
        }
        
        _ = NSTimer.scheduledTimerWithTimeInterval(4.0, target: self, selector: #selector(ViewController.reportPeriodResult), userInfo: nil, repeats: true)

        
    }
    
    internal func reportPeriodResult()-> Void{
        currGalvanicAvg = Double(GalvanicArr.reduce(0, combine: +)) / Double(GalvanicArr.count)
        currHeartRateAvg = Double(HeartRateArr.reduce(0, combine: +)) / Double(HeartRateArr.count)
        
        let AccelCount = AccelerometerArr.count
        if AccelCount != 0 {
            let accelAvg = Double(AccelerometerArr.reduce(0, combine: +)) / Double(AccelCount)
            
            let sumOfSquaredAvgDiff = AccelerometerArr.map { pow($0 - accelAvg, 2.0)}.reduce(0, combine: {$0 + $1})
            currAccelerometerStdDev = sqrt(sumOfSquaredAvgDiff / Double(AccelCount))
        }
        // update UI
        AccelerometerLabel.text = String(currAccelerometerStdDev)
        self.HeartRateLabel.text = String(currHeartRateAvg)
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
    
}

