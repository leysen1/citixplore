//
//  POIsViewController.swift
//  ParseStarterProject-Swift
//
//  Created by Charlotte Leysen on 12/10/2016.
//  Copyright © 2016 Parse. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation
import Parse

// create alert message if data doesn't load

class POIsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, CLLocationManagerDelegate, UIPopoverPresentationControllerDelegate, DataSentDelegate {
    
    
    var nameArray = [String]()
    var distanceArray = [String]()
    var coordinatesArray = [CLLocationCoordinate2D]()
    var completedArray = [String]()
    var imageDataArray = [PFFile]()
    var sortingWithDistanceArray = [Double]()
    let searchController = UISearchController(searchResultsController: nil)
    var filteredNameArray = [String]()
    var chosenAreaPOI = "Kensington and Chelsea"
    var activityIndicator = UIActivityIndicatorView()
    var userLocation = CLLocationCoordinate2D()
    var email: String?
    var scrollView = UIScrollView()
    var chosenPOI = String()
    
    
    func filterContentForSearchText(searchText: String, scope: String = "All") {
        filteredNameArray = nameArray.filter({ (skill) -> Bool in
            return skill.lowercased().contains(searchText.lowercased())
        })

        
        tableView.reloadData()
    }
    
    
    @IBOutlet weak var areaLabel: UILabel!
    @IBOutlet weak var ExploreTitle: UINavigationItem!
    @IBOutlet var tableView: UITableView!
   
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true
        tableView.tableHeaderView = searchController.searchBar

        getStarterVariables { (Bool) in
            self.fetchData { (Bool) in
                self.distanceOrder(completion: { (Bool) in
                    self.parseFetchImages()
                })
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        
        ExploreTitle.title = "Explore An Area"
        areaLabel.text = chosenAreaPOI
    }
    

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.searchController.searchBar.endEditing(true)
        return true
    }
    
