//
//  ExportDataVC.swift
//  DataCollector
//
//  Created by Aleksei Degtiarev on 19/02/2018.
//  Copyright © 2018 Aleksei Degtiarev. All rights reserved.
//

import UIKit
import CoreData

class ExportDataVC: UIViewController, UITableViewDelegate, UITableViewDataSource, NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var deleteButton: UIBarButtonItem!
    
    
    var controller: NSFetchedResultsController<Session>!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        attemptFetch()
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "ItemCell", for: indexPath) as! ItemSessionCell
        configureCell(cell: cell, indexPath: indexPath as NSIndexPath)
        return cell
    }
    
    func configureCell(cell: ItemSessionCell, indexPath: NSIndexPath) {
        
        let session = controller.object(at: indexPath as IndexPath)
        cell.configureCell(session: session)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let sections = controller.sections {
            let sectionInfo = sections[section]
            return sectionInfo.numberOfObjects
        }
        
        return 0
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if let sections = controller.sections {
            return sections.count
        }
        
        return 0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 64
    }
    
    
    func attemptFetch(){
        let fetchRequest: NSFetchRequest<Session> = Session.fetchRequest()
        let idSort = NSSortDescriptor(key: "id", ascending: false)
        fetchRequest.sortDescriptors = [idSort]
        
        let controller = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        
        controller.delegate = self
        
        self.controller = controller
        
        do {
            
            try self.controller.performFetch()
            
        } catch {
            
            let error = error as NSError
            print("\(error)")
            
        }
        
    }
    
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
    
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        switch(type) {
            
        case.insert:
            if let indexPath = newIndexPath {
                tableView.insertRows(at: [indexPath], with: .fade)
            }
            break
            
        case.delete:
            if let indexPath = indexPath {
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
            break
            
        case.update:
            if let indexPath = indexPath {
                let cell = tableView.cellForRow(at: indexPath) as! ItemSessionCell
                configureCell(cell: cell, indexPath: indexPath as NSIndexPath)
            }
            break
            
        case.move:
            if let indexPath = indexPath {
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
            if let indexPath = newIndexPath {
                tableView.insertRows(at: [indexPath], with: .fade)
            }
            break
            
            
        }
        
    }
    
    @IBAction func deletePressed(_ sender: UIBarButtonItem) {
        
        deleteButton.isEnabled = false
        let entities = ["Session", "Characteristic", "SensorData"]
        
        //        for entity in entities{
        //            // Create Fetch Request
        //            let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
        //            // Create Batch Delete Request
        //            let request = NSBatchDeleteRequest(fetchRequest: fetch)
        //
        //            do {
        //
        //                try context.execute(request)
        //
        //            } catch {
        //
        //                let error = error as NSError
        //                print("\(error)")
        //            }
        //
        //        }
        
        for entity in entities{
            // Initialize Fetch Request
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
            
            // Configure Fetch Request
            fetchRequest.includesPropertyValues = false
            
            do {
                let items = try context.fetch(fetchRequest) as! [NSManagedObject]
                
                for item in items {
                    context.delete(item)
                }
                
                // Save Changes
                try context.save()
                
            } catch {
                // Error Handling
                // ...
            }
        }
        
        attemptFetch()
        tableView.reloadData()
        deleteButton.isEnabled = true
        print ("All data deleted!")
    }
    
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            context.delete(controller.fetchedObjects![indexPath.row])
            do {
                try context.save()
                tableView.reloadData()
            } catch let error as NSError {
                print("Could not save. \(error), \(error.userInfo)")
            }
        }
        
    }
    
    @IBAction func exportPressed(_ sender: Any) {
        FileManager.default.clearTmpDirectory()
        
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let sessionDate = formatter.string(from: date)
        
        let fileName = "Motion-sessions_\(sessionDate).csv"
        let path = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
        var csvText = "SessionID,SessionDate,SessionDuration,SessionFrequency,RecordID,Timestamp,timeIntervalSince1970,GyroX,GyroY,GyroZ,AccX,AccY,AccZ,MagX,MagY,MagZ,Pressure,WatchTimestamp,WatchtImeIntervalSince1970,WatchGyroX,WatchGyroY,WatchGyroZ,WatchAccX,WatchAccY,WatchAccZ\n"
        
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSS"
        
        let fetchRequestSession = NSFetchRequest<NSFetchRequestResult>(entityName: "Session")
        
        // Add Sort Descriptors
        let sortDescriptorSession = NSSortDescriptor(key: "id", ascending: true)
        fetchRequestSession.sortDescriptors = [sortDescriptorSession]
        
        
        do {
            let sessions = try context.fetch(fetchRequestSession) as! [Session]
            
            for session in sessions {
                
                let sessionID = "\(session.id)"
                let sessionDate = "\(df.string(from: session.date! as Date))"
                let sessionDuration = "\(session.duration!)"
                let sessionFrequency = "\(session.frequency)"
                let recordID = "\(session.recordID)"
                let sessionInfoString = "\(sessionID),\(sessionDate),\(sessionDuration),\(sessionFrequency),\(recordID),"
                // let sessionType = session.type
                
                var SensorOutputs1 = [SensorOutput]()
                var SensorOutputs2 = [SensorOutput]()
                
                var sensorDatas = session.toSensorData!.allObjects as! [SensorData]
                sensorDatas.sort(by: { $0.timeStamp?.compare($1.timeStamp! as Date) == ComparisonResult.orderedAscending })
                
                for sensorData in sensorDatas {
                    let sensorOutput = getSensorOutput(sensorData: sensorData)
                    
                    
                    if sensorData.toSensor?.id == 1 {
                        SensorOutputs1.append(sensorOutput)
                    } else if sensorData.toSensor?.id == 2 {
                        SensorOutputs2.append(sensorOutput)
                    }
                    
                }// for sensorData
                
                let maxArray = max(SensorOutputs1.count, SensorOutputs2.count)
                
                for i in 0..<maxArray {
                    
                    var sensorsInfo1 = ""
                    var sensorsInfo2 = ""
                    
                    if  i < SensorOutputs1.count {
                        sensorsInfo1 = "\(df.string(from: (SensorOutputs1[i].timeStamp as Date?)!)),\(String(describing: SensorOutputs1[i].timeStamp!.timeIntervalSince1970)),\(String(describing: SensorOutputs1[i].gyroX!)),\(String(describing: SensorOutputs1[i].gyroY!)),\(String(describing: SensorOutputs1[i].gyroZ!)),\(String(describing: SensorOutputs1[i].accX!)),\(String(describing: SensorOutputs1[i].accY!)),\(String(describing: SensorOutputs1[i].accZ!)),\(String(describing: SensorOutputs1[i].magX!)),\(String(describing: SensorOutputs1[i].magY!)),\(String(describing: SensorOutputs1[i].magZ!)),\(String(describing: SensorOutputs1[i].pressure ?? 0.0)),"
                    }
                    
                    if i < SensorOutputs2.count {
                        sensorsInfo2 = "\(df.string(from: (SensorOutputs2[i].timeStamp as Date?)!)),\(String(describing: SensorOutputs2[i].timeStamp!.timeIntervalSince1970)),\(String(describing: SensorOutputs2[i].gyroX!)),\(String(describing: SensorOutputs2[i].gyroY!)),\(String(describing: SensorOutputs2[i].gyroZ!)),\(String(describing: SensorOutputs2[i].accX!)),\(String(describing: SensorOutputs2[i].accY!)),\(String(describing: SensorOutputs2[i].accZ!)),"
                    }
                    
                    
                    if sensorsInfo1 == "" {
                        sensorsInfo1 = ",,,,,,,,,,,"
                    }
                    if sensorsInfo2 == "" {
                        sensorsInfo2 = ",,,,,,,,,"
                    }
                    
                    
                    let sensorsInfo = sensorsInfo1 + sensorsInfo2
                    let endOfLine = "\n"
                    
                    csvText.append(sessionInfoString + sensorsInfo + endOfLine)
                    
                }
                
                
            }// for sessions
            
            
            do {
                try csvText.write(to: path!, atomically: true, encoding: String.Encoding.utf8)
            } catch {
                print("Failed to create file")
                print("\(error)")
            }
            print(path ?? "not found")
            
        } catch {
            print(error)
        }
        
        
        if let fileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName) as URL? {
            let objectsToShare = [fileURL]
            let activityController = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
            activityController.popoverPresentationController?.barButtonItem = self.navigationItem.rightBarButtonItem!
            
            let excludedActivities = [UIActivityType.postToFlickr, UIActivityType.postToWeibo, UIActivityType.message, UIActivityType.mail, UIActivityType.print, UIActivityType.copyToPasteboard, UIActivityType.assignToContact, UIActivityType.saveToCameraRoll, UIActivityType.addToReadingList, UIActivityType.postToFlickr, UIActivityType.postToVimeo, UIActivityType.postToTencentWeibo]
            
            activityController.excludedActivityTypes = excludedActivities
            present(activityController, animated: true, completion: nil)
        }
        
    } // export Pressed
    
    func getSensorOutput(sensorData: SensorData) -> SensorOutput {
        
        let sensorOutput = SensorOutput()
        sensorOutput.timeStamp = sensorData.timeStamp! as Date
        
        let characteristics = sensorData.toCharacteristic!.allObjects as! [Characteristic]
        
        for characteristic in characteristics {
            
            if characteristic.toCharacteristicName?.name == "Gyro" {
                sensorOutput.gyroX = characteristic.x
                sensorOutput.gyroY = characteristic.y
                sensorOutput.gyroZ = characteristic.z
                
            } else if characteristic.toCharacteristicName?.name == "Acc" {
                sensorOutput.accX = characteristic.x
                sensorOutput.accY = characteristic.y
                sensorOutput.accZ = characteristic.z
                
            } else if characteristic.toCharacteristicName?.name == "Mag" {
                sensorOutput.magX = characteristic.x
                sensorOutput.magY = characteristic.y
                sensorOutput.magZ = characteristic.z
            } else if characteristic.toCharacteristicName?.name == "Press" {
                sensorOutput.pressure = characteristic.x
            }
            
        }
        
        return sensorOutput
    }
    
    
}


extension FileManager {
    func clearTmpDirectory() {
        do {
            let tmpDirectory = try contentsOfDirectory(atPath: NSTemporaryDirectory())
            try tmpDirectory.forEach {[unowned self] file in
                let path = String.init(format: "%@%@", NSTemporaryDirectory(), file)
                try self.removeItem(atPath: path)
            }
        } catch {
            print(error)
        }
    }
}
