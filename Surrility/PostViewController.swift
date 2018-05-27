//
//  PostViewController.swift
//  Surrility
//
//  Created by Administrator on 4/14/18.
//  Copyright © 2018 SurrealMX. All rights reserved.
//
import UIKit
import Photos
import Firebase
import Compression

class PostViewController: UIViewController, UITextViewDelegate{
    
    @IBOutlet weak var ImagePreviewPlane: UIImageView!
    @IBOutlet weak var Caption: UITextView!
    @IBOutlet var progressView: UIProgressView!
    
    @IBOutlet var maxLabel: UILabel!
    @IBOutlet var minLabel: UILabel!
    @IBOutlet var rangeLabel: UILabel!
    @IBOutlet var lowerBoundLabel: UILabel!
    @IBOutlet var upperBoundLabel: UILabel!
    @IBOutlet var widthLabel: UILabel!
    @IBOutlet var heightLabel: UILabel!
    
    var ref: DatabaseReference!
    let storage = Storage.storage()
    var frame: CloudFrame?
    var image: UIImage?
    var postID: String?
    
    var defaultText: String = "Write Caption..."
    
    @IBAction func iShare(_ sender: Any) {
        self.addPCM(frame: self.frame!)
        //moveAction();
    }
    
    func setupLabels() {
        
        guard let currentFrame = frame else {
            return
        }
        
        let nf = NumberFormatter()
        nf.numberStyle = .decimal
        
        maxLabel.text = currentFrame.max.format(f: ".2") //nf.string(from: NSNumber(value: currentFrame.max))
        minLabel.text = currentFrame.min.format(f: ".2") //nf.string(from: NSNumber(value: currentFrame.min))
        rangeLabel.text = currentFrame.range.format(f: ".2") //nf.string(from: NSNumber(value: currentFrame.range))
        
        var lowerBound: Float
        var upperBound: Float
        if(currentFrame.BoundA < currentFrame.BoundB){
            lowerBound = currentFrame.BoundA
            upperBound = currentFrame.BoundB
        } else {
            lowerBound = currentFrame.BoundB
            upperBound = currentFrame.BoundA
        }
        
        lowerBoundLabel.text = lowerBound.format(f: ".2") //nf.string(from: NSNumber(value: lowerBound))
        upperBoundLabel.text = upperBound.format(f: ".2") //nf.string(from: NSNumber(value: upperBound))
        
        widthLabel.text = nf.string(from: NSNumber(value: currentFrame.width))
        
        heightLabel.text = nf.string(from: NSNumber(value: currentFrame.height))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        //updateSliders(status: true)
        ImagePreviewPlane.image = image
        fixImageOrientation()
        Caption.text = ""
        updateSliders(status: true)
        setupLabels()
        progressView.progress = 0.0
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func fixImageOrientation() {
        //check current orientation of original image
        switch image?.imageOrientation {
        case .down?, .downMirrored?:
            ImagePreviewPlane.transform = CGAffineTransform(rotationAngle: .pi)
        case .left?, .leftMirrored?:
            ImagePreviewPlane.transform = CGAffineTransform(rotationAngle: .pi/2)
        case .right?, .rightMirrored?:
            ImagePreviewPlane.transform = CGAffineTransform(rotationAngle: -.pi/2)
        case .up?, .upMirrored?:
            break;
        case .none:
            break;
        }
    }
    
    func updateRecords(name: String, downloadURL: String){
        //create a referene to the database
        self.ref = Database.database().reference()
        
        //get the serverTimeStamp
        let timeStamp = Firebase.ServerValue.timestamp()
        
        //update our records to include the user's picture
        let uid: String = UserId!
        let tempRef = self.ref?.child("Posts").childByAutoId().childByAutoId().parent
        //add download url
        tempRef?.child("Path").setValue(downloadURL)
        //add who posted me
        tempRef?.child("UID").setValue(uid)
        //setup likes
        tempRef?.child("likes").setValue(0)
        //add timestamp
        tempRef?.child("TimeStamp").setValue(timeStamp)
        //add description
        if(Caption.text != defaultText){  //if the user forgot to add text oh well... we're not adding the default
            tempRef?.child("Caption").setValue(Caption.text)
        }
        //upload the thumbnail
        addthumbnail(name: name, PID: (tempRef?.key)!)
    }
    
    func addthumbnail(name: String, PID: String){
        //create a storage reference from our storage service for upload
        let storageRef = storage.reference()
        //Create a child reference
        //ImagesRef now points to "images"
        let pngStorageRef = storageRef.child("thumbnails").child(UserId!)
        
        let filename = name + ".jpeg"
        let spaceRef = pngStorageRef.child(filename)
        let uploadMetaData = StorageMetadata()
        uploadMetaData.contentType = "image/jpeg"
        
        if let data = UIImageJPEGRepresentation(image!, 0.3) {  //make sure we converted to dta correctly
            let _ = spaceRef.putData(data, metadata: uploadMetaData) { (metadata, error) in
                if(error != nil) {
                    print("ERROR BILL ROBINSON \(String(describing: error))")  //there was an error while uploading
                } else {
                    print ("UPLOADED THUMBNAIL \(String(describing: metadata))")  //uploaded successfully
                    // Fetch the download URL
                    storageRef.child("thumbnails").child(UserId!).child(filename).downloadURL(completion: { (FileName_url, error) in
                        if (error != nil) {
                            print("Error getting thumbnail Download Url")
                            return
                        } else {
                            //create a referene to the realtime database
                            self.ref = Database.database().reference()
                            //update our records to include the post thumbnail
                            let uid: String = UserId!
                            let tempRef = self.ref?.child("Users").child(uid).child("Posts").child(PID)
                            tempRef?.setValue(FileName_url?.absoluteString)
                            //move back to the camera for next picture
                            self.moveAction()
                        }
                    })
                }
            }
        }
    }
    
    func moveAction(){
        for vc in self.navigationController!.viewControllers as Array {
            if vc.isKind(of: CameraViewController.self) {
                self.navigationController!.popToViewController(vc, animated: true)
                break
            }
        }
        //performSegue(withIdentifier: "postedSegue", sender: self)
    }
    
    func updateSliders(status: Bool){
        DispatchQueue.main.async {
            self.progressView.isHidden = status ? true:false;
        }
    }
    
    func addPCM(frame: CloudFrame){
        updateSliders(status: false);
        
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
        let base64Frame = data.base64EncodedData(options: Data.Base64EncodingOptions.lineLength64Characters)
        guard let compressedData = data.compress(withAlgorithm: .ZLIB) else {
            return
        }
        
        let uploadTask = spaceRef.putData(compressedData, metadata: uploadMetaData) { (metadata, error) in
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
                        //put the download url for the record in the real-time database
                        self.updateRecords(name: now, downloadURL: (FileName_url?.absoluteString)!)
                    }
                })
            }
        }
        //update progress bar
        uploadTask.observe(.progress) { [weak self] (snapshot) in
            guard let progress = snapshot.progress else { return}
            self?.progressView.progress = Float(progress.fractionCompleted)
        }
    }
}
