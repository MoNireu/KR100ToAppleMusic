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


struct MyClaims: Claims {
    let iss: String
    let iat: Date?
    let exp: Date
}



@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var musicChartList = [MusicInfoVO]()
    
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        let myHeader = Header(kid: "475YGH7887")
        let myClaims = MyClaims(iss: "TBWQTY9PVU", iat: Date(), exp: Date(timeIntervalSinceNow: 3600))
        let myJWT = JWT(header: myHeader, claims: myClaims)
        
        let privateKey: Data = """
        -----BEGIN PRIVATE KEY-----
        MIGTAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBHkwdwIBAQQgAp+Z6+iw/pMbwC/3
        sDhz4GY84eTKuHTtD95AorTILG6gCgYIKoZIzj0DAQehRANCAAQUV8CY6NFGWlcB
        lBJVcLU7q7xbTMaXv898HymMpsl4IRPVnioASI5u5jaLu3sijxl0PJVMy2vtwKWm
        n7i04LYr
        -----END PRIVATE KEY-----
""".data(using: .utf8)!
        
        
        do {
            let jwtSigner = JWTSigner.es256(privateKey: privateKey)
            let jwtEncoder = JWTEncoder(jwtSigner: jwtSigner)
            let jwtString = try jwtEncoder.encodeToString(myJWT)
            
            let tokenUtil = TokenUtils()
            tokenUtil.save("monireu.KR100ToAppleMusic", account: "devToken", value: jwtString)
            
            print(jwtString)
        } catch let error as NSError {
            print("JWF ERROR : \(error.localizedDescription)")
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

