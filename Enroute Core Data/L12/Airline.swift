//
//  Airline.swift
//  Enroute Core Data
//
//  Created by Anton Makeev on 22.01.2021.
//

import CoreData
import Combine

extension Airline: Comparable {
    var code: String {
        get { code_! }
        set { code_ = newValue }
    }
    
    var name: String {
        get { name_ ?? code }
        set { name_ = newValue}
    }
    var shortname: String {
        get { (shortname_ ?? "").isEmpty ? name : shortname_! }
        set { shortname_ = newValue }
    }
    var flights: Set<Flight> {
        get { flights_ as? Set<Flight> ?? [] }
        set { flights_ = newValue as NSSet }
    }
    var friendlyName: String { shortname.isEmpty ? name : shortname }
    
    public var id: String { code }
    
    public static func < (lhs: Airline, rhs: Airline) -> Bool {
        lhs.name < rhs.name
    }
    
    static func fetchRequest(_ predicate: NSPredicate) -> NSFetchRequest<Airline> {
        let request = NSFetchRequest<Airline>(entityName: "Airline")
        request.predicate = predicate
        request.sortDescriptors = [NSSortDescriptor(key: "name_", ascending: true)]
        return request
    }
    
    static func withCode(_ code: String, in context: NSManagedObjectContext) -> Airline {
        let request = fetchRequest( NSPredicate(format: "code_ = %@", code) )
        let result = (try? context.fetch(request)) ?? []
        if let airline = result.first {
            // if found, return it
            return airline
        } else {
            // if not, create one and fetch from FlighAware
            let airline = Airline(context: context)
            airline.code = code
            AirlineInfoRequest.fetch(code) { info in
                self.update(from: info, context: context)
            }
            return airline
        }
    }
    
    static func update(from info: AirlineInfo, context: NSManagedObjectContext) {
        if let code = info.code {
            let airline = self.withCode(code, in: context)
            airline.name = info.name
            airline.shortname = info.shortname
            airline.objectWillChange.send()
            airline.flights.forEach { $0.objectWillChange.send() }
            try? context.save()
        }
        return 
    }
    
    
}
