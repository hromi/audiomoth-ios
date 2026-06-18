import Foundation

// NOAA solar calculations — matches the algorithm used in AudioMoth desktop app
struct SunCalculator {

    enum SunEvent {
        case sunrise, sunset, civilDawn, civilDusk, nauticalDawn, nauticalDusk, astronomicalDawn, astronomicalDusk
    }

    // Returns minutes-since-midnight for the requested event, or nil if sun stays above/below horizon
    static func eventTime(event: SunEvent, date: Date, latitude: Double, longitude: Double) -> Int? {
        let zenith: Double
        switch event {
        case .sunrise, .sunset:                         zenith = 90.833
        case .civilDawn, .civilDusk:                   zenith = 96.0
        case .nauticalDawn, .nauticalDusk:             zenith = 102.0
        case .astronomicalDawn, .astronomicalDusk:     zenith = 108.0
        }

        let isRise: Bool
        switch event {
        case .sunrise, .civilDawn, .nauticalDawn, .astronomicalDawn:    isRise = true
        case .sunset, .civilDusk, .nauticalDusk, .astronomicalDusk:      isRise = false
        }

        return noaaTime(julianDate: julianDay(from: date), latitude: latitude, longitude: longitude, zenith: zenith, isRise: isRise)
    }

    // MARK: - NOAA algorithm

    private static func noaaTime(julianDate jd: Double, latitude: Double, longitude: Double, zenith: Double, isRise: Bool) -> Int? {
        let lngHour = longitude / 15.0
        let t = jd + (isRise ? 6 : 18) / 24.0 - lngHour / 24.0

        let M = (0.9856 * t - 3.289).truncatingRemainder(dividingBy: 360.0)
        var L = M + 1.916 * sin(radians(M)) + 0.020 * sin(radians(2 * M)) + 282.634
        L = normalise(L, mod: 360)

        var RA = degrees(atan(0.91764 * tan(radians(L))))
        RA = normalise(RA, mod: 360)

        let Lquad = floor(L / 90) * 90
        let RAquad = floor(RA / 90) * 90
        RA = (RA + Lquad - RAquad) / 15.0

        let sinDec = 0.39782 * sin(radians(L))
        let cosDec = cos(asin(sinDec))

        let cosH = (cos(radians(zenith)) - sinDec * sin(radians(latitude))) / (cosDec * cos(radians(latitude)))
        guard cosH >= -1 && cosH <= 1 else { return nil }   // sun stays above/below horizon

        let H = isRise ? 360 - degrees(acos(cosH)) : degrees(acos(cosH))
        let T = H / 15.0 + RA - 0.06571 * t - 6.622
        var UT = T - lngHour
        UT = normalise(UT, mod: 24)

        return Int(UT * 60)
    }

    private static func julianDay(from date: Date) -> Double {
        let cal = Calendar(identifier: .gregorian)
        let comps = cal.dateComponents([.year, .month, .day], from: date)
        var y = comps.year!, m = comps.month!, d = comps.day!
        if m <= 2 { y -= 1; m += 12 }
        let A = Int(y / 100)
        let B = 2 - A + Int(A / 4)
        return floor(365.25 * Double(y + 4716)) + floor(30.6001 * Double(m + 1)) + Double(d) + Double(B) - 1524.5
    }

    private static func normalise(_ v: Double, mod: Double) -> Double {
        var r = v.truncatingRemainder(dividingBy: mod)
        if r < 0 { r += mod }
        return r
    }

    private static func radians(_ deg: Double) -> Double { deg * .pi / 180 }
    private static func degrees(_ rad: Double) -> Double { rad * 180 / .pi }
}
