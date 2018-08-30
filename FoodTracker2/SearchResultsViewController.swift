//
//  SearchResultsViewController.swift
//  FoodTracker2
//
//  Created by Vanessa on 8/14/18.
//  Copyright © 2018 BESTFOODS Inc. All rights reserved.
//

import UIKit
import AWSMobileClient

class SearchResultsViewController: UIViewController {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var ratingView: RatingControl!
    @IBOutlet weak var ingredientsLabel: UILabel!
    @IBOutlet weak var recipeLabel: UILabel!
    @IBOutlet weak var averageRatingLabel: UILabel!
    //    var autoSaveTimer: Timer?
    var searchedMeal: SearchedMeal?
    var initialRating: Int?
    var mealsContentProvider: MealsContentProvider?
    var index: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        
        mealsContentProvider = MealsContentProvider()
        
        initialRating = ratingView.rating
        
    }
    
    func configureView(){
        print("average rating while configuring: \(searchedMeal!.averageRating)")
        nameLabel.text = searchedMeal!.mealName
        self.initialRating = 0
        ratingView.rating = 0 // change searchedMeal.rating
        ingredientsLabel.text = searchedMeal!.mealIngredients
        recipeLabel.text = searchedMeal!.mealRecipe
        if searchedMeal!.s3Key != "empty"{
            let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(searchedMeal!.s3Key)
            photoImageView.image = UIImage(contentsOfFile: url.path)
        }
        let userId = AWSIdentityManager.default().identityId
        print("userId: \(userId)")
        let ratersList = searchedMeal!.ratersList
        print("got ratersList: \(ratersList)")
        print("previous rating = \(ratersList[userId!])")
        if let previousRating = ratersList[userId!]{
            if let intRating = Int(previousRating){
                self.initialRating = intRating
                print("previousRating: \(intRating)")
                ratingView.rating = intRating
            }
            else{
                print("Can't convert rating from string to int")
            }
        }
        else{
            print("Can't find previous rating")
        }
        
        averageRatingLabel.text = "\(searchedMeal!.averageRating) carrots"
    }
    
    override func viewWillDisappear(_ animated: Bool){
        
        // update average rating
        // change: repeat of code in meal view controller, make into function
        
        let currentRating = ratingView.rating
        let origNumRaters = searchedMeal!.numRaters
        let origAverageRating = searchedMeal!.averageRating
        let newNumRaters: Int?
        let newAverageRating: Float?
        let new_rating = ratingView.rating
        var ratersList = searchedMeal!.ratersList
        let raterId = AWSIdentityManager.default().identityId
        
        if initialRating == 0{
            if new_rating != 0{
                // rating changes, numRaters changes
                newNumRaters = origNumRaters + 1
                newAverageRating = ((origAverageRating * Float(origNumRaters)) + Float(currentRating)) / Float(newNumRaters!)
                ratersList[raterId!] = String(currentRating)
            }
            else{
                // nothing changes
                newNumRaters = origNumRaters
                newAverageRating = origAverageRating
            }
        }
        else{
            // rating changes, numRaters stays same
            newNumRaters = origNumRaters
            newAverageRating = (origAverageRating * Float(newNumRaters!) - Float(initialRating!) + Float(currentRating)) / Float(newNumRaters!)
            ratersList[raterId!] = String(currentRating)
        }
        
        let userId = searchedMeal!.userId
        let mealId = searchedMeal!.mealId
        let mealName = searchedMeal!.mealName
        let rating = searchedMeal!.rating
        let averageRating = newAverageRating
        let numRaters = newNumRaters
        let ingredients = searchedMeal!.mealIngredients
        let recipe = searchedMeal!.mealRecipe
        let creationDate = searchedMeal!.creationDate
        let updateDate = searchedMeal!.updateDate
        let s3Key = searchedMeal!.s3Key
        let filePath = searchedMeal!.filePath
        
        print("averageRating before saving: \(searchedMeal!.averageRating)")
        // only update if user hasn't rated meal yet
        mealsContentProvider?.updateMealDDB(userId: userId, mealId: mealId, mealName: mealName, rating: rating, averageRating: averageRating!, numRaters: numRaters!, ingredients: ingredients, recipe: recipe, filePath: filePath, s3Key: s3Key, ratersList: ratersList)
        SearchViewController.searchedMeals[index!] = SearchedMeal(userId: userId, mealId: mealId, mealName: mealName, rating: rating, averageRating: averageRating!, numRaters: numRaters!, ingredients: ingredients, recipe: recipe, creationDate: creationDate, updateDate: updateDate, filePath: filePath, s3Key: s3Key, ratersList: ratersList)
        print("ratersList saved: \(ratersList)")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func backButtonTapped(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }

}
