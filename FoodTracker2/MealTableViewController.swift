//
//  MealTableViewController.swift
//  FoodTracker2
//
//  Created by Vanessa on 7/2/18.
//  Copyright © 2018 BESTFOODS Inc. All rights reserved.
//

import UIKit
import os.log

// Analytics Import(s)
import AWSCore
import CoreData
import Foundation
import AWSPinpoint

// Register/Login Import(s)
import AWSAuthCore
import AWSAuthUI
import AWSS3
import AWSCognitoIdentityProvider

class MealTableViewController: UITableViewController, NSFetchedResultsControllerDelegate {
    //MARK: Properties
//    var mealsContentProvider : MealsContentProvider? = nil
    var _detailViewController: MealViewController? = nil
    var _mealsContentProvider: MealsContentProvider? = nil
    var _fetchedResultsController: NSFetchedResultsController<Meal>? = nil
    var context: NSManagedObjectContext? = nil
    var meals: [NSManagedObject] = []
    static var absDocURL: URL?
    
    // MARK: Basic (Keyword) Controller Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.delegate = self
        self.tableView.backgroundColor = UIColor.orange
        let fileManager = FileManager.default
        MealTableViewController.absDocURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        print("docs path is \(MealTableViewController.absDocURL!.path)")
        
        if !(AWSSignInManager.sharedInstance().isLoggedIn){
            AWSAuthUIViewController.presentViewController(with: self.navigationController!, configuration: nil) {(provider: AWSSignInProvider, error: Error?) in
                if error != nil{
                    print("Error occurred: \(String(describing: error))")
                }
                else{
                    // Sign-in successful
                }
            }
        }
    
//        let credentialsProvider = AWSCognitoCredentialsProvider(regionType: .USWest2, identityPoolId: "us-west-2:12a1701a-d229-46f0-87d3-e9b40b93c4df")
//        let serviceConfiguration = AWSServiceConfiguration(region: .USWest2, credentialsProvider: credentialsProvider)
        let serviceConfiguration = AWSServiceConfiguration(region: .USWest1, credentialsProvider: nil)
        let userPoolConfiguration = AWSCognitoIdentityUserPoolConfiguration(clientId: "6nphj7a2f97t21goqrmrtjaueo", clientSecret: "fg6h919plqa0krka6ma132d49n8cc6dgeuod8t279ggo1lnbdq9", poolId: "us-west-2_74y9g4oo3")
        AWSCognitoIdentityUserPool.register(with: serviceConfiguration, userPoolConfiguration: userPoolConfiguration, forKey: "UserPool")
        let pool = AWSCognitoIdentityUserPool(forKey: "UserPool")
        let credentialsProvider = AWSCognitoCredentialsProvider(regionType: .USWest2, identityPoolId: "us-west-2:12a1701a-d229-46f0-87d3-e9b40b93c4df", identityProviderManager: pool)
        AWSServiceManager.default().defaultServiceConfiguration = AWSServiceConfiguration(region: .USWest2, credentialsProvider: credentialsProvider)
        
        context?.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        _mealsContentProvider = MealsContentProvider()
        
        navigationItem.leftBarButtonItem = editButtonItem
        
        let addMealButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(insertNewMeal(_:)))
        navigationItem.rightBarButtonItem = addMealButton
        
        if let split = splitViewController {
            let controllers = split.viewControllers
            _detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? MealViewController
        }
        
        print("About to query.")
        _mealsContentProvider?.getMealsFromDDB()
    }
    
    override func viewWillAppear(_ animated: Bool){
        clearsSelectionOnViewWillAppear = splitViewController!.isCollapsed // change
        super.viewWillAppear(animated)
    }
    
    @objc func insertNewMeal(_ sender: Any){
        self.performSegue(withIdentifier: "showDetail", sender: (Any).self);
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?){
        if segue.identifier == "showDetail" {
            print("Performing segue")
            if let indexPath = tableView.indexPathForSelectedRow {
                let object = fetchedResultsController.object(at: indexPath)
                let controller = (segue.destination as! UINavigationController).topViewController as! MealViewController
                controller.myMeal = object
                controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
//                controller.navigationItem.leftBarButtonItem!.action = #selector(controller.mealViewWillDisappear()
//                controller.navigationItem.leftBarButtonItem!.target = controller
                controller.navigationItem.leftItemsSupplementBackButton = true
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = fetchedResultsController.sections![section] // get information about fetched core data results
        return sectionInfo.numberOfObjects // get number of objects in core data
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> MealTableViewCell {
        let cellIdentifier = "MealTableViewCell"
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? MealTableViewCell else{
            fatalError("The dequeued cell is not an instance of MealTableViewCell.")
            } // change
        let event = fetchedResultsController.object(at: indexPath)
        
        configureCell(cell, withEvent: event)

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
        _ = indexPath
        self.performSegue(withIdentifier: "showDetail", sender: indexPath)
    }

    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
 
    

    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let context = fetchedResultsController.managedObjectContext
            let mealObj = fetchedResultsController.object(at: indexPath)
            let mealId = fetchedResultsController.object(at: indexPath).mealId
    
            _mealsContentProvider?.delete(context: context, managed_object: mealObj, mealId: mealId)
            _mealsContentProvider?.deleteMealDDB(mealId: mealId!)
        }
    }

    func configureCell(_ cell: MealTableViewCell, withEvent event: Meal){
        cell.nameLabel.text = event.name
        cell.ratingControl.rating = Int(event.rating)
//        print("configuring cell. file path is \(String(describing: event.filePath))")
        if let meal_photo_path = event.filePath{
            let absFilePath = MealTableViewController.absDocURL!.appendingPathComponent("\(meal_photo_path)").path
            if !absFilePath.isEmpty && FileManager.default.fileExists(atPath: absFilePath){
                if let image = UIImage(contentsOfFile: absFilePath){
                    cell.photoImageView.image = image
                }
            }
        }
        
        
        // change: add photo, implement rating control
    }

    var fetchedResultsController: NSFetchedResultsController<Meal> {
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }
        
        let fetchRequest: NSFetchRequest<Meal> = Meal.fetchRequest()
        
        fetchRequest.fetchBatchSize = 20 // ?
        
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
        
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.context!, sectionNameKeyPath: nil, cacheName: "Master")
        aFetchedResultsController.delegate = self
        _fetchedResultsController = aFetchedResultsController
        
        do{
            try _fetchedResultsController!.performFetch()
        }
        catch{
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
        return _fetchedResultsController!
    }

    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>){
        tableView.beginUpdates()
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type{
            case .insert:
                tableView.insertRows(at: [newIndexPath!], with: .fade)
            case .delete:
                tableView.deleteRows(at: [indexPath!], with: .fade)
            case .update:
                configureCell(tableView.cellForRow(at: indexPath!)! as! MealTableViewCell, withEvent: anObject as! Meal)
            case .move:
                configureCell(tableView.cellForRow(at: indexPath!)! as! MealTableViewCell, withEvent: anObject as! Meal)
                tableView.moveRow(at: indexPath!, to: newIndexPath!)
        }
    }
    
    func controllerDidChangeContent(_ content: NSFetchedResultsController<NSFetchRequestResult>){
            tableView.endUpdates()
    }
}
