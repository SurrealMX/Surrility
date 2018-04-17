//
//  EditorViewController.swift
//  AVCam
//
//  Created by Administrator on 2/21/18.
//  Copyright © 2018 Apple. All rights reserved.
//

import UIKit
import AVFoundation
import Photos
import Firebase

class EditorViewController: UIViewController {
    
    //UI OUtlets
    @IBOutlet weak var SliderA: UISlider!
    @IBOutlet weak var SliderB: UISlider!
    //@IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var picView: UIImageView!
    @IBOutlet weak var extractButton: UIButton!
    @IBOutlet weak var UISelector: UISegmentedControl!
    
    //segue variables
    var capturedPhoto: AVCapturePhoto?
    
    //internal variables
    var downSampledImage: UIImage?
    var frame: CloudFrame?
    var depthDataMap: CVPixelBuffer?
    var colorDataMap: [UInt32]?
    var depthFilter: DepthImageFilters?
    var origImage: UIImage?
    var filterImage: CIImage?
    var depthDataMapImage: UIImage?
    let context = CIContext()

    var ref: DatabaseReference!
    let storage = Storage.storage()
    
    func extract() {
        
        //hide the slider, updating is done
        self.updateSliders(status: false)
    
        //disable the extract button so you cant hit it twice
        extractButton.isEnabled = false
    
        //let cameraCalibrationData = capturedPhoto?.cameraCalibrationData
        //print(cameraCalibrationData as Any)
        let pSize: Float = 0.025 //(cameraCalibrationData?.pixelSize)!/1000.0 //pixelSize is in millimeters
        print(pSize)
        
        //filter the depthDataMap baed on the user selected bounds and turn into [float]
        self.depthDataMap?.filterMapData(with: self.SliderA.value, and: self.SliderB.value)
            
        //get the frame
        self.frame = CloudFrame.compileFrame(DepthBuffer: self.depthDataMap!, ColorMap: self.colorDataMap!, time: 0.0, pixelSize: pSize)

    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier == "showShare"){
            extract()
            let DestinationViewController : PostViewController = segue.destination as! PostViewController
            
            DestinationViewController.image = UIImage(ciImage: self.filterImage)
            DestinationViewController.frame = self.frame
        }

    }
    
    @IBAction func UISelectedChanged(_ sender: Any) {
        DispatchQueue.global(qos: .userInitiated).async {
            self.updateImageView()
        }
    }
    
    @IBAction func saveTapped(_ sender: Any) {
        UIImageWriteToSavedPhotosAlbum(picView.image!, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    @IBAction func cancelTapped(_ sender: Any) {
        moveAction()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        //setup the depthfilters object with the context
        depthFilter = DepthImageFilters(context: context)
        
        //grabDepthDataMap
        grabDepthData()
        
        // Do any additional setup after loading the view.
        let imageData = capturedPhoto?.fileDataRepresentation()
        origImage = UIImage(data: imageData!)!
        
        let ciDepthDataMapImage = CIImage(cvPixelBuffer: depthDataMap!)
        depthDataMapImage = UIImage(ciImage: ciDepthDataMapImage) //UIImage(ciImage: imageData)
        picView.image = UIImage(data: imageData!, scale: 1.0)//UIImage(ciImage: depthMapImage, scale: 1.0, orientation: orientation!)  //UIImage(ciImage: depthDataMapImage)
        picView.contentMode = .scaleAspectFill

        colorDataMap = grabColorData()
        
        //set the filtered image
        filterImage = CIImage(image: origImage)
    
        //show the sliders
        self.updateSliders(status: true)
        
        // Set the segmented control to point to the original image
        UISelector.selectedSegmentIndex = 0 //0 is blur, 1 is color highlight
        
        //update the current view
        self.updateImageView()
    }

    @IBAction func SliderA_ValueChanged(_ sender: UISlider) {
        DispatchQueue.global(qos: .userInitiated).async {
            self.updateImageView()
        }
    }
    
    @IBAction func SliderB_ValueChanged(_ sender: UISlider) {
        DispatchQueue.global(qos: .userInitiated).async {
            self.updateImageView()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
extension EditorViewController {
    // MARK: Helper Functions
    
    func grabDepthData(){
        //let photoData = photo.fileDataRepresentation()
        guard let depthData = (capturedPhoto?.depthData)?.converting(toDepthDataType: kCVPixelFormatType_DepthFloat32) else {
            return
        }
        
        //this depthDataMap is the one that is the depth data associated with the image
        self.depthDataMap = depthData.depthDataMap //AVDepthData -> CVPixelBuffer
        
        //normalize the depth datamap -- this depth datamap is only used for filtering the image
        self.depthDataMap?.normalize()
    }
    
    func grabColorData() -> [UInt32]? {
        
        guard let ciOrigImage = CIImage(image: origImage) else{
            return nil
        }
        
        guard let colorMap = downSampleColorMapimage(image: ciOrigImage) else {
            return nil
        }
        
        return colorMap
        //return cgOrigImage?.pixelBuffer()
    }
    
    func downSampleColorMapimage(image: CIImage) -> [UInt32]? {

        //we need to scale the depth map because the depth map is not the same size as the image
        let maxToDim = max((origImage?.size.width ?? 1.0), (origImage?.size.height ?? 1.0))
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
    
    func upSampleDepthMap() -> CVPixelBuffer?{
        
        //this function will will upsample the depth buffer to match the image
        let ciDepthDataMapImage = CIImage(cvPixelBuffer: depthDataMap!)
        
        //we need to scale the depth map because the depth map is not the same size as the image
        let maxToDim = max((origImage?.size.width ?? 1.0), (origImage?.size.height ?? 1.0))
        let maxFromDim = max((depthDataMapImage?.size.width ?? 1.0), (depthDataMapImage?.size.height ?? 1.0))
        
        let scale = maxToDim / maxFromDim
        
        let filter = CIFilter(name: "CILanczosScaleTransform")!
        filter.setValue(ciDepthDataMapImage, forKey: "inputImage")
        filter.setValue(scale, forKey: "inputScale")
        filter.setValue(1.0, forKey: "inputAspectRatio")
        let outputImage = filter.value(forKey: "outputImage") as! CIImage
        
        guard let depthBufferImage = tools.convertCIImageToCGImage(inputImage: outputImage) else {
            return nil
        }
        
        let depthBuffer = depthBufferImage.pixelBuffer()
        
        return depthBuffer
        
        //let context = CIContext(options: [kCIContextUseSoftwareRenderer: false])
        //let scaledImage = UIImage(CGImage: self.context.createCGImage(outputImage, fromRect: outputImage.extent()))
    }
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            // we got back an error!
            let ac = UIAlertController(title: "Save error", message: error.localizedDescription, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        } else {
            
            let ac = UIAlertController(title: "Saved!", message: "Your Image Has Been to Photos :)", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        }
    }
    
    func updateSliders(status: Bool){
        DispatchQueue.main.async {
            self.SliderA.isHidden = status ? false:true
            self.SliderB.isHidden = status ? false:true
            //self.progressView.isHidden = status ? true:false;
        }
    }
    
    func moveAction(){
        //make sure this is alwas performed on the UI thread otherwise we'll get rando results
        DispatchQueue.main.async {
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    func updateImageView() {
        updateSliders(status: true) //hide the sliders
        
        let selectedFilter = UISelector.selectedSegmentIndex
        
        //create the filtered image = this is the one we are gonna change
        filterImage = CIImage(image: origImage)
        
        //convert depth image to ciimage
        guard let depthImage = depthDataMapImage?.ciImage else {
            return
        }
        
        //we need to scale the depth map because the depth map is not the same size as the image
        let maxToDim = max((origImage?.size.width ?? 1.0), (origImage?.size.height ?? 1.0))
        let maxFromDim = max((depthDataMapImage?.size.width ?? 1.0), (depthDataMapImage?.size.height ?? 1.0))
        
        let scale = maxToDim / maxFromDim
        
        guard let mask = depthFilter?.createMask(for: depthImage, withFocus: CGFloat(SliderA.value), andWithFocus: CGFloat(SliderB.value), andScale: scale),
            let filterImage = filterImage,
            let orientation = origImage?.imageOrientation 
            else {
                return
        }
        
        //set the final image
        let finalImage: UIImage?
        
        switch selectedFilter {
        case 0:
            //case .blur:
            finalImage = depthFilter?.blur(image: filterImage, mask: mask, orientation: orientation)
            self.updateSliders(status: true)  //show the sliders
            self.extractButton.isHidden = false; //show the update butten
        case 1:
            //case depth map
            self.extractButton.isHidden = true //hide the extract button
            self.updateSliders(status: false)  //hide the sliders
            guard let cgImage = context.createCGImage(mask, from: mask.extent),
                let origImage = origImage else {
                    return
            }
            finalImage = UIImage(cgImage: cgImage, scale: 1.0, orientation: origImage.imageOrientation)

        default:
            return
        }
        
        
        DispatchQueue.main.async {
            //empty the current image view
            self.picView.image = nil
            //update imageView with the filtered image
            self.picView.image = finalImage
            self.picView.contentMode = .scaleAspectFill
        }
    }
}
