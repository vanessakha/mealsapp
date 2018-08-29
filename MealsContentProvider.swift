//
//  MealsContentProvider.swift
//  FoodTracker2
//
//  Created by Vanessa on 7/23/18.
//  Copyright © 2018 BESTFOODS Inc. All rights reserved.
//

import Foundation
import CoreData
import UIKit
import AWSCore
import AWSPinpoint
import AWSDynamoDB
import AWSAuthCore

public class MealsContentProvider{
    var myMeals: [NSManagedObject] = []
    
    func get_context() -> NSManagedObjectContext{
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext // created persistentContainer property in AppDelegate
        return context
    }
    
    // MARK: NSManagedObjectContext Methods
    
    // creating new meals in NSManagedObjectContext
    func insert(mealName: String, rating: Int, averageRating: Float, numRaters: Int, ingredients: String, recipe: String, filePath: String, s3Key: String) ->  String{
        let context = get_context()
        
        let entity = NSEntityDescription.entity(forEntityName: "Meal", in: context)!
        
        // create an instance of the entity, insert into the context
        let meal = NSManagedObject(entity: entity, insertInto: context)
        
        // new meal Id
        let mealId = NSUUID().uuidString
        meal.setValue(NSDate(), forKeyPath: "creationDate")
        print("New meal being created in core data. \(mealId)")

        meal.setValue(mealId, forKeyPath: "mealId")
        meal.setValue(mealName, forKeyPath: "name")
        meal.setValue(rating, forKeyPath: "rating")
        meal.setValue(ingredients, forKeyPath: "ingredients")
        meal.setValue(recipe, forKeyPath: "recipe")
        meal.setValue(filePath, forKeyPath: "filePath")
        meal.setValue(s3Key, forKeyPath: "s3Key")
        meal.setValue(averageRating, forKeyPath: "averageRating")
        meal.setValue(numRaters, forKeyPath: "numRaters")
        
//        print("before creating ratersList in core data")
        
//        meal.setValue(ratersList, forKeyPath: "ratersList")
        
        
        print("new meal created in core data")
        print("Set filepath to \(filePath)")
        
        do{
            try context.save()
            myMeals.append(meal)
        }
        catch let error as NSError{
            print("Couldn't save meal in core data. \(error)")
        }
        print("New Meal Saved in core data: \(mealId)")
        return mealId
    }
    
    // updating = creating new object
    func update(mealId: String, mealName: String, rating: Int, averageRating: Float, numRaters: Int, ingredients: String, recipe: String, filePath: String, s3Key: String, ratersList: [String: String]){
        let context = get_context()
        let meal_entity = NSEntityDescription.entity(forEntityName: "Meal", in: context)!
        
        let meal = NSManagedObject(entity: meal_entity, insertInto: context)
        meal.setValue(NSDate(), forKeyPath: "updateDate")
        print("Updating meal with mealId in core data: \(mealId).")
        
        meal.setValue(mealId, forKeyPath: "mealId")
        meal.setValue(mealName, forKeyPath: "name")
        meal.setValue(rating, forKeyPath: "rating")
        meal.setValue(ingredients, forKeyPath: "ingredients")
        meal.setValue(recipe, forKeyPath: "recipe")
        meal.setValue(filePath, forKeyPath: "filePath")
        meal.setValue(s3Key, forKeyPath: "s3Key")
        meal.setValue(averageRating, forKeyPath: "averageRating")
        meal.setValue(numRaters, forKeyPath: "numRaters")
        print("before mutable set value called.")
        var raters = meal.mutableSetValue(forKey: "rater")
        print("after mutable set value called.")
        let rater_entity = NSEntityDescription.entity(forEntityName: "Rater", in: context)!
        print("after rater entity created")
        let meal_rater = NSManagedObject(entity: rater_entity, insertInto: context)
        print("after meal rater created")
        
        // update relationships list
        for (key, value) in ratersList{
            if key == "empty"{
                print("key is empty")
                continue
            }
            print("before setting userId value for rater")
            meal_rater.setValue(key, forKeyPath: "userId")
            print("after setting userId value for rater")
            meal_rater.setValue(value, forKeyPath: "rating")
            print("after setting rating value for rater")
            raters.add(meal_rater)
        }

        
        print("Updated filepath to \(filePath)")
        
        do{
            try context.save()
            myMeals.append(meal)
        }
        catch let error as NSError{
            print("Couldn't save (update) meal in core data. \(error), \(error.userInfo)")
        }
        print("Updated meal with mealId: \(mealId)")
    }
    
    func delete(context: NSManagedObjectContext, managed_object: NSManagedObject, mealId: String!){
        context.delete(managed_object)
        do {
            try context.save()
            print("Deleted local MealId in core data: \(mealId)")
            
        }
        catch{
            let nserror = error as NSError
            fatalError("Error with deletion in core data\(nserror), \(nserror.userInfo)")
        }
    }
    
    // MARK: Database Mutation Functions
    
