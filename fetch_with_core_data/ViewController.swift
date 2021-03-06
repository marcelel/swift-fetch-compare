//
//  ViewController.swift
//  fetching
//
//  Created by Amelia Lekston on 10/01/2020.
//  Copyright © 2020 Marcel Lekston. All rights reserved.
//

import UIKit
import CoreData

class ViewController: UIViewController {
   
    @IBOutlet weak var archivingGenerateResult: UILabel!
    @IBOutlet weak var archivingResult: UILabel!
    @IBOutlet weak var sqliteGenerateResult: UILabel!
    @IBOutlet weak var sqliteResult: UILabel!
    @IBOutlet weak var coreGenerateResult: UILabel!
    @IBOutlet weak var coreResult: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func onArchivingGenerateButtonClicked(_ sender: Any) {
        let startTime = Date()
        
        let sensors = sensorsSetup();
        let readings = readingsSetup();
        do {
            let sensorsData = try NSKeyedArchiver.archivedData(withRootObject: sensors, requiringSecureCoding: false)
            try sensorsData.write(to: Sensor.fileURL)
            let readingsData = try NSKeyedArchiver.archivedData(withRootObject: readings, requiringSecureCoding: false)
            try readingsData.write(to: Reading.fileURL)
        } catch {
            print("Couldn't write file")
        }
        
        let finishTime = Date()
        let measuredTime = finishTime.timeIntervalSince(startTime)
        archivingGenerateResult.text = String(measuredTime)
    }
    
    @IBAction func onArchivingButtonClicked(_ sender: Any) {
        var startTime: Date
        var finishTime: Date
        var measuredTime: Double
        var totalTime: Double = 0
        var readings: [Reading] = []
        
        do {
            let readingData = try Data(contentsOf: Reading.fileURL)
            readings = try (NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(readingData) as? [Reading])!
        } catch {
            print("Couldn't read file")
        }
        
        startTime = Date()
        print("Archiving max date: \(readings.max(by: {(r1, r2) -> Bool in return r1.date < r2.date})!.date)")
        print("Archiving min date: \(readings.min(by: {(r1, r2) -> Bool in return r1.date < r2.date})!.date)")
        finishTime = Date()
        measuredTime = finishTime.timeIntervalSince(startTime)
        totalTime += measuredTime
        print("Archiving query1: \(measuredTime) \n")
        
        startTime = Date()
        print("Archiving average value: \(Double(readings.reduce(0, {$0 + $1.value})) / Double(readings.count))")
        finishTime = Date()
        measuredTime = finishTime.timeIntervalSince(startTime)
        totalTime += measuredTime
        print("Archiving query2: \(measuredTime) \n")
        
        startTime = Date()
        for reading in Dictionary(grouping: readings, by: {$0.sensorName}) {
            let average = Double(reading.value.reduce(0, {$0 + $1.value})) / Double(reading.value.count)
            print("Archiving sensor \(reading.key) - readings: \(reading.value.count), average \(average)")
        }
        finishTime = Date()
        measuredTime = finishTime.timeIntervalSince(startTime)
        totalTime += measuredTime
        print("Archiving query3: \(measuredTime) \n")
        
        archivingResult.text = String(totalTime);
    }
    
    @IBAction func onSQLiteGenerateButtonClicked(_ sender: Any) {
        let startTime = Date()
        
        let sensors = sensorsSetup();
        let readings = readingsSetup();
        let db = openSQLite()!
        var query = "";
        sqlite3_exec(db, "BEGIN TRANSACTION", nil, nil, nil);
        query += "DROP TABLE IF EXISTS readings; "
        query += "DROP TABLE IF EXISTS sensors; "
        query += "CREATE TABLE sensors (name VARCHAR(3) PRIMARY KEY, desc VARCHAR(20)); "
        query += "CREATE TABLE readings (id INTEGER PRIMARY KEY AUTOINCREMENT, timestamp NUMERIC, value REAL, sensor VARCHAR(3), FOREIGN KEY(sensor) REFERENCES sensors(name)); "
        for sensor in sensors {
            query += "INSERT INTO sensors (name, desc) values ('\(sensor.name)', '\(sensor.desc)'); "
        }
        for reading in readings {
            query += "INSERT INTO readings (timestamp, value, sensor) values (\(reading.date.timeIntervalSince1970), \(reading.value), '\(reading.sensorName)'); "
        }
        sqlite3_exec(db, query, nil, nil, nil)
        sqlite3_exec(db, "COMMIT TRANSACTION", nil, nil, nil);
        
        let finishTime = Date()
        let measuredTime = finishTime.timeIntervalSince(startTime)
        sqliteGenerateResult.text = String(measuredTime)
    }
    
