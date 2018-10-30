//
//  ViewController.swift
//  iOS_LocationNotificationApp
//
//  Created by macbook pro on 09/10/18.
//  Copyright © 2018 Omni-Bridge. All rights reserved.
//

import UIKit
import GoogleMaps
import GooglePlaces
import UserNotifications

class ViewController: UIViewController {
    
    // MARK:- Outlets and variable declaration
    
    @IBOutlet weak var btnForCurrentLocation : UIButton!
    @IBOutlet weak var btnForStart : UIButton!
    @IBOutlet weak var txtViewForDestinationLocation : UITextField!
    @IBOutlet var tableView: UITableView!
    
    var isStartPressed = false
    var distanceInMeters = 0.0
    var locationManager = CLLocationManager()
    var currentLocation: CLLocation?
    var destinationLocation : CLLocation?
    var addressArray = [GMSAutocompletePrediction]()
    lazy var filter : GMSAutocompleteFilter = {
        let filter = GMSAutocompleteFilter()
        filter.type = .address
        return filter
    }()
    
    // MARK:- Oview life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.tableFooterView = UIView()
        self.tableView.isHidden = true
        self.btnForStart.isHidden = true
        self.setUserDefaultLoactaion()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK:- Button ction methods
    
    @IBAction func startButtonPressed(_ sender: UIButton) {
        if self.isStartPressed{
            self.locationManager.stopUpdatingLocation()
            self.isStartPressed = false
            sender.setTitle("Start", for: .normal)
        }else if self.currentLocation != nil && self.destinationLocation != nil{
            self.isStartPressed = true
            sender.setTitle("Stop", for: .normal)
        }
    }
    
    func sendLocalNotification(){
        //Setting content of the notification
        let content = UNMutableNotificationContent()
        content.title = "Hello there !"
        content.body = "You are within \(self.distanceInMeters) mtrs of your destination."
        content.badge = 0
        content.sound = UNNotificationSound.default()
        
        //Setting time for notification trigger
        let date = Date(timeIntervalSinceNow: 1)
        let dateCompenents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateCompenents, repeats: false)
        //Adding Request
        let request = UNNotificationRequest(identifier: "timerdone", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
    
    /// set device current Loactaion
    func setUserDefaultLoactaion(){
        locationManager = CLLocationManager()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        locationManager.distanceFilter = 1
        // adding background capability
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.startUpdatingLocation()
        locationManager.delegate = self
    }
    
    /// Used to check condition and send local notification
    func checkAndSetLocalNotification(){
        distanceInMeters = Double(round((self.currentLocation?.distance(from: self.destinationLocation!))! * 100 / 100))
        if distanceInMeters < 1000{
            self.sendLocalNotification()
        }
    }
}

// MARK: - UITextFieldDelegate
extension ViewController : UITextFieldDelegate{
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        self.tableView.isHidden = false
        let searchStr = (textField.text! as NSString).replacingCharacters(in: range, with: string)
        if searchStr == ""{
            self.addressArray = [GMSAutocompletePrediction]()
        }else{
            GMSPlacesClient.shared().autocompleteQuery(searchStr, bounds: nil, filter: filter) { (result, error) in
                if error == nil && result != nil{
                    self.addressArray = result!
                }
            }
        }
        self.destinationLocation = nil
        self.tableView.reloadData()
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

// MARK: - CLLocationManagerDelegate
extension ViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.currentLocation  = locations.last!
        if !self.isStartPressed{
            let geoCoder = CLGeocoder()
            geoCoder.reverseGeocodeLocation(self.currentLocation!, completionHandler: { (placemarks, error) -> Void in
                var placeMark: CLPlacemark!
                placeMark = placemarks?[0]
                var address: String = ""
                for name in (placeMark.addressDictionary?["FormattedAddressLines"] as! NSArray){
                    address += "\(name) ,"
                }
                self.btnForCurrentLocation.setTitle(address , for: .normal)
            })
        }
        if self.isStartPressed{
            self.checkAndSetLocalNotification()
        }
    }
    
    // Handle authorization for the location manager.
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .restricted:
            print("Location access was restricted.")
        case .denied:
            print("User denied access to location.")
        case .notDetermined:
            print("Location status not determined.")
        case .authorizedAlways: fallthrough
        case .authorizedWhenInUse:
            print("Location status is OK.")
        }
    }
    
    // Handle location manager errors.
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationManager.stopUpdatingLocation()
        print("Error: \(error)")
    }
}

// MARK: - UITableViewDataSource
extension ViewController : UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.addressArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "Cell")
        if cell == nil{
            cell = UITableViewCell(style: .default, reuseIdentifier: "Cell")
        }
        cell?.textLabel?.attributedText = self.addressArray[indexPath.row].attributedFullText
        cell?.textLabel?.font = UIFont.systemFont(ofSize: 12)
        print("\(self.addressArray[indexPath.row].attributedFullText)")
        return cell!
    }
}

// MARK: - UITableViewDelegate
extension ViewController : UITableViewDelegate{
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tableView.isHidden = true
        let begningPosition = self.txtViewForDestinationLocation.beginningOfDocument
        self.txtViewForDestinationLocation.textRange(from: begningPosition, to: begningPosition)
        self.txtViewForDestinationLocation.resignFirstResponder()
        self.txtViewForDestinationLocation.attributedText = self.addressArray[indexPath.row].attributedFullText
        let placeID = self.addressArray[indexPath.row].placeID
        GMSPlacesClient.shared().lookUpPlaceID(placeID!, callback: { (place, error) -> Void in
            if let error = error {
                print("lookup place id query error: \(error.localizedDescription)")
                return
            }
            guard let place = place else {
                return
            }
            self.destinationLocation = CLLocation(latitude: place.coordinate.latitude, longitude: place.coordinate.longitude)
            if self.currentLocation != nil && self.destinationLocation != nil{
                self.btnForStart.isHidden = false
            }
        })
    }
}
