//
//  ViewController.swift
//  AMLoginSingup
//
//  Created by amir on 10/11/16.
//  Copyright © 2016 amirs.eu. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import Locksmith

enum AMLoginSignupViewMode {
    case login
    case signup
}

class LoginViewController: UIViewController {
    
    let animationDuration = 0.25
    var mode:AMLoginSignupViewMode = .signup
    var domain: String?
    var loginURL: String?
    var signUpURL: String?
    
    //MARK: - background image constraints
    @IBOutlet weak var backImageLeftConstraint: NSLayoutConstraint!
    @IBOutlet weak var backImageBottomConstraint: NSLayoutConstraint!
    
    
    //MARK: - login views and constrains
    @IBOutlet weak var loginView: UIView!
    @IBOutlet weak var loginContentView: UIView!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var loginButtonVerticalCenterConstraint: NSLayoutConstraint!
    @IBOutlet weak var loginButtonTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var loginWidthConstraint: NSLayoutConstraint!
    
    
    //MARK: - signup views and constrains
    @IBOutlet weak var signupView: UIView!
    @IBOutlet weak var signupContentView: UIView!
    @IBOutlet weak var signupButton: UIButton!
    @IBOutlet weak var signupButtonVerticalCenterConstraint: NSLayoutConstraint!
    @IBOutlet weak var signupButtonTopConstraint: NSLayoutConstraint!
    
    
    //MARK: - logo and constrains
    @IBOutlet weak var logoView: UIView!
    @IBOutlet weak var logoTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var logoHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var logoBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var logoButtomInSingupConstraint: NSLayoutConstraint!
    @IBOutlet weak var logoCenterConstraint: NSLayoutConstraint!
   
    
    @IBOutlet weak var forgotPassTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var socialsView: UIView!
    
    
    //MARK: - input views
    @IBOutlet weak var loginEmailInputView: AMInputView!
    @IBOutlet weak var loginPasswordInputView: AMInputView!
    @IBOutlet weak var signupEmailInputView: AMInputView!
    @IBOutlet weak var signupPasswordInputView: AMInputView!
    @IBOutlet weak var signupPasswordConfirmInputView: AMInputView!

