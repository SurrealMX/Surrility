//
//  colorBuffer.swift
//  Surrility
//
//  Created by Administrator on 4/15/18.
//  Copyright © 2018 SurrealMX. All rights reserved.
//

import Foundation
import UIKit

class imageBuffer {
    var image: UIImage?
    var colorBuffer: [UInt8]?
    var height: Int?
    var width: Int?
    var colorsPerRow: Int?
    
    init(image: UIImage) {
        self.image = image
        let pixelBuffer = image.pixelData()!
        height = Int(image.size.height);
        width = Int(image.size.width);
        colorsPerRow = 4
    }
    
    func getHeight() -> Int {
        return height
    }
    
    func getWidth() -> Int {
        return width
    }
    
    func getPixelData() -> [UInt8] {
        return pixelData
    }
    
    func getColorsPerRow() {
        return colorsPerRow
    }
    
    func getSourceImage() -> UIImage {
        return image
    }
    
    func getUInt32() -> [UInt32] {
        var pixelBuffer: [UInt32] = []
        for i in stride(from: 0, to: pixelData.count, by: 4) {
            let tempBuffer: [UInt8] = [pixelData[i], pixelData[i+1], pixelData[i+2], pixelData[i+3]]
            pixelBuffer.append(tools.convertBytearrayToUInt32(byteArray: tempBuffer))
        }
        return pixelBuffer
    }
}
