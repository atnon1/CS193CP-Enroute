//
//  Enroute_Core_DataApp.swift
//  Enroute Core Data
//
//  Created by Anton Makeev on 21.01.2021.
//

import SwiftUI
import CoreData

@main
struct Enroute_Core_DataApp: App {
    
    let persistenceController = PersistenceController.shared
    var context: NSManagedObjectContext {
        persistenceController.container.viewContext
    }
    var body: some Scene {
        WindowGroup {
            FlightsEnrouteView(flightSearch: FlightSearch(destination: initialAirport))
                .environment(\.managedObjectContext, context)
        }
    }
    var initialAirport: Airport {
        let airport = Airport.withICAO("KSFO", context: context)
        airport.fetchIncomingFlights()
        return airport
    }
}
