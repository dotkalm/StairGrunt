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
import MapKit

var Grunt: AVAudioPlayer?
let path = Bundle.main.path(forResource: "StairGrunt.wav", ofType:nil)!
let url = URL(fileURLWithPath: path)

class ViewController: UIViewController{
    var locationManager: CLLocationManager = CLLocationManager()
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
    
    @IBOutlet weak var lat: UILabel!
    
    @IBOutlet weak var locationName: UITextField!
    @IBOutlet weak var long: UILabel!
    
    @IBOutlet weak var corelocationAltitude: UILabel!
    @IBAction func getLocation(_ sender: Any) {
        updateCoordinates()
    }
    var latitude: Double = 0.0
    var longitude: Double = 0.0
    var myAltitude: Double = 0.0
    
    func updateCoordinates(){
        print("button clicked")
        print(self.locationName.text ?? "somewhere")
        locationManager.startUpdatingLocation()
        let name = " \"\(self.locationName.text ?? "none")\" "

        let parameters = ["query": "mutation{ addLocation(name:\(name) lat:\(latitude) long:\(longitude) id:1){ name lat long id }}"] as [String : Any]
        do{
            print(parameters)
            let headers = ["content-type": "application/json"]
            let postData = try JSONSerialization.data(withJSONObject: parameters, options: [])
            let url = URL(string: "https://graphql-express-location.herokuapp.com/graphql")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.allHTTPHeaderFields = headers
            request.httpBody = postData as Data
            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                if let error = error {
                    print("error: \(error)")
                } else {
                    if let response = response as? HTTPURLResponse {
                        print("statusCode: \(response.statusCode)")
                    }
                    if let data = data, let dataString = String(data: data, encoding: .utf8) {
                        print("data: \(dataString)")
                    }
                }
            }
            task.resume()
        } catch{
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()

        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        func playSound() {
            guard let url = Bundle.main.url(forResource: "StairGrunt", withExtension: "wav") else { return }

            do {
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
                try AVAudioSession.sharedInstance().setActive(true)

                /* The following line is required for the player to work on iOS 11. Change the file type accordingly*/
                Grunt = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.wav.rawValue)

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
                if (numberSum > 1.6 && elapsed < -30.0){
                    playSound()
                    self.date1 = Date()
                    
                    
                }
//                print(elapsed, "elapsed time")
                self.previous = CGFloat(current!)
//                print(self.AltitudeArray, self.AltitudeArray.count, numberSum)
  
               }

        }

        // Do any additional setup after loading the view
        

    }
    
    
   
    
    
    
    
}

extension ViewController: CLLocationManagerDelegate{
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
       if let location = locations.first {
//            print("Found user's location: \(location)", "lat =", location.coordinate.latitude," long = ",location.coordinate.longitude)
            self.lat.text = "My Lat:" + String(location.coordinate.latitude)
            self.long.text = "My Long:" + String(location.coordinate.longitude)
            latitude = location.coordinate.latitude
            longitude = location.coordinate.longitude
            myAltitude = location.altitude
    
//            let span = MKCoordinateSpanMake(0.0005, 0.0005)
            let mylocation = CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude)
//            print(mylocation)
//            print("\n", location.altitude, "altitude")
            self.corelocationAltitude.text = "altitude: " + String(location.altitude)
//            let region = MKCoordinateRegionMake(mylocation, span)
//            Map.setRegion(region, animated: true)
    
            //marker
            let marker1 = MKPointAnnotation()
            marker1.coordinate = CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude)
            marker1.title = "My Position"
//            Map.addAnnotation(marker1)
    
       }
  }
    
  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
       print("Failed to find user's location: \(error.localizedDescription)")
  }
}


