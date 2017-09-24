//
//  LoginTableViewController.swift
//  PostalDemo
//
//  Created by Kevin Lefevre on 24/05/2016.
//  Copyright © 2017 Snips. All rights reserved.
//

import UIKit
import Postal
import SVProgressHUD

enum LoginError: Error {
    case badEmail
    case badPassword
    case badHostname
    case badPort
}

extension String: LocalizedError {
    public var errorDescription: String? { return self }
}

struct ConfigurationCodable: Codable {
    /// The hostname of the IMAP server
    public let hostname: String
    
    /// The post of the IMAP server
    public let port: UInt16
    
    /// The login name
    public let login: String
    
    /// The password or the token of the connection
    public let password: String
    
    /// The connection type (secured or not)
    public let connectionType: String
    
    /// Check if the certificate is enabled
    public let checkCertificateEnabled: Bool
    
    /// The bathsize of heavy requests
    public let batchSize: Int
    
    /// The spam folder name
    public let spamFolderName: String
}

func makeConnectionType(str: String) throws -> ConnectionType {
    switch str {
    case "clear":
        return .clear
    case "startTLS":
        return .startTLS
    case "tls":
        return .tls
    default:
        throw "unkown connection type string"
    }
}

func getConnectionTypeRawValues(connectionType: ConnectionType) throws -> String {
    switch connectionType {
    case .clear:
        return "clear"
    case .startTLS:
        return "startTLS"
    case .tls:
        return "tls"
    }
}

func makePasswordType(str: String) throws -> PasswordType {
    return .plain(str)
}

func getPasswordRawValues(passwordType: PasswordType) throws -> String {
    switch passwordType {
    case .plain(let str):
        return str
    default:
        throw "password not plain"
    }
}

extension Configuration {
    
    func copyToCodable() -> ConfigurationCodable {
        let configCodable: ConfigurationCodable = try! ConfigurationCodable(hostname: self.hostname, port: self.port, login: self.login, password: getPasswordRawValues(passwordType: self.password), connectionType: getConnectionTypeRawValues(connectionType: self.connectionType), checkCertificateEnabled: self.checkCertificateEnabled, batchSize: self.batchSize, spamFolderName: self.spamFolderName)
        return configCodable
    }
    
    func encode() -> Data? {
        return try? JSONEncoder().encode(copyToCodable())
    }
    
    static func decode(data: Data) -> Configuration {
        let configCodable = try! JSONDecoder().decode(ConfigurationCodable.self, from: data)
        let config = try! Configuration(hostname: configCodable.hostname, port: configCodable.port, login: configCodable.login, password: makePasswordType(str: configCodable.password), connectionType: makeConnectionType(str: configCodable.connectionType), checkCertificateEnabled: true)
        return config
    }

}

extension LoginError: CustomStringConvertible {
    var description: String {
        switch self {
        case .badEmail: return "Bad mail"
        case .badPassword: return "Bad password"
        case .badHostname: return "Bad hostname"
        case .badPort: return "Bad port"
        }
    }
}

final class LoginTableViewController: UITableViewController {
    fileprivate let mailsSegueIdentifier = "mailsSegue"

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var hostnameTextField: UITextField!
    @IBOutlet weak var portTextField: UITextField!
    
    var config: Configuration?
    
    @IBAction func connectAccount(_ sender: Any) {
        do {
            self.config = try createConfiguration()
            self.postal = Postal(configuration: self.config!)
            self.connectToServer() { e in
                if e != nil {
                    print(e!)
                }
                else {
                    print("connection to \(String(describing: self.config!.hostname)) is successful.")
                    let data: Data? = self.config?.encode()
                    let dataStr = String(data: data!, encoding: String.Encoding.ascii)!
                    print("config encoded: ", dataStr.description)
                    let c = Configuration.decode(data: data!)
                    print("config decoded: ", c.description)
                    SVProgressHUD.showSuccess(withStatus: "Connected")
                }
            }
        } catch let error as LoginError {
            showAlertError("Error login", message: (error as NSError).localizedDescription)
        } catch {
            fatalError()
        }
    }
    
    
    var provider: MailProvider?
    
    var navVC: UINavigationController?
    fileprivate var postal: Postal?
}

// MARK: - View lifecycle

extension LoginTableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let provider = provider, let configuration = provider.preConfiguration {
            emailTextField.placeholder = "exemple@\(provider.hostname)"
            hostnameTextField.isUserInteractionEnabled = false
            hostnameTextField.text = configuration.hostname
            portTextField.isUserInteractionEnabled = false
            portTextField.text = "\(configuration.port)"
        }
    }
}

// MARK: - Navigation management

extension LoginTableViewController {
    
    func connectToServer(callback: @escaping (_ e: Error?) -> Void) {
        SVProgressHUD.show()
        self.postal?.connect(timeout: Postal.defaultTimeout, completion: { [weak self] result in
            switch result {
            case .success:
                SVProgressHUD.dismiss()
//                SVProgressHUD.showSuccess(withStatus: "Connected!")
                let account = self?.config?.login
                let hostname = self?.config?.hostname
                collectionVC.collection.append(account! + "@" + hostname!)
                callback(nil)
                break
            case .failure(let error):
                SVProgressHUD.dismiss()
                self?.showAlertError("Connection error", message: (error as NSError).localizedDescription)
                callback(error)
            }
        })
    }
}

// MARK: - Helpers

extension LoginTableViewController {
    
    func createConfiguration() throws -> Configuration {
        guard let email = emailTextField.text , !email.isEmpty else { throw LoginError.badEmail  }
        guard let password = passwordTextField.text , !password.isEmpty else { throw LoginError.badPassword }
        
        if let configuration = provider?.preConfiguration {
            return Configuration(hostname: configuration.hostname, port: configuration.port, login: email, password: .plain(password), connectionType: configuration.connectionType, checkCertificateEnabled: configuration.checkCertificateEnabled)
        } else {
            guard let hostname = hostnameTextField.text , !hostname.isEmpty else { throw LoginError.badHostname }
            guard let portText = portTextField.text , !portText.isEmpty else { throw LoginError.badPort }
            guard let port = UInt16(portText) else { throw LoginError.badPort }
            
            return Configuration(hostname: hostname, port: port, login: email, password: .plain(""), connectionType: .tls, checkCertificateEnabled: true)
        }
    }
}
