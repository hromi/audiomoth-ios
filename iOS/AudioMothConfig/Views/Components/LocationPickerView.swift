import SwiftUI
import MapKit
import CoreLocation

struct LocationPickerView: View {

    @Binding var latitude: Coordinate
    @Binding var longitude: Coordinate
    @Environment(\.dismiss) private var dismiss

    @State private var position: MapCameraPosition = .automatic
    @State private var pinCoordinate: CLLocationCoordinate2D = .init(latitude: 0, longitude: 0)
    @State private var latText = ""
    @State private var lonText = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Map(position: $position) {
                    Annotation("", coordinate: pinCoordinate) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.title)
                            .foregroundStyle(.red)
                    }
                }
                .frame(maxHeight: .infinity)
                .onTapGesture { location in
                    // MapKit tap-to-place requires MapReader in iOS 17+
                }
                .overlay(alignment: .bottomTrailing) {
                    Button {
                        if let loc = CLLocationManager().location {
                            pinCoordinate = loc.coordinate
                            updateTextFields()
                        }
                    } label: {
                        Image(systemName: "location.fill")
                            .padding(10)
                            .background(.regularMaterial, in: Circle())
                    }
                    .padding()
                }

                Divider()

                Form {
                    Section("Coordinates") {
                        HStack {
                            Text("Latitude")
                            Spacer()
                            TextField("0.0000", text: $latText)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 120)
                                .onChange(of: latText) { _, new in
                                    if let v = Double(new) { pinCoordinate.latitude = v }
                                }
                        }
                        HStack {
                            Text("Longitude")
                            Spacer()
                            TextField("0.0000", text: $lonText)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 120)
                                .onChange(of: lonText) { _, new in
                                    if let v = Double(new) { pinCoordinate.longitude = v }
                                }
                        }
                    }
                }
                .frame(height: 160)
            }
            .navigationTitle("Select Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        latitude  = Coordinate(decimal: pinCoordinate.latitude)
                        longitude = Coordinate(decimal: pinCoordinate.longitude)
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .onAppear {
            pinCoordinate = CLLocationCoordinate2D(
                latitude: latitude.decimalDegrees,
                longitude: longitude.decimalDegrees
            )
            position = .camera(.init(centerCoordinate: pinCoordinate, distance: 1_000_000))
            updateTextFields()
        }
    }

    private func updateTextFields() {
        latText = String(format: "%.4f", pinCoordinate.latitude)
        lonText = String(format: "%.4f", pinCoordinate.longitude)
    }
}
