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

class PostViewController: UIViewController {
    
    @IBOutlet weak var ImagePreviewPlane: UIImageView!
    @IBOutlet weak var Caption: UITextView!
    @IBOutlet weak var progressView: UIProgressView!
    
    
    var ref: DatabaseReference!
    let storage = Storage.storage()
    var frame: CloudFrame?
    
    @IBAction func PostButtonClicked(_ sender: UIBarButtonItem) {
        self.addPCM(frame: frame!)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
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
        tempRef?.child("Caption").setValue(Caption.text)
    }
    
    func moveAction(){
        //make sure this is alwas performed on the UI thread otherwise we'll get rando results
        DispatchQueue.main.async {
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    func updateSliders(status: Bool){
        DispatchQueue.main.async {
            self.progressView.isHidden = status ? true:false;
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

}
