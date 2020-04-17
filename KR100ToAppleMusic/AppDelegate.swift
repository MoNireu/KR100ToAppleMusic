//
//  AppDelegate.swift
//  KR100ToAppleMusic
//
//  Created by MoNireu on 2020/01/02.
//  Copyright © 2020 monireu. All rights reserved.
//

import UIKit
import CoreData
import SwiftJWT
import Firebase
import FirebaseFirestore

struct MyClaims: Claims {
    let iss: String
    let iat: Date?
    let exp: Date
}


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var tempMusicChartList: [MusicInfoVO]? = [MusicInfoVO]()
    lazy var musicChartList = [MusicInfoVO]()
    
    lazy var db = Firestore.firestore()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        FirebaseApp.configure()
        
        let tokenUtil = TokenUtils()
        var kid: String?
        var iss: String?
        var privateKey: String?
        
        tokenUtil.downloadDevToken() {(devKid, devIss, devPrivateKey) in
            kid        = devKid
            iss        = devIss
            privateKey = devPrivateKey
            
            let myHeader = Header(kid: kid)
            let myClaims = MyClaims(iss: iss!, iat: Date(), exp: Date(timeIntervalSinceNow: 3600))
            let myJWT = JWT(header: myHeader, claims: myClaims)
            
            
            let privateKeyData: Data = privateKey!.data(using: .utf8)!
            
            
            do {
                let jwtSigner = JWTSigner.es256(privateKey: privateKeyData)
                let jwtEncoder = JWTEncoder(jwtSigner: jwtSigner)
                let jwtString = try jwtEncoder.encodeToString(myJWT)
                
                tokenUtil.save("monireu.KR100ToAppleMusic", account: "devToken", value: jwtString)
                
            } catch let error as NSError {
                print("JWF ERROR : \(error.localizedDescription)")
            }
        }
        return true
    }
    
    // MARK: UISceneSession Lifecycle
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    // MARK: - Core Data stack
    
    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        let container = NSPersistentContainer(name: "KR100ToAppleMusic")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    // MARK: - Core Data Saving support
    
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
}

