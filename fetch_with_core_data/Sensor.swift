import Foundation

class Sensor: NSObject, NSCoding {
    
    static let fileURL = URL(fileURLWithPath: "/Users/amelialekston/Documents/fetching/sensors");
    
    struct Keys {
        
        static let name = "name";
        static let desc = "desc";
    }
    
    var name: String?
    var desc: String?
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.name, forKey: Keys.name)
        aCoder.encode(self.desc, forKey: Keys.desc)
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.name = aDecoder.decodeObject(forKey: Keys.name) as? String
        self.desc = aDecoder.decodeObject(forKey: Keys.desc) as? String
    }
    
    init(name: String, description: String) {
        self.name = name;
        self.desc = description;
    }
}
