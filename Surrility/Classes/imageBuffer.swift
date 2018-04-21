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
    var photo: AVCapturePhoto?
    var colorBuffer: [UInt8]?
    var height: Int?
    var width: Int?
    var colorsPerRow: Int?
    
    var depthBuffer: CVPixelBuffer?
    
    init(_photo: AVCapturePhoto) {
        self.photo = _photo
        
        let image = UIImage(data: _photo.fileDataRepresentation()!)
        self.height = Int((image?.size.height)!)
        self.width = Int((image?.size.width)!)
        self.colorsPerRow = 4
    }
    
    private func getAVDepthData() -> AVDepthData? {
        guard let depthData = self.photo?.depthData else {
            return nil
        }
        
        depthData.converting(toDepthDataType: kCVPixelFormatType_DepthFloat32)
        
        return depthData
    }
    
    func getCalibrationData() -> matrix_float3x3? {
        guard let depthData = self.getAVDepthData() else {
            return nil
        }
        return (depthData.cameraCalibrationData?.intrinsicMatrix)!
    }
    
    func getDepthDataBuffer() -> CVPixelBuffer? {
        
        if(depthBuffer == nil){
            //this depthDataMap is the one that is the depth data associated with the image
            guard let depthDataMap = getAVDepthData()?.depthDataMap else {
                return nil
            }
            
            //normalize the depth datamap -- this depth datamap is only used for filtering the image
            depthDataMap.normalize()
            
            depthBuffer = depthDataMap
        }
        
        return depthBuffer
    }
    
    func getDepthMapImage() -> UIImage? {
        
        let depthDataBuffer: CVPixelBuffer
        
        if (depthBuffer == nil) {
            depthDataBuffer = getDepthDataBuffer()!
        } else {
            depthDataBuffer = depthBuffer!
        }
        
        let CIdepthMapImage = CIImage(cvImageBuffer: depthDataBuffer)
        
        return UIImage(ciImage: CIdepthMapImage)
        
    }
    
    func getDepthMap() -> [UInt8]? {
        let depthDataBuffer = getDepthDataBuffer()
        
        guard var depthDataFloats = depthDataBuffer?.extractFloats() else {
            return nil
        }
        
        var depthByteBuffer: [UInt8] = []
        for i in stride(from: 0, to: depthDataFloats.count, by: 4) {
            let bytes = depthDataFloats[i].toBytes()
            //bytes should have 4 uint8s
            depthByteBuffer.append(contentsOf: bytes)
        }
        return depthByteBuffer
    }
    
    private func getColorMapByteArray() -> [UInt8]? {

        //we need to scale the depth map because the depth map is not the same size as the image
        let maxToDim = max((getUIImage()?.size.width ?? 1.0), (getUIImage()?.size.height ?? 1.0))
        let maxFromDim = max((getDepthMapImage()?.size.width ?? 1.0), (getDepthMapImage()?.size.height ?? 1.0))
        
        guard let ciImage = getCIImage() else {
            return nil
        }
        
        let scale: Float = Float(maxFromDim/maxToDim) //maxToDim / maxFromDim
        
        let filter = CIFilter(name: "CILanczosScaleTransform")!
        filter.setValue(ciImage, forKey: "inputImage")
        filter.setValue(scale, forKey: "inputScale")
        filter.setValue(1.0, forKey: "inputAspectRatio")
        let outputImage = filter.value(forKey: "outputImage") as! CIImage
        
        let downSampledImage = UIImage(ciImage: outputImage, scale: 1.0, orientation: (getUIImage()!.imageOrientation)) //ToDostore for later use in segue
        
        return downSampledImage.pixelData()
    }
    
    func getColorMap() -> [UInt32]? {
        guard let colormapByteArray = getColorMapByteArray() else {
            return nil
        }
        var colorMap: [UInt32] = []
        for i in stride(from: 0, to: colormapByteArray.count, by: 4) {
            let colormap32 = tools.convertBytearrayToUInt32(byteArray: [colormapByteArray[i], colormapByteArray[i+1], colormapByteArray[i+2], colormapByteArray[i+3]])
            colorMap.append(colormap32)
        }
        return colorMap
    }
    
    func getCIImage() -> CIImage? {
        guard let ciImage = CIImage(data: (photo?.fileDataRepresentation())!) else {
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
    
    func getColorsPerRow() -> Int? {
        return colorsPerRow
    }
    
    func getUIImage() -> UIImage? {
        guard let uiImage = UIImage(data: (photo?.fileDataRepresentation())!) else {
            return nil
        }
        return uiImage
    }
    
    func getCombinedData() -> [UInt64]? {
        var imageBuffer: [UInt64] = []
        
        guard let colorUIntBuffer = self.getColorMapByteArray() else {
            return nil
        }
        
        guard let depthUIntBuffer = self.getDepthMap() else {
            return nil
        }
        
        if(colorUIntBuffer.count == depthUIntBuffer.count) {
            for i in stride(from: 0, to: colorUIntBuffer.count, by: 4) {
                let tempColorBuffer: [UInt8] = [colorUIntBuffer[i], colorUIntBuffer[i+1], colorUIntBuffer[i+2], colorUIntBuffer[i+3]]
                let tempDepthBuffer: [UInt8] = [depthUIntBuffer[i], depthUIntBuffer[i+1], depthUIntBuffer[i+2], depthUIntBuffer[i+3]]
                var tempBuffer: [UInt8] = []
                tempBuffer.append(contentsOf: tempDepthBuffer)
                tempBuffer.append(contentsOf: tempColorBuffer)
                
                imageBuffer.append(tools.convertBytearrayToUInt64(byteArray: tempBuffer))
            }
            return imageBuffer
        } else {
            return nil
        }
    }
    
    func getCombinedData(with filteredDepth: CVPixelBuffer) -> [UInt64]? {
        var imageBuffer: [UInt64] = []
        
        guard let colorUIntBuffer = self.getColorMapByteArray() else {
            return nil
        }
        
        var floatDepthBuffer = filteredDepth.extractFloats()
        
        var depthUIntBuffer: [UInt8] = []
        for i in 0 ..< floatDepthBuffer.count {
            depthUIntBuffer.append(contentsOf: floatDepthBuffer[i].toBytes())
        }
        
        if(colorUIntBuffer.count == depthUIntBuffer.count) {
            for i in stride(from: 0, to: colorUIntBuffer.count, by: 4) {
                let tempColorBuffer: [UInt8] = [colorUIntBuffer[i], colorUIntBuffer[i+1], colorUIntBuffer[i+2], colorUIntBuffer[i+3]]
                let tempDepthBuffer: [UInt8] = [depthUIntBuffer[i], depthUIntBuffer[i+1], depthUIntBuffer[i+2], depthUIntBuffer[i+3]]
                var tempBuffer: [UInt8] = []
                tempBuffer.append(contentsOf: tempDepthBuffer)
                tempBuffer.append(contentsOf: tempColorBuffer)
                
                imageBuffer.append(tools.convertBytearrayToUInt64(byteArray: tempBuffer))
            }
            return imageBuffer
        } else {
            return nil
        }
    }
}