    func getStarterVariables(completion: @escaping (_ result: Bool)->()) {
        if let tempEmail = PFUser.current()?.username! {
            self.email = tempEmail
        }
        
        nameArray.removeAll()
        distanceArray.removeAll()
        coordinatesArray.removeAll()
        completedArray.removeAll()
        imageDataArray.removeAll()
        sortingWithDistanceArray.removeAll()
        filteredNameArray.removeAll()

        if let tempGeoPoint = PFUser.current()?["location"] as? PFGeoPoint {
            self.userLocation = CLLocationCoordinate2D(latitude: tempGeoPoint.latitude, longitude: tempGeoPoint.longitude)
            print(self.userLocation)
            completion(true)
            
        }
        print("loading POISVC")
        print(email)
        print(userLocation)
        print(chosenAreaPOI)
    }

    
    func fetchData(completion: @escaping (_ result: Bool)->()) {
        let query = PFQuery(className: "POI")
        query.whereKey("area", equalTo: chosenAreaPOI)
        query.findObjectsInBackground { (objects, error) in
            if error != nil {
                print("error")
            } else {
                if let objects = objects {
                    var i = 0
                    for object in objects {
                        if let tempCoordinates = object["coordinates"] as? PFGeoPoint {
                            self.coordinatesArray.append(CLLocationCoordinate2D(latitude: tempCoordinates.latitude, longitude: tempCoordinates.longitude))
                            if self.userLocation.latitude > 0 {
                                let tempUserLocation = CLLocation(latitude: self.userLocation.latitude, longitude: self.userLocation.longitude)
                                let tempPOILocation = CLLocation(latitude: tempCoordinates.latitude, longitude: tempCoordinates.longitude)
                                let tempDistance = Double(tempUserLocation.distance(from: tempPOILocation) / 1000)
                                self.distanceArray.append(String(tempDistance))
                                self.sortingWithDistanceArray.append(tempDistance)
                            }
                            
                        } else {
                            self.coordinatesArray.append(CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0))
                            self.distanceArray.append("0")
                            self.sortingWithDistanceArray.append(0)
                        }
                        if let tempName = object["name"] as? String {
                            self.nameArray.append(tempName)
                        } else {
                            self.nameArray.append("not found")
                        }
                        i += 1
                        if i == objects.count {
                            completion(true)
                        }
                    }
                }
            }
        }
    }
    
    func distanceOrder(completion: (_ result: Bool)->()) {
        // create dictionary out of name array and distance
        print("distance array \(self.distanceArray.count)")
        print("sorting distance array \(self.sortingWithDistanceArray.count)")
        print("name array \(self.nameArray.count)")
        var i = 0
        if sortingWithDistanceArray.count == distanceArray.count && nameArray.count == sortingWithDistanceArray.count {
            
            var dictName: [String: Double] = [:]
            var dictDist: [String: Double] = [:]
            
            for (name, number) in self.nameArray.enumerated() {
                dictName[number] = self.sortingWithDistanceArray[name]
            }
            for (distance, number) in self.distanceArray.enumerated() {
                dictDist[number] = self.sortingWithDistanceArray[distance]
            }
            
            let sortedName = (dictName as NSDictionary).keysSortedByValue(using: #selector(NSNumber.compare(_:)))
            let sortedDist = (dictDist as NSDictionary).keysSortedByValue(using: #selector(NSNumber.compare(_:)))
            
            self.nameArray = sortedName as! [String]
            self.distanceArray = sortedDist as! [String]
            
            var tempDistanceArray = [String]()
            tempDistanceArray.removeAll()
            for item in self.distanceArray {
                let number: Double = round(Double(item)! * 100) / 100
                tempDistanceArray.append(String(number))
                if tempDistanceArray.count == distanceArray.count {
                    i += 1
                }
            }
            self.distanceArray = tempDistanceArray
            
        }
        
        // prepare for other information in getData function
        self.completedArray.removeAll()
        self.imageDataArray.removeAll()
        
        let imageFiller = UIImage(named: "NA.png")
        let imageFillerData = UIImageJPEGRepresentation(imageFiller!, 1.0)
        
        for _ in self.nameArray {
            self.completedArray.append("no")
            self.imageDataArray.append(PFFile(data: imageFillerData!)!)
            if self.imageDataArray.count == self.nameArray.count {
                i += 1
            }
        }
        if i == 2 {
            completion(true)
            print("distance done")
        }
    }
    
    
    func parseFetchImages() {
        // Get Parse images and completed
        let queryRest = PFQuery(className: "POI")
        queryRest.whereKey("area", equalTo: self.chosenAreaPOI)
        queryRest.findObjectsInBackground { (objects, error) in
            if let objects = objects {
                for object in objects {
                    if let tempName = object["name"] as? String {
                        if let indexCheck = self.nameArray.index(of: tempName) {
                            // add photo to all POIs
                            if let photo = object["smallPicture"] as? PFFile {
                                self.imageDataArray[indexCheck] = photo
                            }
                            if let tempCompletedArray = object["completed"] as? [String] {
                                if tempCompletedArray.contains(self.email!) {
                                    self.completedArray[indexCheck] = "yes"
                                }
                            }
                        }
                    }
                    self.tableView.reloadData()
                }
                self.tableView.reloadData()
                self.tableView.tableFooterView = UIView()
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // add in search count
        
        if completedArray.count > 0 && imageDataArray.count > 0 {
            if searchController.isActive && searchController.searchBar.text != "" {
                return filteredNameArray.count
            }
            
            return nameArray.count
        } else {
            return 0
        }
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! POIsTableViewCell
        
        if searchController.isActive && searchController.searchBar.text != "" {
            let indexValue = nameArray.index(of: filteredNameArray[indexPath.row])
            // name
            if nameArray != [] {
                cell.locationName.text = filteredNameArray[indexPath.row] }
            if distanceArray != [] {
                cell.locationDistance.text = "\(distanceArray[indexValue!]) km" }
            
            // picture
            if imageDataArray != [] {
                imageDataArray[indexValue!].getDataInBackground { (data, error) in
                    
                    if let imageData = data {
                        if let downloadedImage = UIImage(data: imageData) {
                            cell.locationImage.image = downloadedImage
                        }
                    }
                }
            }
            
            if completedArray[indexValue!] == "yes" {
                cell.backgroundColor = UIColor(red: 246/255, green: 246/255, blue: 246/255, alpha: 1.0)
                cell.locationName.textColor = UIColor.black
                cell.locationDistance.textColor = UIColor.black
                cell.locationImage.alpha = 1
                cell.tickImage.image = UIImage(named: "tick.png")
            } else {

                cell.backgroundColor = UIColor.clear
                cell.locationName.textColor = UIColor.black
                cell.locationDistance.textColor = UIColor.black
                cell.locationImage.alpha = 1
                cell.tickImage.image = UIImage()
                
            }
            
        } else {
            // no filter
            
            // name
            if nameArray != [] {
                cell.locationName.text = nameArray[indexPath.row] }
            if distanceArray != [] {
                cell.locationDistance.text = "\(distanceArray[indexPath.row]) km" }
            
            // picture
            if imageDataArray != [] {
                imageDataArray[indexPath.row].getDataInBackground { (data, error) in
                    
                    if let imageData = data {
                        if let downloadedImage = UIImage(data: imageData) {
                            cell.locationImage.image = downloadedImage
                        }
                    }
                }
            }
            
            if completedArray[indexPath.row] == "yes" {
                cell.backgroundColor = UIColor(red: 246/255, green: 246/255, blue: 246/255, alpha: 1.0)
                cell.locationName.textColor = UIColor.black
                cell.locationDistance.textColor = UIColor.black
                cell.locationImage.alpha = 1
                cell.tickImage.image = UIImage(named: "tick.png")
            } else {

                cell.backgroundColor = UIColor.clear
                cell.locationName.textColor = UIColor.black
                cell.locationDistance.textColor = UIColor.black
                cell.locationImage.alpha = 1
                cell.tickImage.image = UIImage()
            }
        }
        
        // return
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if searchController.isActive && searchController.searchBar.text != "" {
            chosenPOI = filteredNameArray[indexPath.row]
        } else {
             chosenPOI = nameArray[indexPath.row]
        }
        
        print("name \(nameArray[indexPath.row])")
            
        performSegue(withIdentifier: "toSinglePOI", sender: self)
        
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
    func userSelectedData(data: String) {
        chosenAreaPOI = data
        print(chosenAreaPOI)
        areaLabel.text = chosenAreaPOI
        // reload table function:
        getStarterVariables { (Bool) in
            self.fetchData { (Bool) in
                self.distanceOrder(completion: { (Bool) in
                    self.parseFetchImages()
                })
            }
        }
        
    }

    
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        if (segue.identifier == "toSinglePOI") {
            let singlePOI = segue.destination as? SinglePOIViewController
            singlePOI?.name = chosenPOI
            
        }
        
        if segue.identifier == "cityPopover" {
            
            let popoverVC: CityPopOverViewController = segue.destination as! CityPopOverViewController
            popoverVC.baseView = "POIView"
            popoverVC.delegate = self
            
            popoverVC.modalPresentationStyle = UIModalPresentationStyle.popover
            popoverVC.popoverPresentationController!.delegate = self
            popoverVC.preferredContentSize = CGSize(width: UIScreen.main.bounds.width / 1.5, height: 150)
            
            
            
        }
    }
    

}


extension POIsViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchText: searchController.searchBar.text!)
    }
}
