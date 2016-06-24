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
        // retreive the tile if it exists, or create a new tile
        // getTile();
        do{
            try self.band?.sensorManager.startAccelerometerUpdatesToQueue(nil, withHandler:{
                (accelerometerData: MSBSensorAccelerometerData!, error: NSError!) in
                print(accelerometerData.x)
                self.GalvanicLabel.text = String(accelerometerData.x)
            })
        }
        catch{
        }
    }
    
    internal func clientManager(clientManager: MSBClientManager!, clientDidDisconnect client: MSBClient!) {
        print("Band disconnected.")
    }
    
    internal func clientManager(clientManager: MSBClientManager!, client: MSBClient!, didFailToConnectWithError error: NSError!) {
        print("Failed to connect to Band.")
        print(error.description)
    }
    
}

