//
//  Flight.swift
//  Enroute Core Data
//
//  Created by Anton Makeev on 22.01.2021.
//

import CoreData
import Combine

extension Flight {
    var arrival: Date {
        get { arrival_ ?? Date(timeIntervalSinceReferenceDate: 0) }
        set { arrival_ = newValue }
    }
    var ident: String {
        get { ident_ ?? "Unknown" }
        set { ident_ = newValue }
    }
    var origin: Airport {
        get { origin_! }
        set { origin_ = newValue }
    }
    var destination: Airport {
        get { destination_! }
        set { destination_ = newValue }
    }
    var airline: Airline {
        get { airline_! }
        set { airline_ = newValue }
    }
    
    var number: Int {
        Int(String(ident.drop(while: { !$0.isNumber }))) ?? 0
    }
    
    static func fetchRequest(_ predicate: NSPredicate) -> NSFetchRequest<Flight> {
        let request = NSFetchRequest<Flight>(entityName: "Flight")
        request.predicate = predicate
        request.sortDescriptors = [NSSortDescriptor(key: "arrival_", ascending: true)]
        return request
    }
    
    @discardableResult
    static func update(from faflight: FAFlight, context: NSManagedObjectContext) -> Flight {
        let request = fetchRequest( NSPredicate(format: "ident_ = %@", faflight.ident) )
        let result = (try? context.fetch(request)) ?? []
        let flight = result.first ?? Flight(context: context)
        flight.ident = faflight.ident
        flight.origin = Airport.withICAO(faflight.origin, context: context)
        flight.destination = Airport.withICAO(faflight.destination, context: context)
        flight.arrival = faflight.arrival
        flight.departure = faflight.departure
        flight.filed = faflight.filed
        flight.aircraft = faflight.aircraft
        flight.airline = Airline.withCode(faflight.airlineCode, in: context)
        flight.objectWillChange.send()        
        return flight
    }
}
