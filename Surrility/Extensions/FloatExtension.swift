//
//  FloatExtension.swift
//  Surrility
//  https://stackoverflow.com/questions/46566343/how-to-convert-float-to-data-with-bigendian
//  https://stackoverflow.com/questions/38023838/round-trip-swift-number-types-to-from-data
//
//  Created by Administrator on 3/3/18.
//  Copyright © 2018 SurrealMX. All rights reserved.
//

import Foundation

extension Float {
    
    public mutating func toBytes() -> [UInt8] {
        var value = self.bitPattern.bigEndian  //when i transfer over network convention is to convert the data to bigEndian
        let data = Data(buffer: UnsafeBufferPointer(start: &value, count: 1))
        
        let byteArray = [UInt8](data)
        return byteArray
    }
    
    func format(f: String) -> String {
        return String(format: "%\(f)f", self)
    }
}
