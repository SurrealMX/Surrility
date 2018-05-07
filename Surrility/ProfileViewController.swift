//
//  ProfileViewController.swift
//  Surrility
//
//  Created by Administrator on 5/6/18.
//  Copyright © 2018 SurrealMX. All rights reserved.
//

import UIKit

class ProfileViewController: UIViewController {

    @IBOutlet var profilePicture: UIImageView!
    @IBOutlet var myName: UILabel!
    @IBOutlet var numberOfPosts: UILabel!
    @IBOutlet var editProfileButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        myName.text = UserName
        
        
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
