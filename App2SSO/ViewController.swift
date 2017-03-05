//
//  ViewController.swift
//  Auth0WebAuth
//
//  Created by Pushp Abrol on 11/2/16.
//  Copyright © 2016 Pushp Abrol. All rights reserved.
//

import UIKit
import Auth0
import SimpleKeychain
import JWTDecode
import Alamofire


class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    
        
                NotificationCenter.default.addObserver(self, selector: #selector(ViewController.applicationIsActive), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.applicationEnteredForeground), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        
        
        checkRefreshTokenAndPerformSegue()
        

        
            }
    
    
    func applicationIsActive() {
    print("Application Did Become Active");
    }
    
    func applicationEnteredForeground(){
    checkRefreshTokenAndPerformSegue()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func clickOnLogin(_ sender: AnyObject) {
          let app = Application.sharedInstance
        var auth0 = Auth0.webAuth()
        
        auth0
            .logging(enabled: true)
            .parameters(["audience" : app.API_AUDIENCE!, "device" : "Pushp"])
            .scope(app.scope!)
            .connection("Username-Password-Authentication")
            .start { result in
                switch result {
                case .success(let credentials):
                    print("credentials: \(credentials)")
                    do {
                    let jwt = try decode(jwt: credentials.idToken!),
                        at = try decode(jwt: credentials.accessToken)
                        if(JWtHelper.isTokenValid(token: jwt))
                        {

                            Application.sharedInstance.keychainService.setString(credentials.accessToken, forKey: "accessToken")
                            Application.sharedInstance.keychainService.setString(credentials.idToken!, forKey: "idToken")
                            Application.sharedInstance.keychainService.setString(credentials.refreshToken!, forKey: "refreshToken")
                            self.performSegue(withIdentifier: "loggedin", sender: self)
                        }
                        else
                        {
                            print("Your session is no longer valid.");
                            let alertController = UIAlertController(title: "JWT Validation", message:
                                "JWT Validation failed", preferredStyle: UIAlertControllerStyle.alert)
                            alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default,handler: nil))
                            
                            self.present(alertController, animated: true, completion: nil)
                        }
                    }
                    catch let error as NSError {
                        print(error.localizedDescription)
                        let alertController = UIAlertController(title: "JWT Decode error", message:
                            error.localizedDescription, preferredStyle: UIAlertControllerStyle.alert)
                        alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default,handler: nil))
                        
                        self.present(alertController, animated: true, completion: nil)
                    }
 

                case .failure(let error):
                    print(error)
                    let alertController = UIAlertController(title: "Error logging in", message:
                        error.localizedDescription, preferredStyle: UIAlertControllerStyle.alert)
                    alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default,handler: nil))
                    
                    self.present(alertController, animated: true, completion: nil)
                }
        }

    }
    
    func checkRefreshTokenAndPerformSegue()  {
        if (Application.sharedInstance.keychainService.string(forKey: "refreshToken") != nil)
        {
            getTokens(fromRefreshToken: Application.sharedInstance.keychainService.string(forKey: "refreshToken")! )
            self.performSegue(withIdentifier: "loggedin", sender: self)
            
            
            
        }
        
    }
    
    func getTokens(fromRefreshToken: String){
        let app = Application.sharedInstance
        
        let parameters: [String: Any] = [
            "refresh_token" : fromRefreshToken,
            "client_id" : app.audience! as String,
            "grant_type" : "refresh_token"
 
        ]
        let url =  "https://".appending(app.domain!).appending("/oauth/token")
        
        Alamofire.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default)
            .responseJSON { response in
                switch response.result
                {
                case .success:
                if let result = response.result.value {
                 let JSON = result as! NSDictionary
                    Application.sharedInstance.keychainService.setString(JSON.value(forKey: "access_token") as! String, forKey: "accessToken")
                    Application.sharedInstance.keychainService.setString(JSON.value(forKey: "id_token") as! String, forKey: "idToken")

                }
                case .failure(let error):
                    print(error)
                    let alertController = UIAlertController(title: "Error refreshing tokens", message:
                        error.localizedDescription, preferredStyle: UIAlertControllerStyle.alert)
                    alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default,handler: nil))
                    
                    self.present(alertController, animated: true, completion: nil)
                    
                }
                
        }
        
    
    }

}

