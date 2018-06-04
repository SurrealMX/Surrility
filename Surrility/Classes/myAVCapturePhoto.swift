//
//  myAVCapturePhoto.swift
//  Surrility
//
//  Created by Administrator on 6/3/18.
//  Copyright © 2018 SurrealMX. All rights reserved.
//

import Foundation
import UIKit
import Photos

class myAVCapturePhoto {
    
    var image: UIImage
    var depthData: AVDepthData
    var matrix: matrix_float3x3
    
    init (image: CGImage, depthData: AVDepthData, intrinsicMatrix: matrix_float3x3) {
        self.image = UIImage(cgImage: image)
        self.depthData = depthData
        self.matrix = intrinsicMatrix
    }
    
    init (image: UIImage, depthData: AVDepthData, intrinsicMatrix: matrix_float3x3) {
        self.image = image
        self.depthData = depthData
        self.matrix = intrinsicMatrix
    }
    
    func getDepthData() -> AVDepthData {
        return self.depthData
    }
    
    func getUIImage() -> UIImage {
        return self.image
    }
    
    func getIntrinsics() -> matrix_float3x3 {
        return self.matrix
    }
}
