import Foundation
import SwiftUI
import Combine

/// Manages free tier allowances and paywall triggers:
/// - Free tier: 5 scans per calendar day
/// - Free tier collection limit: 20 saved specimen items
/// - Pro tier: Unlimited daily scans and unlimited collection storage
@MainActor
public final class ScanAllowanceManager: ObservableObject {
    public static let shared = ScanAllowanceManager()
    
    public static let freeDailyScanLimit = 5
    public static let freeCollectionLimit = 20
    
    private let dailyScansKey = "GemIDScanner_DailyScanCount"
    private let lastScanDateKey = "GemIDScanner_LastScanDate"
    
    @Published public var remainingDailyScans: Int = freeDailyScanLimit
    @Published public var dailyScansUsed: Int = 0
    @Published public var isProUnlocked: Bool = false
    
    public init() {
        refreshDailyAllowance()
    }
    
    public func updateProStatus(isPro: Bool) {
        self.isProUnlocked = isPro
    }
    
    public func canPerformScan() -> Bool {
        if isProUnlocked { return true }
        refreshDailyAllowance()
        return dailyScansUsed < Self.freeDailyScanLimit
    }
    
    public func recordScan() {
        guard !isProUnlocked else { return }
        refreshDailyAllowance()
        dailyScansUsed += 1
        UserDefaults.standard.set(dailyScansUsed, forKey: dailyScansKey)
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: lastScanDateKey)
        remainingDailyScans = max(0, Self.freeDailyScanLimit - dailyScansUsed)
    }
    
    public func canAddToCollection(currentCollectionCount: Int) -> Bool {
        if isProUnlocked { return true }
        return currentCollectionCount < Self.freeCollectionLimit
    }
    
    public func refreshDailyAllowance() {
        let calendar = Calendar.current
        let now = Date()
        
        let lastScanTimestamp = UserDefaults.standard.double(forKey: lastScanDateKey)
        if lastScanTimestamp > 0 {
            let lastDate = Date(timeIntervalSince1970: lastScanTimestamp)
            if !calendar.isDate(lastDate, inSameDayAs: now) {
                // New day: reset counter
                UserDefaults.standard.set(0, forKey: dailyScansKey)
                UserDefaults.standard.set(now.timeIntervalSince1970, forKey: lastScanDateKey)
                dailyScansUsed = 0
                remainingDailyScans = Self.freeDailyScanLimit
                return
            }
        }
        
        dailyScansUsed = UserDefaults.standard.integer(forKey: dailyScansKey)
        remainingDailyScans = max(0, Self.freeDailyScanLimit - dailyScansUsed)
    }
    
    public var nextDailyResetDate: Date {
        let calendar = Calendar.current
        let now = Date()
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now),
           let nextMidnight = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: tomorrow) {
            return nextMidnight
        }
        return now.addingTimeInterval(86400)
    }
    
    public var formattedResetCountdown: String {
        let remainingSeconds = max(0, Int(nextDailyResetDate.timeIntervalSince(Date())))
        let hours = remainingSeconds / 3600
        let minutes = (remainingSeconds % 3600) / 60
        return "\(hours)h \(minutes)m"
    }
    
    #if DEBUG
    public func resetDailyAllowanceForTesting() {
        UserDefaults.standard.set(0, forKey: dailyScansKey)
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: lastScanDateKey)
        dailyScansUsed = 0
        remainingDailyScans = Self.freeDailyScanLimit
    }
    #endif
}
