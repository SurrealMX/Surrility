//
//  FloatExtension.swift
//  Surrility
//
//  Created by Administrator on 3/3/18.
//  Copyright © 2018 SurrealMX. All rights reserved.
//

import Foundation

extension Float {
    public mutating func toBytes() -> [UInt8] {
        let data = Data(buffer: UnsafeBufferPointer(start: &self, count: 1))
        let byteArray = [UInt8](data)
        return byteArray
    }
}
