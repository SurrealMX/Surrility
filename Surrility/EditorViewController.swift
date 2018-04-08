//
//  EditorViewController.swift
//  AVCam
//
//  Created by Administrator on 2/21/18.
//  Copyright © 2018 Apple. All rights reserved.
//

import UIKit
import SceneKit
import AVFoundation
import Photos
import Firebase

class EditorViewController: UIViewController {
    
    //UI OUtlets
    @IBOutlet weak var SliderA: UISlider!
    @IBOutlet weak var SliderB: UISlider!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var picView: UIImageView!
    @IBOutlet weak var extractButton: UIButton!
    @IBOutlet weak var UISelector: UISegmentedControl!
    
    //segue variables
    var capturedPhoto: AVCapturePhoto?
    
    //internal variables
    var depthDataMap: CVPixelBuffer?
    var colorDataMap: CVPixelBuffer?
    var depthFilter: DepthImageFilters?
    var origImage: UIImage?
    var filterImage: CIImage?
    var depthDataMapImage: UIImage?
    let context = CIContext()

    var ref: DatabaseReference!
    let storage = Storage.storage()
    
    @IBAction func extractButton(_ sender: UIButton) {
        
        //hide the slider, updating is done
        self.updateSliders(status: false)
    
        //disable the extract button so you cant hit it twice
        extractButton.isEnabled = false
    
        //let cameraCalibrationData = capturedPhoto?.cameraCalibrationData
        //print(cameraCalibrationData as Any)
        let pSize: Float = 0.025 //(cameraCalibrationData?.pixelSize)!/1000.0 //pixelSize is in millimeters
        print(pSize)
        
        DispatchQueue.global(qos: .userInitiated).async {
            //filter the depthDataMap baed on the user selected bounds
            self.depthDataMap?.filterMapData(with: self.SliderA.value, and: self.SliderB.value)
            
            //filter the colorDataMap based on the slider value in preparation for the cloudFrame
            self.colorDataMap?.filterMapData(with: 0, and: 1)
            
            //get the frame
            guard let frame: CloudFrame = CloudFrame.compileFrame(DepthBuffer: self.depthDataMap!, ColorBuffer: self.colorDataMap!, time: 0.0, pixelSize: pSize) else {
                    print("couldn't create frame... upload failed")
                    return
            }
            
            //add the frame to the cloud
            //self.addPCMJSON(frame: frame)
            self.addPCM(frame: frame)
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
        
        //let cgImage = context.createCGImage(ciImage, from: ciImage.extent)
        
        //let cgOrigImage: CGImage = capturedPhoto?.cgImageRepresentation() as! CGImage
        //pixelBuffer = cgOrigImage.pixelBuffer()
        
        //let orientation = origImage?.imageOrientation
        let ciDepthDataMapImage = CIImage(cvPixelBuffer: depthDataMap!)
        depthDataMapImage = UIImage(ciImage: ciDepthDataMapImage) //UIImage(ciImage: imageData)
        picView.image = UIImage(data: imageData!, scale: 1.0)//UIImage(ciImage: depthMapImage, scale: 1.0, orientation: orientation!)  //UIImage(ciImage: depthDataMapImage)
        picView.contentMode = .scaleAspectFill
        
        //depthDataMap = upSampleDepthMap()
        
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
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
extension EditorViewController {
    // MARK: Helper Functions
    
    func grabDepthData(){
        //let photoData = photo.fileDataRepresentation()
        let depthData = (capturedPhoto?.depthData as AVDepthData!).converting(toDepthDataType: kCVPixelFormatType_DepthFloat32)
        
        //this depthDataMap is the one that is the depth data associated with the image
        self.depthDataMap = depthData.depthDataMap //AVDepthData -> CVPixelBuffer
        
        //normalize the depth datamap -- this depth datamap is only used for filtering the image
        self.depthDataMap?.normalize()
    }
    
    func grabColorData() -> CVPixelBuffer? {
        
        guard let ciOrigImage = CIImage(image: origImage) else{
            return nil
        }
        
        guard let colorMap = downSampleColorMapimage(image: ciOrigImage) else {
            return nil
        }
        
        return colorMap
        //return cgOrigImage?.pixelBuffer()
    }
    
    func downSampleColorMapimage(image: CIImage) -> CVPixelBuffer?{

        //we need to scale the depth map because the depth map is not the same size as the image
        let maxToDim = max((origImage?.size.width ?? 1.0), (origImage?.size.height ?? 1.0))
        let maxFromDim = max((depthDataMapImage?.size.width ?? 1.0), (depthDataMapImage?.size.height ?? 1.0))
        
        let scale: Float = Float(maxFromDim/maxToDim) //maxToDim / maxFromDim
        
        let filter = CIFilter(name: "CILanczosScaleTransform")!
        filter.setValue(image, forKey: "inputImage")
        filter.setValue(scale, forKey: "inputScale")
        filter.setValue(1.0, forKey: "inputAspectRatio")
        let outputImage = filter.value(forKey: "outputImage") as! CIImage
        
        //let outputImage = filter.value(forKey: "outputImage") as! CIImage
        
        guard let colorBufferImage = tools.convertCIImageToCGImage(inputImage: outputImage) else {
            return nil
        }
        
        return colorBufferImage.pixelBuffer()
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
            self.progressView.isHidden = status ? true:false;
        }
    }
    
    func addPCMJSON(frame: CloudFrame) {
        //create a referene to the database
        self.ref = Database.database().reference()
        
        //convert cloudframe to data
        let encoder = JSONEncoder()
        let data = try! encoder.encode(frame)
        let fstring: String = String(data: data, encoding: String.Encoding.utf8)!
        let pcmString = fstring.toBase64()
        
        //update our records to include the user's picture
        let uid: String = UserId!
        self.ref?.child("Users").child(uid).child("Moments").childByAutoId().setValue(pcmString)
        
        self.moveAction()
    }
    
    func updateUserRecord(downloadURL: String){
        //create a referene to the database
        self.ref = Database.database().reference()
        
        //get the serverTimeStamp
        let timeStamp = Firebase.ServerValue.timestamp()
        
        //update our records to include the user's picture
        let uid: String = UserId!
        let tempRef = self.ref?.child(uid).childByAutoId().childByAutoId().parent
        tempRef?.child("Path").setValue(downloadURL)
        //setup likes
        tempRef?.child("likes").setValue(0)
        //add timestamp
        tempRef?.child("TimeStamp").setValue(timeStamp)
    }
    
    func moveAction(){
        //make sure this is alwas performed on the UI thread otherwise we'll get rando results
        DispatchQueue.main.async {
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    func addPCM(frame: CloudFrame){
        
        //create a storage reference from our storage service
        let storageRef = storage.reference()
        
        //Create a child reference
        //ImagesRef now points to "images"
        let pcmStorageRef = storageRef.child("pcms").child(UserId!)
        
        let dateformatter = DateFormatter()
        dateformatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        dateformatter.timeZone = NSTimeZone(name: "UTC")! as TimeZone
        let now = dateformatter.string(from: Date())
        let fileName = now + ".pcm"
    
        let spaceRef = pcmStorageRef.child(fileName)
        let uploadMetaData = StorageMetadata()
        uploadMetaData.contentType = "image/pcm"
        
        //convert cloudframe to data
        let encoder = JSONEncoder()
        let data = try! encoder.encode(frame)
        
        //let fstring: String = String(data: data, encoding: String.Encoding.utf8)!
        //let pcmString = fstring.toBase64()
        
        let uploadTask = spaceRef.putData(data, metadata: uploadMetaData) { (metadata, error) in
            if(error != nil) {
                print("ERROR BILL ROBINSON \(String(describing: error))")
            } else {
                print ("Upload complete! \(String(describing: metadata))")
                
                // Fetch the download URL
                storageRef.child("pcms").child(UserId!).child(fileName).downloadURL(completion: { (FileName_url, error) in
                    if (error != nil) {
                        print("Error getting Download Url")
                        return
                    } else {
                        // Get the download URL for 'images/stars.jpg'
                        print(FileName_url?.absoluteString)
                        //put the download url for the record in the real-time database
                        self.updateUserRecord(downloadURL: (FileName_url?.absoluteString)!)
                        //move back to the camera for next picture
                        self.moveAction()
                    }
                })
            }
        }
        
        DispatchQueue.main.async {
            //update progress bar
            uploadTask.observe(.progress) { [weak self] (snapshot) in
                guard let strongSelf = self else {return}
                guard let progress = snapshot.progress else { return}
                strongSelf.progressView.progress = Float(progress.fractionCompleted)
            }
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
            self.updateSliders(status: true)  //show the sliders
            finalImage = depthFilter?.blur(image: filterImage, mask: mask, orientation: orientation)
        case 1:
            //case depth map
            self.updateSliders(status: false)  //hide the sliders
            self.extractButton.isHidden = true //hide the extract button
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
