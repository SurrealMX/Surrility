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
    var pSize: Float
    
    init(time: Float, vals: [UInt64], height: Int, width: Int, pSize: Float){
        self.t = time
        self.height = height
        self.width = width
        self.p = vals
        self.pSize = pSize
    }
}

extension CloudFrame {
    
    static func compileFrame(DepthBuffer: CVPixelBuffer, ColorBuffer: CVPixelBuffer, time: Float, pixelSize: Float) -> CloudFrame? {
        
        var Depthvals: [Float] = DepthBuffer.extractFloats()
        var Colorvals: [Float] = ColorBuffer.extractFloats()
        
        let depthHeight = CVPixelBufferGetHeight(DepthBuffer)
        let depthWidth = CVPixelBufferGetWidth(DepthBuffer)
        let colorHeight = CVPixelBufferGetHeight(ColorBuffer)
        let colorWidth = CVPixelBufferGetWidth(ColorBuffer)
        
        /*
        //test tools
        
        var testVal: Float = 0.9;
        var val = testVal.toBytes()
        let valR: CGFloat = 0.6;
        let valG: CGFloat = 0.4;
        let valB: CGFloat = 0.2;
        let valA: CGFloat = 1.0;

        val.append(tools.convertCGFloat2UInt8(val: valR))
        val.append(tools.convertCGFloat2UInt8(val: valG))
        val.append(tools.convertCGFloat2UInt8(val: valB))
        val.append(tools.convertCGFloat2UInt8(val: valA))
        
        let data = Data(bytes: val)
        let aVal = UInt64(bigEndian: data.withUnsafeBytes { $0.pointee }) */
        
        if((colorHeight == depthHeight) && (colorWidth == depthWidth)) {
            let height = depthHeight
            let width = depthWidth
            var vals: [UInt64] = []
            
            for y in 0 ..< height {
                for x in 0 ..< width {
                    let idx = y * width + x
                    
                    var aDepthVals: [UInt8] = Depthvals[idx].toBytes()
                    let aColorVals: [UInt8] = Colorvals[idx].toBytes()
                    
                    for i in 0 ..< aColorVals.count {
                        aDepthVals.append(aColorVals[i])
                    }
                    
                    //let aVal: Double = Double(aDepthVals)!
                    let data = Data(bytes: aDepthVals)
                    let aVal = UInt64(bigEndian: data.withUnsafeBytes { $0.pointee })

                    vals.append(aVal)
                    
                }
            }
            return CloudFrame(time: time, vals: vals, height: height, width: width, pSize: pixelSize)
        } else {
            return nil
        }
    }
    
    static func compileFrame(DepthBuffer: CVPixelBuffer, ColorMap: [UInt32], time: Float, pixelSize: Float) -> CloudFrame? {
        var Depthvals: [Float] = DepthBuffer.extractFloats()
        
        let depthHeight = CVPixelBufferGetHeight(DepthBuffer)
        let depthWidth = CVPixelBufferGetWidth(DepthBuffer)
        
        let height = depthHeight
        let width = depthWidth
        
<<<<<<< HEAD
        if(height*width == ColorMap.count){
            var vals: [UInt64] = []
            for y in 0 ..< height {
                for x in 0 ..< width {
                    let idx = y * width + x
                    
                    var aDepthVal: [UInt8] = Depthvals[idx].toBytes()
                    var aColorVal: [UInt8] = tools.splitUint32(number: ColorMap[idx])
                    
                    for i in 0..<4 {
                        aDepthVal.append(aColorVal[i])
                    }
                    
                    //let aVal: Double = Double(aDepthVals)!
                    let data = Data(bytes: aDepthVal)
                    let aVal = UInt64(bigEndian: data.withUnsafeBytes { $0.pointee })
                    
                    vals.append(aVal)
                }
=======
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
>>>>>>> updatesToStorageProcess
            }
            return CloudFrame(time: time, vals: vals, height: height, width: width, pSize: pixelSize)
        } else {
            return nil
        }
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
    
    public func getNode() -> SCNNode? {
        if(self.p.count != 0){
            let node:SCNNode = buildNode()
            NSLog(String(describing: node))
            return node
        } else{
            return nil
        }
    }
    
    private func buildNode() -> SCNNode{
        //need Vector3s not floats
        
        let vectors: [SCNVector3] = getVectors()
        
        let vertexData = NSData(bytes: vectors, length: MemoryLayout<SimpleVector>.size*p.count)
        
        let pointSource = SCNGeometrySource(data: vertexData as Data,
                                            semantic: SCNGeometrySource.Semantic.vertex,
                                            vectorCount: vectors.count,
                                            usesFloatComponents: true,
                                            componentsPerVector: 3,
                                            bytesPerComponent: MemoryLayout<Float>.size,
                                            dataOffset: 0,
                                            dataStride: MemoryLayout<SimpleVector>.size)
        let colorSource = SCNGeometrySource(data: vertexData as Data,
                                            semantic: SCNGeometrySource.Semantic.color,
                                            vectorCount: p.count,
                                            usesFloatComponents: true,
                                            componentsPerVector: 4,
                                            bytesPerComponent: MemoryLayout<Float>.size,
                                            dataOffset: MemoryLayout<Float>.size*4,
                                            dataStride: MemoryLayout<SimpleVector>.size)
        let elements = SCNGeometryElement(data: nil,
                                          primitiveType: .point,
                                          primitiveCount: p.count,
                                          bytesPerIndex: MemoryLayout<Int>.size)
        
        elements.pointSize = 10.0
        
        let pointsGeometry = SCNGeometry(sources: [pointSource, colorSource], elements: [elements])
        
        
        return SCNNode(geometry: pointsGeometry)
    }
    
    public func getColors() -> [UIColor] {
        //the color is a gray scale based on depth
        
        var colors: [UIColor] = []
        
        for x in 0 ..< width {
            for y in 0 ..< height {
                let aColor: UIColor = UIColor(white: CGFloat(p[y*width+x]), alpha: 1)
                colors.append(aColor)
            }
        }
        return colors
    }
    
    public func getVectors() -> [SCNVector3] {
        var vectors: [SCNVector3] = []
        
        for x in 0 ..< width {
            for y in 0 ..< height {
                let avector = SCNVector3Make(Float(x)*pSize, Float(y)*pSize, Float(p[y * width + x]))
                vectors.append(avector)
            }
        }
        return vectors
    }
}
