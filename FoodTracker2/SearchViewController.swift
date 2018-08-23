//
//  SearchViewController.swift
//  FoodTracker2
//
//  Created by Vanessa on 8/14/18.
//  Copyright © 2018 BESTFOODS Inc. All rights reserved.
//

import UIKit
import Foundation
import AWSDynamoDB
import AWSCognitoIdentityProvider
import AWSS3
import AWSMobileClient

class SearchViewController: UITableViewController {
    
    static var searchedMeals = [SearchedMeal]()
//    var mealsContentProvider = MealsContentProvider()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.backgroundColor = UIColorFromRGB(rgbValue: 0xFFB3B3)
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search Meals"
        navigationItem.searchController = searchController
        definesPresentationContext = true
//        searchController.searchBar.delegate = self
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool){
        super.viewWillAppear(animated)
        if #available(iOS 11.0, *){
            navigationItem.hidesSearchBarWhenScrolling = false
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    override func viewDidAppear(_ animated: Bool) {
        if #available(iOS 11.0, *){
            self.navigationItem.hidesSearchBarWhenScrolling = true
        }
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return SearchViewController.searchedMeals.count
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! SearchViewCell
        
        // configure cell
        let meal = SearchViewController.searchedMeals[indexPath.row]
        cell.nameLabel.text = meal.mealName
        cell.ratingControl.rating = meal.rating
        
        if meal.s3Key != "empty"{
            print("meal s3key isn't empty")
//            let imageKey = NSUUID().uuidString
            let downloadingFileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(meal.s3Key)
            let downloadRequest = AWSS3TransferManagerDownloadRequest()!
            downloadRequest.bucket = "mealsapp-userfiles-mobilehub-1459387644/public"
            downloadRequest.key = meal.s3Key
            downloadRequest.downloadingFileURL = downloadingFileURL
            
//            let credentialsProvider = AWSMobileClient.sharedInstance().getCredentialsProvider()
//            let configuration = AWSServiceConfiguration(region: .USWest2, credentialsProvider: credentialsProvider)
//            AWSServiceManager.default().defaultServiceConfiguration = configuration
            print("about to make transfer manager")
            let transferManager = AWSS3TransferManager.default()
            print("made transfer manaager")
            transferManager.download(downloadRequest).continueWith(executor: AWSExecutor.mainThread(), block: { (task: AWSTask<AnyObject>) -> Any? in
                print("about to attempt download")
                if let error = task.error as? NSError {
                    if error.domain == AWSS3TransferManagerErrorDomain, let code = AWSS3TransferManagerErrorType(rawValue: error.code){
                        switch code{
                        case .cancelled, .paused:
                            break
                        default:
                            print("Error downloading: \(String(describing: downloadRequest.key))\nError: \(String(describing:error))")
                        }
                    }
                    else{
                        print("Error downloading: \(String(describing: downloadRequest.key))\nError: \(String(describing: error))")
                    }
                    return nil
                }
                print("Download complete for \(String(describing: downloadRequest.key))")
                cell.cellImageView.image = UIImage(contentsOfFile: downloadingFileURL.path)
                
                DispatchQueue.main.async{
                    self.tableView.reloadData()
                }
                
                return nil
            })
        }
        
        return cell
        
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.performSegue(withIdentifier: "showSearchDetail", sender: indexPath)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showSearchDetail"{
            let myIndexPath = self.tableView.indexPathForSelectedRow
            let controller = (segue.destination as! UINavigationController).topViewController as! SearchResultsViewController
            controller.searchedMeal = SearchViewController.searchedMeals[myIndexPath!.row]
        }
    }
    
    func searchMealsDDB(searchRequest: String){
        if searchRequest.isEmpty {
            print("Empty search request")
            return
        }
        print("searching for: \(searchRequest)")
        let queryExpression = AWSDynamoDBQueryExpression()
        queryExpression.indexName = "search_name"
        queryExpression.keyConditionExpression = "lowercase_name = :searchRequest"
        queryExpression.expressionAttributeValues = [
            ":searchRequest": searchRequest.lowercased()
        ]
        let object_mapper = AWSDynamoDBObjectMapper.default()
        object_mapper.query(Meals.self, expression: queryExpression).continueWith(block: {(task:AWSTask<AWSDynamoDBPaginatedOutput>!)-> Any? in
            if task.error != nil{
                print("DynamoDB query request failed. Error: \(String(describing: task.error))")
            }
            if let paginatedOutput = task.result{
                print("searching for meals")
                var count = 0
                for meal in paginatedOutput.items{
                    if count > 20{
                        print("count is greater than 20")
                        break
                    }
                    let meal = meal as! Meals
                    print("UserId: \(meal._userId!)\nMealId: \(meal._mealId!)\nName: \(meal._name!)\nRating: \(meal._rating!)\nIngredients \(meal._rating!)\nRecipe: \(meal._recipe!)\nS3Key: \(meal._s3Key)")
                    let searchedMeal = SearchedMeal(userId: meal._userId!, mealId: meal._mealId!, mealName: meal._name!, rating: meal._rating! as! Int, ingredients: meal._ingredients!, recipe: meal._recipe!, creationDate: meal._creationDate!, updateDate: meal._updateDate!, s3Key: meal._s3Key ?? "empty")
                    count += 1
                    SearchViewController.searchedMeals.append(searchedMeal)
                    print("number of searchedMeals entries: \(String(SearchViewController.searchedMeals.count))")
                    DispatchQueue.main.async{
                        self.tableView.reloadData()
                    }
                }
            }
            print("leaving query")
            return nil
        }) //?
    }
    
    @IBAction func backButtonTapped(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func UIColorFromRGB(rgbValue: UInt)->UIColor{
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16)/255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8)/255.0,
            blue: CGFloat(rgbValue & 0x0000FF)/255.0,
            alpha: CGFloat(1.0)
        )
    }
}

extension SearchViewController: UISearchResultsUpdating{
    func updateSearchResults(for searchController: UISearchController) {
        SearchViewController.searchedMeals = []
        searchMealsDDB(searchRequest: searchController.searchBar.text!)
    }
}
