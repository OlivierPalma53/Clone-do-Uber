//
//  ViewController.swift
//
//  Copyright 2011-present Parse Inc. All rights reserved.
//

import UIKit
import Parse

class ViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var username: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var riderLabel: UILabel!
    @IBOutlet weak var driverLabel: UILabel!
    @IBOutlet weak var `switch`: UISwitch!
    @IBOutlet weak var signUpButton: UIButton!
    @IBOutlet weak var signInButton: UIButton!
    
    var signUpActivy = true
    
    func alertDialog (title: String, message: String){
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
        
    }
    
    @IBAction func signUp(sender: AnyObject) {
        
        if username.text == "" || password.text == "" {
            
            alertDialog("Erro", message: "Por favor, preencha os campos de usuário e senha!")
            
        } else {
            if signUpActivy == true {
                
                let user = PFUser()
                user.username = username.text
                user.password = password.text
                user["isDriver"] = `switch`.on
                
                user.signUpInBackgroundWithBlock {(succeeded, error) -> Void in
                    
                    if let error = error {
                        
                        if let errorString = error.userInfo["error"] as? NSString {
                            
                            self.alertDialog("Falha no Cadastro", message: String(errorString))
                            
                        }
                        
                    } else {
                        if PFUser.currentUser()?["isDriver"]! as! Bool == true {
                            
                            self.performSegueWithIdentifier("loginDriver", sender: self)
                            
                        } else {
                            
                            self.performSegueWithIdentifier("loginRider", sender: self)
                            
                        }
                        
                    }
                }
                
            } else {
                
                PFUser.logInWithUsernameInBackground(username.text!, password: password.text!) {
                    (user: PFUser?, error: NSError?) -> Void in
                    if user != nil {
                        
                        if PFUser.currentUser()?["isDriver"]! as! Bool == true {
                            
                            self.performSegueWithIdentifier("loginDriver", sender: self)
                            
                        } else {
                            
                            self.performSegueWithIdentifier("loginRider", sender: self)
                            
                        }
                        

                        
                    } else {
                        
                        if let error = error {
                            
                            if let errorString = error.userInfo["error"] as? NSString {
                                
                                self.alertDialog("Falha ao entrar", message: String(errorString))
                                
                            }

                        }
                    }
                }
                
            }
            
        }
        
    }
    
    @IBAction func togleSignUp(sender: AnyObject) {
        
        if signUpActivy == true {
            
            signUpButton.setTitle("Entrar", forState: .Normal)
            signInButton.setTitle("Cadastre-se", forState: .Normal)
            
            signUpActivy = false
            
            riderLabel.alpha = 0
            driverLabel.alpha = 0
            `switch`.alpha = 0
            
            
        } else {
            
            signUpButton.setTitle("Cadastrar", forState: .Normal)
            signInButton.setTitle("Login", forState: .Normal)
            
            signUpActivy = true
            
            riderLabel.alpha = 1
            driverLabel.alpha = 1
            `switch`.alpha = 1
            
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.username.delegate = self
        self.password.delegate = self
        
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "dismissKeybord")
        view.addGestureRecognizer(tap)
        
    }
    
    func dismissKeybord() {
        view.endEditing(true)
    }
    
    override func viewDidAppear(animated: Bool) {
        
        if let user = PFUser.currentUser()?.username {
            
            if PFUser.currentUser()?["isDriver"]! as! Bool == true {
                
                self.performSegueWithIdentifier("loginDriver", sender: self)
                
            } else {
                
                self.performSegueWithIdentifier("loginRider", sender: self)
                
            }
            
            
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

