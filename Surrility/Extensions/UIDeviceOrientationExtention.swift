//
//  UIDeviceOrientationExtention.swift
//  Surrility
//
//  Created by Administrator on 2/26/18.
//  Copyright © 2018 SurrealMX. All rights reserved.
//

//From Stackoverflow : "How to generate an UIImage from AVCapturePhoto with correct Orientation

import Foundation
import UIKit
import AVFoundation

extension UIDeviceOrientation {
    func getAVCaptureVideoOrientationFromDevice() -> AVCaptureVideoOrientation? {
        //return AVCaptureVideoOrientationFromDevice
        switch self {
        case UIDeviceOrientation.portrait: return AVCaptureVideoOrientation.portrait
        case UIDeviceOrientation.portraitUpsideDown: return AVCaptureVideoOrientation.portraitUpsideDown
        case UIDeviceOrientation.landscapeLeft: return AVCaptureVideoOrientation.landscapeLeft
        case UIDeviceOrientation.landscapeRight: return AVCaptureVideoOrientation.landscapeRight
        case UIDeviceOrientation.faceDown: return AVCaptureVideoOrientation.portrait
        case UIDeviceOrientation.faceUp: return AVCaptureVideoOrientation.portrait
        case UIDeviceOrientation.unknown: return nil
        }
    }
}
