//
//  indoorsViewController.swift
//  gymme
//
//  Created by Salah Eddin Alshaal on 25/06/16.
//  Copyright © 2016 Salah Eddin Alshaal. All rights reserved.
//

import UIKit

class indoorsViewController: UIViewController, ESTBeaconManagerDelegate {

    @IBOutlet weak var venueLabel: UILabel!
    // 2. Add the beacon manager and the beacon region
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
    // 42601 47751 22
    // 50698 56686 21
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        // 3. Set the beacon manager's delegate
        self.beaconManager.delegate = self
        // 4. We need to request this authorization for every beacon manager
        self.beaconManager.requestAlwaysAuthorization()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
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
            venueLabel.text = String(places)
            // TODO: update the UI here
            print("venue:\(places)") // TODO: remove after implementing the UI
        }
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
