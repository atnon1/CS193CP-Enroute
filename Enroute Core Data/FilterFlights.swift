//
//  FilterFlights.swift
//  Enroute
//
//  Created by Anton Makeev on 18.01.2021.
//  Copyright © 2021 Stanford University. All rights reserved.
//

import SwiftUI
import MapKit

struct FilterFlights: View {
    
    @FetchRequest(fetchRequest:  Airport.fetchRequest(.all)) var airports: FetchedResults<Airport>
    @FetchRequest(fetchRequest:  Airline.fetchRequest(.all)) var airlines: FetchedResults<Airline>
    
    @Binding var flightSearch: FlightSearch
    @Binding var isPresented: Bool    
    
    @State var draft: FlightSearch
    
    init(flightSearch: Binding<FlightSearch>, isPresented: Binding<Bool>) {
        _flightSearch = flightSearch
        _isPresented = isPresented
        _draft = State(wrappedValue: flightSearch.wrappedValue)
    }
    
    var destination: Binding<MKAnnotation?> {
        return Binding<MKAnnotation?>(
            get: { return draft.destination },
            set: { annotation in
                if let airport = annotation as? Airport {
                    draft.destination = airport
                }
            }
        )
    }

    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Picker("Destination", selection: $draft.destination) {
                        ForEach(airports.sorted()) { airport in
                            Text("\(airport.friendlyName)").tag(airport)
                        }
                    }
                    MapView(annotations: airports.sorted(), selection: destination)
                        .frame(minHeight: 400)
                }
                Section {
                    Picker("Origin", selection: $draft.origin) {
                        Text("Any").tag(Airport?.none)
                        ForEach(airports.sorted()) { (airport: Airport?) in
                            Text("\(airport?.friendlyName ?? "Any")").tag(airport)
                        }
                    }
                    Picker("Airline", selection: $draft.airline) {
                        Text("Any").tag(Airline?.none)
                        ForEach(airlines.sorted()) { (airline: Airline?) in
                            Text("\(airline?.friendlyName ??  "Any")").tag(airline)
                        }
                    }
                    Toggle(isOn: $draft.inTheAir) { Text("Enroute Only") }
                }
            }
            .navigationTitle("Filter Flights")
                .navigationBarItems(leading: cancel, trailing: done)
        }
    }
    
    var cancel: some View {
        Button("Cancel") {
            isPresented = false
        }
    }
    
    var done: some View {
        Button("Done") {
            if draft.destination != flightSearch.destination {
                draft.destination.fetchIncomingFlights()
            }
            flightSearch = draft
            isPresented = false
        }
    }
}

/*
struct FilterFlights_Previews: PreviewProvider {
    static var previews: some View {
        FilterFlights()
    }
}
*/
