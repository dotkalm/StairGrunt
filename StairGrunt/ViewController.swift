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

var Grunt: AVAudioPlayer?
let path = Bundle.main.path(forResource: "StairGrunt.wav", ofType:nil)!
let url = URL(fileURLWithPath: path)

class ViewController: UIViewController {
    
    
    var AltitudeArray : [Float] = [0.0]
    var pedometer = CMPedometer()
    var altitude = CMAltimeter()
    var previous : CGFloat = 0.0
    @IBOutlet weak var Update: UILabel!
    
    @IBOutlet weak var Steps: UILabel!
    
    @IBOutlet weak var Altitude: UILabel!
    
    @IBOutlet weak var Pressure: UILabel!
    
    @IBOutlet weak var Cadence: UILabel!
    
    @IBOutlet weak var TenSecondChange: UILabel!
    
    var backgroundTask: UIBackgroundTaskIdentifier = .invalid

    func registerBackgroundTask() {
       backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
         self?.endBackgroundTask()
       }
       assert(backgroundTask != .invalid)
     }
       
     func endBackgroundTask() {
       print("Background task ended.")
       UIApplication.shared.endBackgroundTask(backgroundTask)
       backgroundTask = .invalid
     }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
                self.Altitude.text = "Altitude: \(String.init(format: "%.1fM", (data?.relativeAltitude.floatValue)!))"
                self.Pressure.text = "Pressure: \(data?.pressure.description ?? 0.description)"
                // find difference between last element and current altitude
                let current = data?.relativeAltitude.floatValue
                let difference = self.previous + CGFloat(current!)

                self.AltitudeArray.append(Float(difference))
                if self.AltitudeArray.count > 10{
                    self.AltitudeArray.remove(at: 0)
                }
                let numberSum = self.AltitudeArray.reduce(0, { x, y in
                    x + y
                })
                if (numberSum > 2.0){
                    playSound()
                    //do timestamp so it doesnt go nuts
                }
                self.previous = CGFloat(current!)
                print(self.AltitudeArray, self.AltitudeArray.count, numberSum)
                self.TenSecondChange.text = "10 seconds : \(numberSum.description)"
                
               }
        }
 
        // Do any additional setup after loading the view.
    }


}

