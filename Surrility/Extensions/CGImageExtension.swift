//  Created by Brian Advent on 09.06.17.
//  Copyright © 2017 Brian Advent. All rights reserved.


import CoreVideo
import CoreGraphics

extension CGImage {
    
    func findColors() -> [UInt32] {
        
        let pixelsWide = Int(self.width)
        let pixelsHigh = Int(self.height)
        
        guard let pixelData = self.dataProvider?.data else { return [] }
        let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
        
        var imageColors: [UInt32] = []
        for x in 0..<pixelsWide {
            for y in 0..<pixelsHigh {
                let point = CGPoint(x: x, y: y)
                let pixelInfo: Int = ((pixelsWide * Int(point.y)) + Int(point.x)) * 4
                let colorBytes = [data[pixelInfo],
                                  data[pixelInfo + 1],
                                  data[pixelInfo + 2],
                                  data[pixelInfo + 3]]  //RGBA
                let color32Byte = tools.convertBytearrayToUInt32(byteArray: colorBytes)
                imageColors.append(color32Byte)
            }
        }
        return imageColors
    }
  
  func pixelBuffer() -> CVPixelBuffer? {
    
    let frameSize = CGSize(width: self.width, height: self.height)
    
    var pixelBuffer:CVPixelBuffer? = nil
    let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(frameSize.width), Int(frameSize.height), kCVPixelFormatType_32BGRA , nil, &pixelBuffer)
    
    if status != kCVReturnSuccess {
        return nil
        
    }
    
    CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags.init(rawValue: 0))
    let data = CVPixelBufferGetBaseAddress(pixelBuffer!)
    let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo = CGBitmapInfo(rawValue: CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue)
    let context = CGContext(data: data, width: Int(frameSize.width), height: Int(frameSize.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: rgbColorSpace, bitmapInfo: bitmapInfo.rawValue)
    
    
    context?.draw(self, in: CGRect(x: 0, y: 0, width: self.width, height: self.height))
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
    
    return pixelBuffer
  }
}
