//
//  colorBuffer.swift
//  Surrility
//
//  Created by Administrator on 4/15/18.
//  Copyright © 2018 SurrealMX. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

class imageBuffer {
    var imageData: Data?
    var colorBuffer: [UInt8]?
    var height: Int?
    var width: Int?
    var colorsPerRow: Int?
    
    init(filedatarepresentation: Data) {
        let image = UIImage(data: filedatarepresentation)
        height = Int((image?.size.height)!)
        width = Int((image?.size.width)!)
        colorsPerRow = 4
    }
    
    func getDepthData() -> AVDepthData? {
        
        guard let depthData = getCIImage()?.depthData?.converting(toDepthDataType: kCVPixelFormatType_DepthFloat32) else {
            return nil
        }
        
        //this depthDataMap is the one that is the depth data associated with the image
        self.depthDataMap = depthData.depthDataMap //AVDepthData -> CVPixelBuffer
        
        //normalize the depth datamap -- this depth datamap is only used for filtering the image
        self.depthDataMap?.normalize()
        
        return depthData
    }
    
    func getColorMap() -> [UInt32]? {
        
        //we need to scale the depth map because the depth map is not the same size as the image
        let maxToDim = max((getUIImage()?.size.width ?? 1.0), (getUIImage()?.size.height ?? 1.0))
        let maxFromDim = max((depthDataMapImage?.size.width ?? 1.0), (depthDataMapImage?.size.height ?? 1.0))
        
        let scale: Float = Float(maxFromDim/maxToDim) //maxToDim / maxFromDim
        
        let filter = CIFilter(name: "CILanczosScaleTransform")!
        filter.setValue(image, forKey: "inputImage")
        filter.setValue(scale, forKey: "inputScale")
        filter.setValue(1.0, forKey: "inputAspectRatio")
        let outputImage = filter.value(forKey: "outputImage") as! CIImage
        
        self.downSampledImage = UIImage(ciImage: outputImage, scale: 1.0, orientation: (origImage?.imageOrientation)!) //ToDostore for later use in segue
        
        let colorBufferImage = UIImage(ciImage: outputImage)
        
        return colorBufferImage.getColors()
    }
    
    func getCIImage() -> CIImage? {
        guard let ciImage = CIImage(data: imageData!) else {
            return nil
        }
        
        return ciImage
    }
    
    func getHeight() -> Int {
        return height!
    }
    
    func getWidth() -> Int {
        return width!
    }
    
    private func getPixelData() -> [UInt8]? {
        guard let pixelData = UIImage(data: imageData!)?.pixelData() else {
            return nil
        }
        return pixelData
    }
    
    func getColorsPerRow() -> Int? {
        return colorsPerRow
    }
    
    func getUIImage() -> UIImage? {
        guard let uiImage = UIImage(data: imageData!) else {
            return nil
        }
        return uiImage
    }
    
    func getUInt32() -> [UInt32]? {
        var pixelBuffer: [UInt32] = []
        guard let pixelData = self.getPixelData() else {
            return nil
        }
        for i in stride(from: 0, to: pixelData.count, by: 4) {
            let tempBuffer: [UInt8] = [pixelData[i], pixelData[i+1], pixelData[i+2], pixelData[i+3]]
            pixelBuffer.append(tools.convertBytearrayToUInt32(byteArray: tempBuffer))
        }
        return pixelBuffer
    }
}
