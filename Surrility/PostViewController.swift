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

class PostViewController: UIViewController, UITextViewDelegate{
    
    @IBOutlet weak var ImagePreviewPlane: UIImageView!
    @IBOutlet weak var Caption: UITextView!
    @IBOutlet var progressView: UIProgressView!
    
    
    var ref: DatabaseReference!
    let storage = Storage.storage()
    var frame: CloudFrame?
    var image: UIImage?
    
    var defaultText: String = "Write Caption..."
    
    @IBAction func iShare(_ sender: Any) {
        self.addPCM(frame: self.frame!)
        //moveAction();
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        //updateSliders(status: true)
        ImagePreviewPlane.image = image
        Caption.text = defaultText
        updateSliders(status: true)
        progressView.progress = 0.0
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func updateUserRecord(downloadURL: String){
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
                        //put the download url for the record in the real-time database
                        self.updateUserRecord(downloadURL: (FileName_url?.absoluteString)!)
                        //move back to the camera for next picture
                        self.moveAction()
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
