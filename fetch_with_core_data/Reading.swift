import Foundation

class Reading: NSObject, NSCoding {
    
    static let fileURL = URL(fileURLWithPath: "/Users/amelialekston/Documents/fetching/reading");
    
    struct Keys {
        
        static let date = "date"
        static let sensorName = "sensorName"
        static let value = "value"
    }
    
    let date: Date
    let sensorName: String
    let value: Double
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.date, forKey: Keys.date)
        aCoder.encode(self.sensorName, forKey: Keys.sensorName)
        aCoder.encode(self.value, forKey: Keys.value)
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.date = aDecoder.decodeObject(forKey: Keys.date) as! Date
        self.sensorName = aDecoder.decodeObject(forKey: Keys.sensorName) as! String
        self.value = aDecoder.decodeDouble(forKey: Keys.value)
    }
    
    init(date: Date, sensorName: String, value: Double) {
        self.date = date;
        self.sensorName = sensorName;
        self.value = value;
    }
}
