//
//  ViewController.swift
//  StairGrunt
//
//  Created by Joel on 2/24/20.
//  Copyright © 2020 dotkalm. All rights reserved.
//

import UIKit
import CoreMotion
import AVFoundation
import CoreLocation

var Grunt: AVAudioPlayer?
let path = Bundle.main.path(forResource: "StairGrunt.wav", ofType:nil)!
let url = URL(fileURLWithPath: path)
var locationManager: CLLocationManager!

class ViewController: UIViewController{

    var date1 : Date! = Date()
    var AltitudeArray : [Float] = [0.0]
    var pedometer = CMPedometer()
    var altitude = CMAltimeter()
    var previous : CGFloat = 0.0
    var previousGrunt : Date = Date()

    @IBOutlet weak var Update: UILabel!
    
    @IBOutlet weak var Steps: UILabel!
    
    @IBOutlet weak var Altitude: UILabel!
    
    @IBOutlet weak var Pressure: UILabel!
    
    @IBOutlet weak var Cadence: UILabel!
    
    @IBOutlet weak var TenSecondChange: UILabel!
    
   
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager?.allowsBackgroundLocationUpdates = true
        locationManager?.pausesLocationUpdatesAutomatically = false

        func playSound() {
            guard let url = Bundle.main.url(forResource: "StairGrunt", withExtension: "wav") else { return }

            do {
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
                try AVAudioSession.sharedInstance().setActive(true)

                /* The following line is required for the player to work on iOS 11. Change the file type accordingly*/
                Grunt = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.mp3.rawValue)

                /* iOS 10 and earlier require the following line:
                player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileTypeMPEGLayer3) */

                guard let player = Grunt else { return }

                player.play()

            } catch let error {
                print(error.localizedDescription)
            }
        }
        if CMPedometer.isFloorCountingAvailable() {
            pedometer.startUpdates(from: Date()) { (data, error) in
                 self.Update.text = "floors ascended: \(data?.floorsAscended?.description ?? 0.description)"
                 self.Steps.text = "steps: \(data?.numberOfSteps.description ?? 0.description)"
                 self.Cadence.text = "cadence: \(data?.currentCadence?.description ?? 0.description)"
            }
        }
        if CMAltimeter.isRelativeAltitudeAvailable(){
            altitude.startRelativeAltitudeUpdates(to: OperationQueue.main) { (data, error) in
                let current = data?.relativeAltitude.floatValue
                let difference = self.previous - CGFloat(current!)
                self.Altitude.text = "Altitude: \(String.init(format: "%.1fM", (data?.relativeAltitude.floatValue)!))"
                self.Pressure.text = "Pressure: \(data?.pressure.description ?? 0.description)"
                self.AltitudeArray.append(Float(difference))
                if self.AltitudeArray.count > 10{
                    self.AltitudeArray.remove(at: 0)
                }
                let numberSum = self.AltitudeArray.reduce(0, { x, y in
                    x - y
                })
                self.TenSecondChange.text = numberSum.description

                let elapsed = self.date1.timeIntervalSince(Date())
                if (numberSum > 2.0 && elapsed < -30.0){
                    playSound()
                    print("GRUNNNNTTT")
                    self.date1 = Date()
                    
                    
                }



                print(elapsed, "elapsed time")
                self.previous = CGFloat(current!)
                print(self.AltitudeArray, self.AltitudeArray.count, numberSum)
                print(CLLocation().altitude, "altitude")
                self.Cadence.text = CLLocation().altitude.description
               }

        }
 
        // Do any additional setup after loading the view.
    }
    


}