    // inserting into database
    func insertMealDDB(mealId: String, mealName: String, rating: Int, averageRating: Float, numRaters: Int, ingredients: String, recipe: String, filePath: String, s3Key: String, ratersList: [String:String])->String{
        
        var meal_ratersList = ratersList
        let object_mapper = AWSDynamoDBObjectMapper.default()
        let meal: Meals = Meals()
        
        meal._userId = AWSIdentityManager.default().identityId
        meal._mealId = mealId
        meal._name = mealName
        meal._rating = rating as NSNumber
        meal._averageRating = averageRating as NSNumber
        meal._numRaters = numRaters as NSNumber
        meal._ingredients = ingredients
        meal._recipe = recipe
        meal._filePath = filePath
        meal._s3Key = s3Key
        meal._creationDate = NSDate().timeIntervalSince1970 as NSNumber
        meal._lowercaseName = mealName.lowercased()
        if ratersList.isEmpty{
            meal_ratersList["empty"] = "empty"
        }
        meal._ratersList = meal_ratersList
        
        object_mapper.save(meal){ (error: Error?) -> Void in
            if let error = error {
                print("Amazon DynamoDB Save Error on new meal: \n\(error)")
                return
            }
            print("New meal was saved to DDB.")
        }
        return meal._mealId!
    }
    
    func updateMealDDB(userId: String, mealId: String, mealName: String, rating: Int, averageRating: Float, numRaters: Int, ingredients: String, recipe: String, filePath: String, s3Key: String, ratersList: [String: String]){
        
        var meal_ratersList = ratersList
        let object_mapper = AWSDynamoDBObjectMapper.default()
        
        let meal: Meals = Meals()
//        meal._userId = AWSIdentityManager.default().identityId
        meal._userId = userId
        meal._mealId = mealId
        meal._name = mealName
        meal._rating = rating as NSNumber
        meal._averageRating = averageRating as NSNumber
        meal._numRaters = numRaters as NSNumber
        meal._lowercaseName = mealName.lowercased()
        meal._ingredients = ingredients
        meal._recipe = recipe
        meal._filePath = filePath
        meal._s3Key = s3Key
        if ratersList.isEmpty{
            meal_ratersList["empty"] = "empty"
        }
        meal._ratersList = meal_ratersList
        
//        if (!mealName.isEmpty){
//            meal._name = mealName
//            meal._lowercaseName = mealName.lowercased()
//        }
//        else{
//            meal._name = ""
//            meal._lowercaseName = ""
//        }
//        meal._rating = rating as NSNumber
//        if (!ingredients.isEmpty){
//            meal._ingredients = ingredients
//        }
//        else{
//            meal._ingredients = ""
//        }
//        if (!recipe.isEmpty){
//            meal._recipe = recipe
//        }
//        else{
//            meal._recipe = ""
//        }
        
        
        meal._updateDate = NSDate().timeIntervalSince1970 as NSNumber
        
        let updateMapperConfig = AWSDynamoDBObjectMapperConfiguration()
        updateMapperConfig.saveBehavior = .updateSkipNullAttributes
        object_mapper.save(meal, configuration: updateMapperConfig) { (error:Error?) in
            if let error = error {
                print("Amazon DynamoDB Save Error on meal update: \n\(error)")
                return
            }
            print("Existing meal updated in DDB.")
        }
    }
    
    func deleteMealDDB(mealId: String){
        let object_mapper = AWSDynamoDBObjectMapper.default()
        let meal_to_delete = Meals()
        meal_to_delete?._userId = AWSIdentityManager.default().identityId // optional chaining
        meal_to_delete?._mealId = mealId
        object_mapper.remove(meal_to_delete!){ (error: Error?) -> Void in
            if let error = error {
                print("Amazon DynamoDB deletion error \(error)")
                return
            }
            print("Meal deleted in DDB.")
        }
    }
    
    // MARK: Database Query Functions
    
    func getMealsFromDDB(){
        // query and update local data
        print("getting meals from db")
        let queryExpression = AWSDynamoDBQueryExpression()
        queryExpression.keyConditionExpression = "#userId = :userId"
        queryExpression.expressionAttributeNames = [
            "#userId": "userId"
        ]
        queryExpression.expressionAttributeValues = [
            ":userId": AWSIdentityManager.default().identityId
        ]
        let object_mapper = AWSDynamoDBObjectMapper.default()
        print("about to perform actual query")
        object_mapper.query(Meals.self, expression: queryExpression){ (output: AWSDynamoDBPaginatedOutput?, error: Error?) in // ? how do I access query items?
            print("querying")
            if error != nil {
                print("DynamoDB query request failed. Error: \(String(describing: error))")
            }
            if output != nil{
                print("Found [\(output!.items.count)] meals")
                for meal in output!.items {
                    let meal = meal as? Meals
                    print("\nMealId: \(meal!._mealId!)\nTitle: \(meal!._name!)\nRating: \(meal!._rating!)\nAverage Rating: \(meal!._averageRating!)\nNum Raters: \(meal!._numRaters!)\nIngredients: \(meal!._ingredients!)\nRecipe: \(meal!._recipe!)\nLowercased name: \(meal!._lowercaseName!)\nratersList: \(meal!._ratersList)")
                    
                    // update core data
                    DispatchQueue.main.async{
                        self.update(mealId: meal!._mealId!, mealName: meal!._name!, rating: meal!._rating! as! Int, averageRating: meal!._averageRating!.floatValue, numRaters: meal!._numRaters! as! Int, ingredients: meal!._ingredients!, recipe: meal!._recipe!, filePath: meal!._filePath ?? "", s3Key: meal!._s3Key ?? "", ratersList: meal!._ratersList!)
                    }
                }
                print("got meals from DDB")
                
            }
        }
    }
    
}
