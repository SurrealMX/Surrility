//
//  ProfileViewController.swift
//  Surrility
//
//  Created by Administrator on 5/6/18.
//  Copyright © 2018 SurrealMX. All rights reserved.
//

import UIKit
import Firebase

class ProfileViewController: UIViewController {

    var ref: DatabaseReference!
    var userData: Dictionary<String, AnyObject>!
    var userPostData: Dictionary<String, String>!
    
    @IBOutlet var profilePicture: UIImageView!
    @IBOutlet var myName: UILabel!
    @IBOutlet var numberOfPosts: UILabel!
    @IBOutlet var editProfileButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
 
        // Do any additional setup after loading the view.
        ref = Database.database().reference()
        fetchUserData()
    }
    
    private func fetchUserData() {
        ref.child("Users").child(UserId!).observe(.value, with: { (userSnapshot) in
            self.userData = userSnapshot.value as! Dictionary<String, AnyObject>
            
            self.ref.child("Users").child(UserId!).child("Posts").observe(.value, with: { (userPostSnapshot) in
                self.userPostData = userPostSnapshot.value as! Dictionary<String, String>
                self.populateViewFromSnapshot()
            }, withCancel: { (error) in
                print(error)
            })
        }, withCancel: { (error) in
            print(error) })
    }
    
    private func populateViewFromSnapshot() {
        for(info) in userData {
            if(info.key == "Name") {
                myName.text = (info.value as! String)
            }
        }
        var i = 0;
        for(posts) in userPostData {
            print(posts)
            i = i + 1;
        }
        numberOfPosts.text = String(i)
    }

    @IBAction func editProfileTapped(_ sender: Any) {
    
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func moveAction(){
        //make sure this is alwas performed on the UI thread otherwise we'll get rando results
        DispatchQueue.main.async {
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier == "editProfile"){
            let DestinationViewController : ProfileEditorViewController = segue.destination as! ProfileEditorViewController
            
            DestinationViewController.myData = self.userData
        }
        
    }
    
}
