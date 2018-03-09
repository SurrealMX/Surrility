//
//  SimpleVector.swift
//  SurrealityAR
//
//  Created by Michael Archer on 1/22/18.
//  Copyright © 2018 SurrealMX. All rights reserved.
//

import Foundation
import SceneKit

class SimpleVector : Codable {
    var X: Float, Y: Float, Z: Float
    var A: Float, R: Float, G: Float, B: Float
    
    init(X: Float, Y: Float, Z: Float, R: Float, G: Float, B: Float, A: Float){
        self.X = X
        self.Y = Y
        self.Z = Z
        self.R = R
        self.G = G
        self.B = B
        self.A = A
    }
    
    init(vector: SCNVector3, color: UIColor){
        
        var (red, green, blue, alpha) = (CGFloat(0.0), CGFloat(0.0),  CGFloat(0.0), CGFloat(0.0))
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        self.R = Float (red)
        self.G = Float (green)
        self.B = Float (blue)
        self.A = Float (alpha)
        
        self.X = vector.x;
        self.Y = vector.y;
        self.Z = vector.z;
    }
    
    func getVector3() -> SCNVector3 {
        return SCNVector3Make(self.X, self.Y, self.Z)
    }
    
    func getUIColor() -> UIColor {
        return UIColor(red: CGFloat(self.R), green: CGFloat(self.G), blue: CGFloat(self.B), alpha: CGFloat(self.A))
    }
    /*
    init(json: [String: Any]) {
        X = json["X"] as? Float ?? -1.0
        Y = json["Y"] as? Float ?? -1.0
        Z = json["Z"] as? Float ?? -1.0
        R = json["R"] as? Float ?? 0
        G = json["G"] as? Float ?? 0
        B = json["B"] as? Float ?? 0
        A = json["A"] as? Float ?? 0
    }
 */
}