    @IBAction func onSQLiteButtonClicked(_ sender: Any) {
        var startTime: Date
        var finishTime: Date
        var measuredTime: Double
        var totalTime: Double = 0
        let db = openSQLite()!
        
        startTime = Date()
        let maxMinQuery = "SELECT max(timestamp) as max, min(timestamp) as min, avg(value) as avg from readings;"
        sqlite3_exec(db, maxMinQuery, {_, _, values, _ in
            let max = String(cString: values![0]!)
            let min = String(cString: values![1]!)
            print("SQLite max date: \(Date(timeIntervalSince1970: Double(max)!))")
            print("SQLite min date: \(Date(timeIntervalSince1970: Double(min)!))")
            return 0
         }, nil, nil)
        finishTime = Date()
        measuredTime = finishTime.timeIntervalSince(startTime)
        totalTime += measuredTime
        print("SQLite query1: \(measuredTime) \n")
        
        startTime = Date()
        let avgQuery = "SELECT avg(value) as avg from readings;"
        sqlite3_exec(db, avgQuery, {_, _, values, _ in
            let avg = String(cString: values![0]!)
            print("SQLige average value: \(avg)")
            return 0
         }, nil, nil)
        finishTime = Date()
        measuredTime = finishTime.timeIntervalSince(startTime)
        totalTime += measuredTime
        print("SQLite query2: \(measuredTime) \n")
        
        startTime = Date()
        let selectSensorsQuery = "SELECT sensor, count(*) as readings, avg(value) as avg from readings group by sensor;"
        sqlite3_exec(db, selectSensorsQuery, {_, _, values, _ in
            let sensor = String(cString: values![0]!)
            let readings = String(cString: values![1]!)
            let avg = String(cString: values![2]!)
            print("Archiving sensor \(sensor) - readings: \(readings), average \(avg)")
            return 0
        }, nil, nil)
        finishTime = Date()
        measuredTime = finishTime.timeIntervalSince(startTime)
        totalTime += measuredTime
        print("SQLite query3: \(measuredTime) \n")

        sqliteResult.text = String(totalTime);
    }
    
    @IBAction func onCoreGenerateButtonClicked(_ sender: Any) {
        deleteAllCoreRecords(entity: "SensorCoreData")
        deleteAllCoreRecords(entity: "ReadingCoreData")
        
        let startTime = Date()
        
        guard let ad = UIApplication.shared.delegate  as? AppDelegate else { return}
        let moc = ad.persistentContainer.viewContext
        let sensors = sensorsSetup();
        let readings = readingsSetup();
        var sensorsCoreData: [SensorCoreData] = []
        
        for sensor in sensors {
            let sensorCoreData = SensorCoreData(context: moc)
            sensorCoreData.desc = sensor.desc
            sensorCoreData.name = sensor.name
            sensorsCoreData.append(sensorCoreData)
        }
        for reading in readings {
            let readingCoreData = ReadingCoreData(context: moc)
            readingCoreData.sensor = sensorsCoreData.randomElement()
            readingCoreData.date = reading.date
            readingCoreData.value = reading.value
        }
        
        try? moc.save()
        let finishTime = Date()
        let measuredTime = finishTime.timeIntervalSince(startTime)
        coreGenerateResult.text = String(measuredTime)
    }
    
