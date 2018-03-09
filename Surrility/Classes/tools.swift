//
//  tools.swift
//  SurrealityAR
//
//  Created by Administrator on 1/24/18.
//  Copyright © 2018 SurrealMX. All rights reserved.
//

import Foundation
import UIKit

class tools{
    
    public static func convertCGFloat2UInt8(val: CGFloat) -> UInt8{
        let temp: CGFloat = val*255.0
        return UInt8(temp)
    }
    
    public static func convertArrayofUint8ToUInt64( number: [UInt8], R: UInt8, G: UInt8, B: UInt8, A: UInt8 )  -> [UInt8] {
        var result: [UInt8] = Array()
        
        //first add the float UInts
        for i in 0 ..< number.count {
            result.append(number[i])
        }
        result.append(R)
        result.append(G)
        result.append(B)
        result.append(A)
        
        return result
    }
}
