//
//  ProfileEditorViewController.swift
//  Surrility
//
//  Created by Administrator on 5/27/18.
//  Copyright © 2018 SurrealMX. All rights reserved.
//

import UIKit

class ProfileEditorViewController: UIViewController {

    var myData: Dictionary<String, AnyObject>?
    
    
    @IBOutlet var myNameTxt: UITextField!
    @IBOutlet var myUserNameTxt: UITextField!
    @IBOutlet var myEmailTxt: UITextField!
    @IBOutlet var profilePicView: UIImageView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        populateViewFromSnapshot()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func populateViewFromSnapshot() {
        for(info) in myData! {
            if(info.key == "Name") {
                myNameTxt.text = (info.value as! String)
            }
            if(info.key == "Email") {
                myEmailTxt.text = info.value as? String
            }
            if(info.key == "UserName") {
                myUserNameTxt.text = info.value as? String
            }
        }
    }
    
    @IBAction func doneButton(_ sender: Any) {
    }
    
}
