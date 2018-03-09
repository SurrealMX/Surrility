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
    var p: [Float]
    var height: Int
    var width: Int
    var pSize: Float
    
    init(time: Float, vals: [Float], height: Int, width: Int, pSize: Float){
        self.t = time
        self.height = height
        self.width = width
        self.p = vals
        self.pSize = pSize
    }
}

extension CloudFrame {
    
    static func compileFrame(CVBuffer: CVPixelBuffer, time: Float, pixelSize: Float, with parameters: [Float]) -> CloudFrame? {
        let vals = CVBuffer.extractFloats(with: parameters)
        let height = CVPixelBufferGetHeight(CVBuffer)
        let width = CVPixelBufferGetWidth(CVBuffer)
        
        let normalizedVals = normalize(vals: vals, height: height, width: width, and: parameters)
        
        return CloudFrame(time: time, vals: normalizedVals, height: height, width: width, pSize: pixelSize)
    }
    
    static func compileFrame(CVBuffer: CVPixelBuffer, time: Float, pixelSize: Float) -> CloudFrame? {
        let vals = CVBuffer.extractFloats()
        let height = CVPixelBufferGetHeight(CVBuffer)
        let width = CVPixelBufferGetWidth(CVBuffer)
        
        
        return CloudFrame(time: time, vals: vals, height: height, width: width, pSize: pixelSize)
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
    
    public func getDepths() -> [Float]? {
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
                let avector = SCNVector3Make(Float(x)*pSize, Float(y)*pSize, p[y * width + x])
                vectors.append(avector)
            }
        }
        return vectors
    }
}
