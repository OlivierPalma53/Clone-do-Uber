//
//  RiderViewController.swift
//  Uber Clone
//
//  Created by Olivier Palma on 31/12/15.
//  Copyright © 2015 Parse. All rights reserved.
//

import UIKit
import Parse
import MapKit

class RiderViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
    @IBOutlet var mapUber: MKMapView!
    @IBOutlet var callUberButton: UIButton!
    var latitude: CLLocationDegrees = 0
    var longitude: CLLocationDegrees = 0
    var riderRequestActivy = false
    var driverOnTheWay = false
    
    func alertDialog (title: String, message: String){
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
        
    }

    
    @IBAction func callUber(sender: AnyObject) {
        
        if riderRequestActivy == false {
            
            let riderRequest = PFObject(className: "riderRequest")
            riderRequest["username"] = PFUser.currentUser()?.username
            riderRequest["location"] = PFGeoPoint(latitude: latitude, longitude: longitude)
            
            riderRequest.saveInBackgroundWithBlock { (success, error) -> Void in
                
                if success {
                    
                    self.callUberButton.setTitle("Cancelar", forState: .Normal)
                    self.riderRequestActivy == true

                    
                } else {
                    
                    self.alertDialog("Não Foi possivel chamar um uber", message: "tente novamente")
                    
                }
                
            }

            
        } else {
            
            self.callUberButton.setTitle("Chamar Uber", forState: .Normal)
            riderRequestActivy = false
            
            let query = PFQuery(className: "riderRequest")
            query.whereKey("username", equalTo: PFUser.currentUser()!.username!)
            
            query.findObjectsInBackgroundWithBlock({ (objects, error) -> Void in
                if error == nil {
                    
                    if let objects = objects as? [PFObject] {
                        
                        for object in objects {
                            
                            object.deleteInBackground()
                            
                        }
                        
                    }
                    
                } else {
                    print("Error")
                }
            })
            
            
        }
        
    }
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "logOutRider" {
            
            PFUser.logOut()
            
        }
    }
    
    var locationManager: CLLocationManager!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let location:CLLocationCoordinate2D = manager.location!.coordinate
        
        //        print("location = \(location.latitude) \(location.longitude)")
        
        latitude = location.latitude
        longitude = location.longitude
        
        
        let query = PFQuery(className: "riderRequest")
        query.whereKey("username", equalTo: PFUser.currentUser()!.username!)
        
        query.findObjectsInBackgroundWithBlock { (objects: [AnyObject]?, error: NSError?) -> Void in
            
            if error == nil {
                
                if let objects = objects as? [PFObject] {
                    
                    for object in objects {
                        
                        if let driverUsername = object["driverResponded"] {
                            
                            let driverQuery = PFQuery(className: "driverLocation")
                            driverQuery.whereKey("username", equalTo: driverUsername)
                            
                            driverQuery.findObjectsInBackgroundWithBlock { (objects: [AnyObject]?, error: NSError?) -> Void in
                                
                                if error == nil {
                                    
                                    if let objects = objects as? [PFObject] {
                                        
                                        for object in objects {
                                            
                                            if let driverLocation = object["driverLocation"] as? PFGeoPoint {
                                                
                                                let driverCLLocation = CLLocation(latitude: driverLocation.latitude, longitude: driverLocation.longitude)
                                                let userCLLLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
                                                
                                                let distanceMeters = userCLLLocation.distanceFromLocation(driverCLLocation)
                                                let distanceKM = distanceMeters / 1000
                                                let roundedDistance = Double(round(distanceKM * 10) / 10)
                                                
                                                self.callUberButton.setTitle("\(driverUsername) a \(roundedDistance)Km", forState: .Normal)
                                                self.driverOnTheWay = true
                                                
                                                let latDelta = abs(driverLocation.latitude - location.latitude) * 2 + 0.001
                                                let lonDelta = abs(driverLocation.longitude - location.longitude) * 2 + 0.001
                                                
                                                let center = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
                                                let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta))
                                                
                                                self.mapUber.setRegion(region, animated: true)
                                                
                                                self.mapUber.removeAnnotations(self.mapUber.annotations)
                                                
                                                let pinLocation: CLLocationCoordinate2D = CLLocationCoordinate2DMake(location.latitude, location.longitude)
                                                let pinAnnotation = MKPointAnnotation()
                                                pinAnnotation.coordinate = pinLocation
                                                pinAnnotation.title = "Você"
                                                
                                                self.mapUber.addAnnotation(pinAnnotation)
                                                
                                                
                                                let driverPinLocation: CLLocationCoordinate2D = CLLocationCoordinate2DMake(driverLocation.latitude, driverLocation.longitude)
                                                let driverPinAnnotation = MKPointAnnotation()
                                                driverPinAnnotation.coordinate = driverPinLocation
                                                driverPinAnnotation.title = "Seu Motorista"
                                                
                                                self.mapUber.addAnnotation(driverPinAnnotation)
                                                
                                            }
                                            
                                        }
                                        
                                    }
                                    
                                    
                                } else {
                                    print(error)
                                }
                                
                                
                            }
                            
                        }
                        
                    }
                }
                
            } else {
                
                print(error)
                
            }
        }
        
        
        
        if driverOnTheWay == false {
            let center = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
            let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
            
            self.mapUber.setRegion(region, animated: true)
            
            self.mapUber.removeAnnotations(mapUber.annotations)
            
            let pinLocation: CLLocationCoordinate2D = CLLocationCoordinate2DMake(location.latitude, location.longitude)
            let pinAnnotation = MKPointAnnotation()
            pinAnnotation.coordinate = pinLocation
            pinAnnotation.title = "Você"
            
            self.mapUber.addAnnotation(pinAnnotation)
        }
        
    }
}
