//
//  CloudVector.swift
//  SurrealityAR
//
//  Created by Michael Archer on 1/22/18.
//  Copyright © 2018 SurrealMX. All rights reserved.
//

import Foundation
import UIKit
import SceneKit

class CloudFrame : Codable {
    var t: Float
    var p: [UInt64]//[Float]
    var height: Int
    var width: Int
    var fx, fy, x0, y0: Float
    var min, max, range: Float
    var BoundA, BoundB: Float
    
    init(time: Float, vals: [UInt64], height: Int, width: Int, matrix: matrix_float3x3, parameters: [Float], BoundA: Float, BoundB: Float){
        self.t = time
        self.height = height
        self.width = width
        self.p = vals
        
        self.min = parameters[0]
        self.max = parameters[1]
        self.range = parameters[2]
        
        let col1 = matrix.columns.0
        let col2 = matrix.columns.1
        let col3 = matrix.columns.2
        
        self.fx = col1.x
        self.fy = col2.y
        self.x0 = col3.x
        self.y0 = col3.y
        
        self.BoundA = BoundA
        self.BoundB = BoundB
    }
}

extension CloudFrame {
    
    static func compileFrame(DepthBuffer: [UInt32], ColorBuffer: [UInt32], time: Float, intrinsicMatrix: matrix_float3x3, depthMapParamers: [Float], height: Int, width: Int) -> CloudFrame? {
        
            var vals: [UInt64] = []
            
            for y in 0 ..< height {
                for x in 0 ..< width {
                    let idx = y * width + x
                    
                    var aDepthVals: [UInt8] = tools.splitUint32(number: DepthBuffer[idx])
                    let aColorVals: [UInt8] = tools.splitUint32(number: ColorBuffer[idx])

                    aDepthVals.append(contentsOf: aColorVals)
                    
                    //let aVal: Double = Double(aDepthVals)!
                    let data = Data(bytes: aDepthVals)
                    let aVal = UInt64(bigEndian: data.withUnsafeBytes { $0.pointee })
                    
                    vals.append(aVal)
                    
                }
            }
        return CloudFrame(time: time, vals: vals, height: height, width: width, matrix: intrinsicMatrix, parameters: depthMapParamers, BoundA: 0, BoundB: 1)

    }
    
    static func compileFrame(DepthBuffer: CVPixelBuffer, ColorMap: [UInt32], time: Float, intrinsicMatrix: matrix_float3x3, depthMapParamers: [Float], _BoundA: Float, _BoundB: Float) -> CloudFrame? {
        var Depthvals: [Float] = DepthBuffer.extractFloats()
        
        let depthHeight = CVPixelBufferGetHeight(DepthBuffer)
        let depthWidth = CVPixelBufferGetWidth(DepthBuffer)
        
        let height = depthHeight
        let width = depthWidth
        var vals: [UInt64] = []
        
        for y in 0 ..< height {
            for x in 0 ..< width {
                let idx = y * width + x
                
                var aDepthVal: [UInt8] = Depthvals[idx].toBytes()
                let aColorVal: [UInt8] = tools.splitUint32(number: ColorMap[idx])
                
                aDepthVal.append(contentsOf: aColorVal)
                
                
                //let aVal: Double = Double(aDepthVals)!
                let data = Data(bytes: aDepthVal)
                let aVal = UInt64(bigEndian: data.withUnsafeBytes { $0.pointee })
                
                vals.append(aVal)
            }
        }
        return CloudFrame(time: time, vals: vals, height: height, width: width, matrix: intrinsicMatrix, parameters: depthMapParamers, BoundA: _BoundA, BoundB: _BoundB)
    }
    
    private static func normalize(vals: [Float], height: Int, width: Int, and parameters: [Float]) -> [Float] {
        
        var normalizedVals: [Float] = []
        
        for y in 0 ..< height {
            for x in 0 ..< width {
                let aval = vals[y * width + x]
                normalizedVals.append(aval/parameters[1])
            }
        }
        return normalizedVals
    }
    
    public func getDepths() -> [UInt64]? {
        return self.p
    }
}