    //MARK: - controller
    override func viewDidLoad() {
        super.viewDidLoad()
        self.domain = __domain__
        self.loginURL = domain! + "/login"
        self.signUpURL = domain! + "/register"
        
        // set view to login mode
        toggleViewMode(animated: false)
        
        //add keyboard notification
        NotificationCenter.default.addObserver(self, selector: #selector(keyboarFrameChange(notification:)), name: .UIKeyboardWillChangeFrame, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: .UIApplicationDidBecomeActive, object: nil)
    }
    
    @objc private func appDidBecomeActive() {
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
//        showDialog()
    }
    
    
    
    private func showDialog() {
        var alertController:UIAlertController?
        alertController = UIAlertController(title: "Enter server address",
                                            message: "use IP address and port",
                                            preferredStyle: .alert)
        
        alertController!.addTextField(
            configurationHandler: {(textField: UITextField!) in
                textField.placeholder = "http://localhost:3000"
        })
        var enteredText: String?
        let action = UIAlertAction(title: "Submit",
                                   style: UIAlertActionStyle.default,
                                   handler: { //[weak self]
                                    (paramAction:UIAlertAction!) in
                                    if let textFields = alertController?.textFields{
                                        let theTextFields = textFields as [UITextField]
                                        enteredText = theTextFields[0].text
                                    }
                                    if enteredText!.count > 0 {
                                         __domain__ = enteredText!
                                    }
                                    print(enteredText!)

        })
        
        alertController?.addAction(action)
        self.present(alertController!,
                                   animated: true,
                                   completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
 
    private func verifyLogin(email: String, password: String, callback: @escaping (JSON) -> Void) -> Void {
        let param: Parameters = ["username": email, "password": password]
        Alamofire.request(self.loginURL!, method: .post, parameters: param)
            .responseJSON(completionHandler: { (response: DataResponse) -> Void in
                let json = JSON(data: response.data!)
                if json["status"] == "success" {
                    callback(json)
                }
                else {
                    print("bad login")
                }
        })
    }
    
    //MARK: - button actions
    @IBAction func loginButtonTouchUpInside(_ sender: AnyObject) {
   
        if mode == .signup {
             toggleViewMode(animated: true)
        
        }else{
            print("Email:\(String(describing: loginEmailInputView.textFieldView.text)) Password:\(String(describing: loginPasswordInputView.textFieldView.text))")
            
            let email = loginEmailInputView.textFieldView.text
            let password = loginPasswordInputView.textFieldView.text

            verifyLogin(email: email!, password: password!) { json in
                print("token", json["token"])
                let token = json["token"].string
                let userId = json["userId"].string
                //save token and userId to userDefault
//                self.updateUserDefaultsWithCredentials(token: token!, userId: userId!)
                self.updateKeyChain(email: email!, password: password!, token: token!, userId: userId!)
                self.presentNextVC()
            }
        }
    }
    
//    private func updateUserDefaultsWithCredentials(token: String, userId: String) {
//        UserDefaults.standard.setValue(token, forKey: "token")
//        UserDefaults.standard.setValue(userId, forKey: "userId")
//    }
    
    private func presentNextVC() {

//        let tab = TabViewController()
        
        let nextVC = mainYanShareVC
        let navVC = UINavigationController.init(rootViewController: nextVC!)
        navVC.viewControllers = [nextVC!]
        navVC.navigationBar.topItem?.title = "Yan"
        
        self.present(navVC, animated: true, completion: nil)
        
        
    }
    
    private func submitSignUp(email: String, password: String, callback: @escaping (JSON) -> Void) {
        let param: Parameters = ["username": email, "password": password]
        Alamofire.request(self.signUpURL!, method: .post, parameters: param)
            .responseJSON(completionHandler: { (response: DataResponse) -> Void in
                let json = JSON(data: response.data!)
                if json["status"] == "success" {
                    callback(json)
                }
                else {
                    print("bad sign up")
                    // TODO:
                }
            })
        
    }
    
    @IBAction func signupButtonTouchUpInside(_ sender: AnyObject) {
   
        if mode == .login {
            toggleViewMode(animated: true)
        }else{
            
            //TODO: signup by this data
            NSLog("Email:\(String(describing: signupEmailInputView.textFieldView.text)) Password:\(String(describing: signupPasswordInputView.textFieldView.text)), PasswordConfirm:\(String(describing: signupPasswordConfirmInputView.textFieldView.text))")
            
            let email = signupEmailInputView.textFieldView.text
            let password = signupPasswordInputView.textFieldView.text
            let passwordConfirmation = signupPasswordConfirmInputView.textFieldView.text
            
            if password != passwordConfirmation {
                print("password does not match with confirmation")
                // TODO
            }
            
            submitSignUp(email: email!, password: password!) { json in
                print("token", json["token"])
                let token = json["token"].string
                let userId = json["userId"].string
//                self.updateUserDefaultsWithCredentials(token: token!, userId: userId!)
                self.updateKeyChain(email: email!, password: password!, token: token!, userId: userId!)
                self.presentNextVC()
            }
            
        }
    }
    
    private func updateKeyChain(email: String, password: String, token: String, userId: String) {
        do {
            try Locksmith.saveData(data: ["email": email, "password": password, "token": token, "userId": userId], forUserAccount: "Yan")
        }
        catch let e {
            print(e.localizedDescription)
        }
    }

    //MARK: - toggle view
    func toggleViewMode(animated:Bool){
    
        // toggle mode
        mode = mode == .login ? .signup:.login
        
        
        // set constraints changes
        backImageLeftConstraint.constant = mode == .login ? 0:-self.view.frame.size.width
        
        
        loginWidthConstraint.isActive = mode == .signup ? true:false
        logoCenterConstraint.constant = (mode == .login ? -1:1) * (loginWidthConstraint.multiplier * self.view.frame.size.width)/2
        loginButtonVerticalCenterConstraint.priority = mode == .login ? 300:900
        signupButtonVerticalCenterConstraint.priority = mode == .signup ? 300:900
        
        
        //animate
        self.view.endEditing(true)
        
        UIView.animate(withDuration:animated ? animationDuration:0) {
            
            //animate constraints
            self.view.layoutIfNeeded()
            
            //hide or show views
            self.loginContentView.alpha = self.mode == .login ? 1:0
            self.signupContentView.alpha = self.mode == .signup ? 1:0
            
            
            // rotate and scale login button
            let scaleLogin:CGFloat = self.mode == .login ? 1:0.4
            let rotateAngleLogin:CGFloat = self.mode == .login ? 0:CGFloat(-M_PI_2)
            
            var transformLogin = CGAffineTransform(scaleX: scaleLogin, y: scaleLogin)
            transformLogin = transformLogin.rotated(by: rotateAngleLogin)
            self.loginButton.transform = transformLogin
            
            
            // rotate and scale signup button
            let scaleSignup:CGFloat = self.mode == .signup ? 1:0.4
            let rotateAngleSignup:CGFloat = self.mode == .signup ? 0:CGFloat(-M_PI_2)
            
            var transformSignup = CGAffineTransform(scaleX: scaleSignup, y: scaleSignup)
            transformSignup = transformSignup.rotated(by: rotateAngleSignup)
            self.signupButton.transform = transformSignup
        }
        
    }
    
    
    //MARK: - keyboard
    func keyboarFrameChange(notification:NSNotification){
        
        let userInfo = notification.userInfo as! [String:AnyObject]
        
        // get top of keyboard in view
        let topOfKetboard = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue .origin.y
        
        
        // get animation curve for animate view like keyboard animation
        var animationDuration:TimeInterval = 0.25
        var animationCurve:UIViewAnimationCurve = .easeOut
        if let animDuration = userInfo[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber {
            animationDuration = animDuration.doubleValue
        }
        
        if let animCurve = userInfo[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber {
            animationCurve =  UIViewAnimationCurve.init(rawValue: animCurve.intValue)!
        }
        
        
        // check keyboard is showing
        let keyboardShow = topOfKetboard != self.view.frame.size.height
        
        
        //hide logo in little devices
        let hideLogo = self.view.frame.size.height < 667
        
        // set constraints
        backImageBottomConstraint.constant = self.view.frame.size.height - topOfKetboard
        
        logoTopConstraint.constant = keyboardShow ? (hideLogo ? 0:20):50
        logoHeightConstraint.constant = keyboardShow ? (hideLogo ? 0:40):60
        logoBottomConstraint.constant = keyboardShow ? 20:32
        logoButtomInSingupConstraint.constant = keyboardShow ? 20:32
        
        forgotPassTopConstraint.constant = keyboardShow ? 30:45
        
        loginButtonTopConstraint.constant = keyboardShow ? 25:30
        signupButtonTopConstraint.constant = keyboardShow ? 23:35
        
        loginButton.alpha = keyboardShow ? 1:0.7
        signupButton.alpha = keyboardShow ? 1:0.7
        
        
        
        // animate constraints changes
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(animationDuration)
        UIView.setAnimationCurve(animationCurve)
        
        self.view.layoutIfNeeded()
        
        UIView.commitAnimations()
        
    }
    
    //MARK: - hide status bar in swift3
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
    }
}

