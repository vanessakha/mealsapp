//
//  AppDelegate.swift
//  FoodTracker2
//
//  Created by Vanessa on 6/29/18.
//  Copyright © 2018 BESTFOODS Inc. All rights reserved.
//

import UIKit

// Analytics Import(s)
import AWSPinpoint
import AWSCore
import CoreData

// Register/Login Import(s)
import AWSMobileClient
import AWSCognitoIdentityProvider

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UISplitViewControllerDelegate{

    var window: UIWindow?

    var pinpoint: AWSPinpoint?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        let splitViewController = self.window!.rootViewController as! UISplitViewController
        let navigationController = splitViewController.viewControllers[splitViewController.viewControllers.count - 1] as! UINavigationController
        navigationController.topViewController!.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem
        splitViewController.delegate = self

        let masterNavigationController = splitViewController.viewControllers[0] as! UINavigationController
        let controller = masterNavigationController.topViewController as! MealTableViewController
        controller.context = self.persistentContainer.viewContext

        // initialize AWSMobileClient
        let didFinishLaunching = AWSMobileClient.sharedInstance().interceptApplication(application, didFinishLaunchingWithOptions: launchOptions) // register user pool as identity provider
        
        let credentialsProvider = AWSMobileClient.sharedInstance().getCredentialsProvider()
        let configuration = AWSServiceConfiguration(region: .USWest2, credentialsProvider: credentialsProvider)
        AWSServiceManager.default().defaultServiceConfiguration = configuration
        
//        let serviceConfiguration = AWSServiceConfiguration(region: .USWest1, credentialsProvider: nil)
//        let userPoolConfiguration = AWSCognitoIdentityUserPoolConfiguration(clientId: "6nphj7a2f97t21goqrmrtjaueo", clientSecret: "fg6h919plqa0krka6ma132d49n8cc6dgeuod8t279ggo1lnbdq9", poolId: "us-west-2_74y9g4oo3")
//        AWSCognitoIdentityUserPool.register(with: serviceConfiguration, userPoolConfiguration: userPoolConfiguration, forKey: "UserPool")
//        let pool = AWSCognitoIdentityUserPool(forKey: "UserPool")
//        let credentialsProvider = AWSCognitoCredentialsProvider(regionType: .USWest2, identityPoolId: "us-west-2:12a1701a-d229-46f0-87d3-e9b40b93c4df", identityProviderManager: pool)
        
//        let credentialsProvider = AWSCognitoCredentialsProvider(regionType: .USWest2, identityPoolId: "us-west-2:12a1701a-d229-46f0-87d3-e9b40b93c4df")
//        let configuration = AWSServiceConfiguration(region: .USWest2, credentialsProvider: credentialsProvider)
        
//        AWSServiceManager.default().defaultServiceConfiguration = configuration
//        AWSServiceManager.default().defaultServiceConfiguration = AWSServiceConfiguration(region: .USWest2, credentialsProvider: credentialsProvider)
        
        pinpoint = AWSPinpoint(configuration: AWSPinpointConfiguration.defaultPinpointConfiguration(launchOptions: launchOptions))
        
        return didFinishLaunching
    }
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        // create singleton instance of AWSMobileClient
        return AWSMobileClient.sharedInstance().interceptApplication(application, open: url, sourceApplication: sourceApplication, annotation: annotation)
    }

    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool{
        guard let secondaryAsNavController = secondaryViewController as? UINavigationController else{ return false }
        guard let topAsDetailController = secondaryAsNavController.topViewController as? MealViewController else { return false }
        if topAsDetailController.myMeal == nil{
            return true
        }
        return false
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    lazy var persistentContainer: NSPersistentContainer = { // make a persistent container
        let container = NSPersistentContainer(name: "Meal")
        container.loadPersistentStores(){ (storeDescription, error) in // completion handler
            if let error = error as NSError? {
                fatalError("Error! \(error), \(error.userInfo)")
            }
        }
        return container
    }()


}

