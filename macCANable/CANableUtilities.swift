func GenerateCANableMessageFromData(id: String, dlc: String, d: [String]) -> String? {
    /*
     * Extended Message format: TIIIIIIIINDD...
     * where
     *     T = literal "T" for extended transmit command
     *   IIIIIII = 8-digit ID, 29-bit (hex, uppercase)
     *     N = 1-digit DLC
     *    DD = 2-digit data (hex, uppercase)
     *   ... = additional data bytes as governed by DLC
     */
    
    guard id.count == 8 else { return nil }                                // 8 hex digits for extended ID
    guard Constants.HexadecimalDigits.union(id.uppercased()).count == 16 else { return nil }
    guard let idVal = Int(id, radix: 16), idVal <= 0x1FFFFFFF else { return nil }  // max 29-bit value
    guard dlc.count == 1 else { return nil }
    guard Constants.DecimalDigits.union(dlc).count == 10 else { return nil }
    guard let n = Int(dlc), n >= 0 && n <= 8 else { return nil }          // DLC can be zero too
    guard d.count == n else { return nil }
    for item in d {
        guard item.count == 2 else { return nil }
        guard Constants.HexadecimalDigits.union(item.uppercased()).count == 16 else { return nil }
    }
    
    var message = "T" + id.uppercased() + dlc
    for item in d {
        message.append(item.uppercased())
    }
    
    return message
}

func GenerateCANableDataFromMessage(_ message: String) -> (id: String, dlc: String, d: [String])? {
    /*
     * Extended Message format: TIIIIIIIINDD...
     * where
     *     T = literal "T" for extended transmit command
     *   IIIIIII = 8-digit ID, 29-bit (hex, uppercase)
     *     N = 1-digit DLC
     *    DD = 2-digit data (hex, uppercase)
     *   ... = additional data bytes as governed by DLC
     */
    
    guard message.count >= 10 else { return nil } // T + 8 hex + DLC at least
    
    // Strip off "T" prefix
    var parts = BreakString(message, atOffset: 1)
    var str = parts.suffix
    
    // Extract ID value
    parts = BreakString(str, atOffset: 8)
    let id = parts.prefix.uppercased()
    guard Constants.HexadecimalDigits.union(id).count == 16 else { return nil }
    guard let idVal = Int(id, radix: 16), idVal <= 0x1FFFFFFF else { return nil }
    str = parts.suffix
    
    // Extract DLC value
    parts = BreakString(str, atOffset: 1)
    let dlc = parts.prefix
    guard let n = Int(dlc), n >= 0 && n <= 8 else { return nil }
    str = parts.suffix
    guard 2 * n == str.count else { return nil }
    
    // Extract data bytes
    var d: [String] = []
    for _ in 1...n {
        parts = BreakString(str, atOffset: 2)
        guard Constants.HexadecimalDigits.union(parts.prefix.uppercased()).count == 16 else { return nil }
        d.append(parts.prefix.uppercased())
        str = parts.suffix
    }
    
    return (id, dlc, d)
}
