import Vapor

func routes(_ app: Application) throws {
    
    app.get("weather_advice") { req -> Advice in
        let city = try req.content.get(String.self, at: "city")
        let date = try req.content.get(String.self, at: "date")
        
        let formatted = date.components(separatedBy: "-")
        
        let data = try Data(contentsOf: URL(string: "https://www.metaweather.com/api/location/search/?query=\(city)")!)
        
        let woeid = try JSONDecoder().decode([City].self, from: data)[0].woeid
        
        let replyData = try Data(contentsOf: URL(string: "https://www.metaweather.com/api/location/\(woeid)/\(formatted[2])/\(formatted[1])/\(formatted[0])/")!)
        
        let reply = try JSONDecoder().decode([Weather].self, from: replyData).sorted()[0]
        
        let temp = reply.the_temp ?? (reply.min_temp + reply.max_temp) / 2
        
        let conclusion = Advice(should_wear_hat: (((5...15).contains(temp) && reply.wind_speed > 5) || temp < 5),
                                should_wear_sunglasses: reply.weather_state_abbr == "c",
                                should_take_umbrella: ("sn, sl, h, hr, lr, s".contains(reply.weather_state_abbr) && temp > 0 && reply.wind_speed < 7),
                                should_wear_raincoat: ("sn, sl, h, hr, lr, s".contains(reply.weather_state_abbr) && temp > 0 && reply.wind_speed >= 7),
                                should_wear_scarf: (0...10).contains(temp) && (reply.wind_speed > 4) || (temp < 0),
                                should_wear_panama: reply.weather_state_abbr == "c" && temp > 30,
                                should_use_sunscreen: reply.weather_state_abbr == "c" && temp > 23)
        
        return conclusion
    }
    
}
struct Weather: Codable, Comparable {
    
    static func < (lhs: Weather, rhs: Weather) -> Bool {
        let RFC3339DateFormatter = DateFormatter()
        RFC3339DateFormatter.locale = Locale(identifier: "en_US_POSIX")
        RFC3339DateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        RFC3339DateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        guard let ldate = RFC3339DateFormatter.date(from: lhs.created) else { fatalError() }
        guard let rdate = RFC3339DateFormatter.date(from: rhs.created) else { fatalError() }
        
        return ldate < rdate
    }
    
    let id: Int
    let weather_state_name: String
    let weather_state_abbr: String
    let wind_direction_compass: String
    let created: String
    let applicable_date: String
    let min_temp: Double
    let max_temp: Double
    let the_temp: Double?
    let wind_speed: Double
    let wind_direction: Double
    let air_pressure: Double?
    let humidity: Double
    let visibility: Double?
    let predictability: Double
}

struct City: Codable {
    let title: String
    let location_type: String
    let woeid: Int
    let latt_long: String
}

struct Advice: Content {
    let should_wear_hat: Bool
    let should_wear_sunglasses: Bool
    let should_take_umbrella: Bool
    let should_wear_raincoat: Bool
    let should_wear_scarf: Bool
    let should_wear_panama: Bool
    let should_use_sunscreen: Bool
}
