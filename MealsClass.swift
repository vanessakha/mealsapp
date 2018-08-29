//
//  MealsClass.swift
//  FoodTracker2
//
//  Created by Vanessa on 8/14/18.
//  Copyright © 2018 BESTFOODS Inc. All rights reserved.
//

import Foundation

class SearchedMeal{
    var userId: String
    var mealId: String
    var creationDate: NSNumber?
    var updateDate: NSNumber?
    var mealName: String
    var mealIngredients: String
    var mealRecipe: String
    var rating: Int
    var averageRating: Float
    var numRaters: Int
    var s3Key: String
    var filePath: String
    var ratersList: [String:String]
//    var ratersList: NSDictionary
//    var filePath: String
    
    init(userId: String, mealId: String, mealName: String, rating: Int, averageRating: Float, numRaters: Int, ingredients: String, recipe: String, creationDate: NSNumber?, updateDate: NSNumber?, filePath: String, s3Key: String, ratersList: [String:String]){
        self.userId = userId
        self.mealId = mealId
        self.creationDate = creationDate
        self.updateDate = updateDate
        self.mealName = mealName
        self.mealIngredients = ingredients
        self.mealRecipe = recipe
        self.filePath = filePath
        self.rating = rating
        self.averageRating = averageRating
        self.numRaters = numRaters
        self.s3Key = s3Key
        self.ratersList = ratersList
        
    }
}