    @IBAction func onCoreButtonClicked(_ sender: Any) {
        var startTime: Date
        var finishTime: Date
        var measuredTime: Double
        var totalTime: Double = 0
        guard let ad = UIApplication.shared.delegate  as? AppDelegate else { return}
        let moc = ad.persistentContainer.viewContext
        
        startTime = Date()
        let frMinMax = NSFetchRequest<NSDictionary>(entityName: "ReadingCoreData")
        let edMax = NSExpressionDescription()
        edMax.name = "maxDate"
        edMax.expression = NSExpression(format: "@max.date")
        edMax.expressionResultType = .dateAttributeType
        let edMin = NSExpressionDescription()
        edMin.name = "minDate"
        edMin.expression = NSExpression(format: "@min.date")
        edMin.expressionResultType = .dateAttributeType
        frMinMax.propertiesToFetch = [edMax, edMin]
        frMinMax.resultType = .dictionaryResultType
        let minMaxQueryResults = (try! moc.fetch(frMinMax)).first!
        print("Core max date: \(String(describing: minMaxQueryResults["maxDate"]!))")
        print("Core min date: \(String(describing: minMaxQueryResults["minDate"]!))")
        finishTime = Date()
        measuredTime = finishTime.timeIntervalSince(startTime)
        totalTime += measuredTime
        print("Core query1: \(measuredTime) \n")
        
        startTime = Date()
        let frAvg = NSFetchRequest<NSDictionary>(entityName: "ReadingCoreData")
        let edAvg = NSExpressionDescription()
        edAvg.name = "average"
        edAvg.expression = NSExpression(format: "@avg.value")
        frAvg.propertiesToFetch = [edAvg]
        frAvg.resultType = .dictionaryResultType
        let avgQueryResults = (try! moc.fetch(frAvg)).first!
        print("Core average value: \(String(describing: avgQueryResults["average"]!))")
        finishTime = Date()
        measuredTime = finishTime.timeIntervalSince(startTime)
        totalTime += measuredTime
        print("Core query2: \(measuredTime) \n")
        
        let frSensor = NSFetchRequest<NSDictionary>(entityName: "ReadingCoreData")
        frSensor.propertiesToGroupBy = ["sensor"]
        frSensor.returnsObjectsAsFaults = false
        frSensor.resultType = .dictionaryResultType
        let eCount = NSExpression(forFunction: "count:", arguments: [NSExpression(forKeyPath: "value")])
        let edCount = NSExpressionDescription()
        edCount.expression = eCount
        edCount.name = "count"
        let eSensorAvg = NSExpression(format: "@avg.value")
        let edSensorAvg = NSExpressionDescription()
        edSensorAvg.expression = eSensorAvg
        edSensorAvg.name = "avg"
        edSensorAvg.expressionResultType = .floatAttributeType
        frSensor.propertiesToFetch = ["sensor", edCount, edSensorAvg]
        let sensorsResults = (try! moc.fetch(frSensor))
        for sensorResult in sensorsResults {
            let sensorId = sensorResult.value(forKey: "sensor") as! NSManagedObjectID
            let sensor = (moc.object(with: sensorId)) as! SensorCoreData
            let readings = sensorResult["count"]!
            let average = sensorResult["avg"]!
            print("Core sensor \(sensor.name!) - readings: \(readings), average \(average)")
        }
        finishTime = Date()
        measuredTime = finishTime.timeIntervalSince(startTime)
        totalTime += measuredTime
        print("Core query3: \(measuredTime) \n")

        coreResult.text = String(totalTime);
    }
    
    func sensorsSetup() -> [Sensor] {
        var sensors = [Sensor]();
        for n in 1...20 {
            sensors.append(Sensor(name: "S" + String(n), description: "Sensor number n" + String(n)))
        }
        return sensors;
    }
    
    func readingsSetup() -> [Reading] {
        var readings = [Reading]();
        for _ in 1...100000 {
            let sensorName = "S" + String(Int.random(in: 1...20));
            let date = generateRandomDate();
            let value = Double.random(in: 0...100);
            readings.append(Reading(date: date, sensorName: sensorName, value: value))
        }
        return readings;
    }
    
    func generateRandomDate() -> Date {
        let to = Date().timeIntervalSince1970
        let from = to - 31556926.0
        return Date(timeIntervalSince1970: Double.random(in: from...to))
    }
    
    func deleteAllCoreRecords(entity: String) {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let context = delegate.persistentContainer.viewContext

        let deleteFetch = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: deleteFetch)

        do {
            try context.execute(deleteRequest)
            try context.save()
        } catch {
            print ("There was an error")
        }
    }
    
    func openSQLite() -> OpaquePointer? {
        let docDir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let dbFilePath = NSURL(fileURLWithPath: docDir).appendingPathComponent("demo.db")?.path
        var db: OpaquePointer? = nil
        if sqlite3_open(dbFilePath, &db) == SQLITE_OK {
            return db;
        } else {
            print("error connect to sqlite db")
            return nil;
        }
    }
}
