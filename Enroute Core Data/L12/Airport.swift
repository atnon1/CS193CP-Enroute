//
//  Airport.swift
//  Enroute Core Data
//
//  Created by Anton Makeev on 22.01.2021.
//

import CoreData
import Combine
import MapKit

extension Airport: MKAnnotation {
    public var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    public var title: String? { name ?? icao }
    public var subtitle: String? { location }
}

extension Airport {
    static func withICAO(_ icao: String, context: NSManagedObjectContext) -> Airport {
        // look up icao in Core Data
        let request = fetchRequest( NSPredicate(format: "icao_ = %@", icao) )
        let airport = (try? context.fetch(request)) ?? []
        if let airport = airport.first {
            // if found, return it
            return airport
        } else {
            // if not, create one and fetch from FlighAware
            let airport = Airport(context: context)
            airport.icao = icao
            AirportInfoRequest.fetch(icao) { airportInfo in
                self.update(from: airportInfo, context: context)
            }
            return airport
        }
    }
    
    static func fetchRequest(_ predicate: NSPredicate) -> NSFetchRequest<Airport> {
        let request = NSFetchRequest<Airport>(entityName: "Airport")
        request.predicate = predicate
        request.sortDescriptors = [NSSortDescriptor(key: "location", ascending: true)]
        return request
    }
    
    static func update(from info: AirportInfo, context: NSManagedObjectContext) {
        if let icao = info.icao {
            let airport = self.withICAO(icao, context: context)
            airport.latitude = info.latitude
            airport.longitude = info.longitude
            airport.location = info.location
            airport.name = info.name
            airport.timezone = info.timezone
            airport.objectWillChange.send()
            airport.flightsTo.forEach { $0.objectWillChange.send() }
            airport.flightsFrom.forEach { $0.objectWillChange.send() }
            try? context.save()
        }
    }
    
    var flightsTo: Set<Flight> {
        get { flightsTo_ as? Set<Flight> ?? [] }
        set { flightsTo_ = newValue as NSSet}
    }
    var flightsFrom: Set<Flight> {
        get { flightsFrom_ as? Set<Flight> ?? [] }
        set { flightsFrom_ = newValue as NSSet}
    }
    
}

extension Airport: Comparable {
    var icao: String {
        get { icao_! }
        set { icao_ = newValue }
    }
    
    var friendlyName: String {
        let friendly = AirportInfo.friendlyName(name: name ?? "", location: location ?? "")
        return friendly.isEmpty ? icao : friendly
    }
    
    public var id: String { icao }
    
    public static func < (lhs: Airport, rhs: Airport)  -> Bool {
        lhs.location ?? lhs.friendlyName < rhs.location ?? rhs.friendlyName
    }
}

extension Airport {
    func fetchIncomingFlights() {
        Self.flightAwareRequest?.stopFetching()
        if let context = managedObjectContext {
            Self.flightAwareRequest = EnrouteRequest.create(airport: icao, howMany: 120)
            Self.flightAwareRequest?.fetch(andRepeatEvery: 10)
            Self.flightAwareRequestCancellable = Self.flightAwareRequest?.results.sink { results in
                for faflight in results {
                    Flight.update(from: faflight, context: context)
                }
                do {
                    try context.save()
                } catch(let error) {
                    print("couldn't save flight update to CoreDate: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private static var flightAwareRequest: EnrouteRequest!
    private static var flightAwareRequestCancellable: AnyCancellable?
}
