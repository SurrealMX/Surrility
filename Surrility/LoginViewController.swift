//
//  LoginViewController.swift
//  Surrility
//
//  Created by Administrator on 3/1/18.
//  Copyright © 2018 SurrealMX. All rights reserved.
//

import UIKit
import Firebase
import FBSDKLoginKit

var UserEmail: String? = nil
var UserId: String? = nil
var UserName: String? = nil

class LoginViewController: UIViewController, FBSDKLoginButtonDelegate {

    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!) {
        if (error != nil) {
            print("login failed")
            return
        }
        imLoggedIn()
    }
    
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!) {
        print("Did log out of facebook")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        let loginButton = FBSDKLoginButton()
        
        view.addSubview(loginButton)
        loginButton.center = view.center
        
        loginButton.delegate = self
        loginButton.readPermissions = ["email", "public_profile"]
        
        //persistent login
        if (FBSDKAccessToken.current()) != nil {
            //well i was already logged in
            imLoggedIn()
        }
    }
    
    func imLoggedIn(){
        //login to surility
        loginToSurility()
        
        //lets grab the user's info from FB
        fetchFBdata()
        
        //move to the camera app
        moveAction()
    }
    
    func fetchFBdata(){
        FBSDKGraphRequest(graphPath: "/me", parameters: ["fields": "id, name, email"]).start { (connection, result, err) in
            
            if err != nil {
                print("failed to start graph request:", err!)
                return
            }
            let results = result as! [String: AnyObject]
            UserEmail = results["email"] as? String
            //UserId = results["id"] as? String
            UserName = results["name"] as? String
            print(result!)
        }
    }
    
    func moveAction(){
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "Camera") as! CameraViewController
        
        self.show(vc, sender: nil)
        //self.navigationController?.pushViewController(vc, animated: true)
        //self.present(vc, animated: true, completion: nil)
    }
    
    
    func loginToSurility() {
        let credential = FacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
        
        Auth.auth().signIn(with: credential) { (user, error) in
            if error != nil {
                print("Couldn't Sign into Firebase")
                return
            }
            print("Successfully Logged on to Firebase with user from FB: ", user ?? "")
            UserId = user?.uid
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
