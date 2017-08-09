//
//  ViewController.swift
//  PendReader
//
//  Created by Hamzah Mugharbil on 8/9/17.
//  Copyright © 2017 Hamzah Mugharbil. All rights reserved.
//

import UIKit
import CloudKit

class ViewController: UIViewController {

    @IBOutlet weak var tempLabel: UILabel!
    @IBOutlet weak var pressureLabel: UILabel!
    @IBOutlet weak var windspeedLabel: UILabel!
    @IBOutlet weak var periodSegment: UISegmentedControl!

    @IBOutlet weak var datePicker: UIDatePicker!
    
    @IBAction func periodSegment(_ sender: UISegmentedControl) {
        fetchData(control: sender)
    }
    
    @IBAction func datePicker(_ sender: UIDatePicker) {
        fetchData(control: sender)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // handle any change to the controls
        
        
    }
    
    func fetchData(control: UIControl) {
    
        // point to our specific CloudKit container
        let container = CKContainer(identifier: "iCloud.com.hamzahmugharbil.WeatherDataLoader")
        let publicDB = container.publicCloudDatabase
        
        // get date from datePicker, removing time
        let startDate = NSCalendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: datePicker.date)
        
        // begin by setting end-date same as start date
        var endDate = startDate
        
        switch periodSegment.selectedSegmentIndex {
            case 0:
                // first option - 1 day of data
                endDate = NSCalendar.current.date(byAdding: .day, value: 1, to: startDate!)
            case 1:
                // second option - add 7 days
                endDate = NSCalendar.current.date(byAdding: .day, value: 7, to: startDate!)
            case 2:
                // third option - add a month
                endDate = NSCalendar.current.date(byAdding: .month, value: 1, to: startDate!)
            default:
                break
        }
        
        // create predicate
        let myPredicate = NSPredicate(format: "date >= %@ AND date < %@", startDate! as CVarArg, endDate! as CVarArg)
        
        // create query
        let myQuery = CKQuery(recordType: "weatherData", predicate: myPredicate)
        
        // issue query and setup completion closure
        publicDB.perform(myQuery, inZoneWith: nil, completionHandler: {
            results, error in
            if error != nil {
                print("wtf is going on")
            }
            if (results?.count)! > 0 {
                // deal with the results
                // need to update UI back on main thread
                OperationQueue.main.addOperation({
                        self.parseResults(results!)
                })
            }
        })
        
    }
    
    func parseResults(_ results: [AnyObject]) {
        // create arrays to hold returned values
        // when retrieving multiple days of data
        var windspeedMeans = [Double]()
        var temperatureMeans = [Double]()
        var pressureMeans = [Double]()
        var windspeedMedians = [Double]()
        var temperatureMedians = [Double]()
        var pressureMedians = [Double]()
        
        for eachResult in results {
            windspeedMeans.append(eachResult["windspeedMean"] as! Double)
            temperatureMeans.append(eachResult["airTemperatureMean"] as! Double)
            pressureMeans.append(eachResult["barometricPressureMean"] as! Double)
            windspeedMedians.append(eachResult["windspeedMedian"] as! Double)
            temperatureMedians.append(eachResult["airTemperatureMedian"] as! Double)
            pressureMedians.append(eachResult["barometricPressureMedian"] as! Double)
        }
        
        // average collected results
        let windMean = calculateAverage(windspeedMeans)
        let windMed = calculateAverage(windspeedMedians)
        let tempMean = calculateAverage(temperatureMeans)
        let tempMed = calculateAverage(temperatureMedians)
        let pressureMean = calculateAverage(pressureMeans)
        let pressureMed = calculateAverage(pressureMedians)
        
        // set labels
        tempLabel.text = "\(tempMean) / \(tempMed)"
        windspeedLabel.text = "\(windMean) / \(windMed)"
        pressureLabel.text = "\(pressureMean) / \(pressureMed)"
        
    }
    
    func calculateAverage(_ values: [Double]) -> Int {
        let total = values.reduce(0.0, { $0 + $1 })
        let average = total/Double(values.count)
        let roundedInt = Int(round(average))
        return roundedInt
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

