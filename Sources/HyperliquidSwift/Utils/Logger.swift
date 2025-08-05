import Foundation

/// Simple logging utility
public enum Logger {
    
    public enum Level: String, Sendable {
        case debug = "DEBUG"
        case info = "INFO"
        case warning = "WARNING"
        case error = "ERROR"
    }
    
    public static let isEnabled = false
    public static let minLevel: Level = .info
    
    public static func debug(_ message: String, file: String = #file, line: Int = #line) {
        log(level: .debug, message: message, file: file, line: line)
    }
    
    public static func info(_ message: String, file: String = #file, line: Int = #line) {
        log(level: .info, message: message, file: file, line: line)
    }
    
    public static func warning(_ message: String, file: String = #file, line: Int = #line) {
        log(level: .warning, message: message, file: file, line: line)
    }
    
    public static func error(_ message: String, error: Error? = nil, file: String = #file, line: Int = #line) {
        var fullMessage = message
        if let error = error {
            fullMessage += " | Error: \(error.localizedDescription)"
        }
        log(level: .error, message: fullMessage, file: file, line: line)
    }
    
    private static func log(level: Level, message: String, file: String, line: Int) {
        guard isEnabled else { return }
        guard shouldLog(level: level) else { return }
        
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        let timestamp = DateFormatter.logFormatter.string(from: Date())
        
        print("[\(timestamp)] [\(level.rawValue)] [\(fileName):\(line)] \(message)")
    }
    
    private static func shouldLog(level: Level) -> Bool {
        let levels: [Level] = [.debug, .info, .warning, .error]
        guard let currentIndex = levels.firstIndex(of: level),
              let minIndex = levels.firstIndex(of: minLevel) else {
            return false
        }
        return currentIndex >= minIndex
    }
}

// MARK: - DateFormatter Extension

extension DateFormatter {
    static let logFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()
}
