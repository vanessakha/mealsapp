//
//  FoodTracker2Tests.swift
//  FoodTracker2Tests
//
//  Created by Vanessa on 6/29/18.
//  Copyright © 2018 BESTFOODS Inc. All rights reserved.
//

import XCTest
@testable import FoodTracker2
// gives tests access to implementation of FoodTracker2

class FoodTracker2Tests: XCTestCase {
    //MARK: Meal Class Tests
    
    // confirm that the Meal initializer returns a Meal object when passed valid parameters
    func testMealInitializationSucceeds(){
        
        // Zero rating
        let zeroRatingMeal = Meal.init(name: "Zero", photo: nil, rating: 0)
        XCTAssertNotNil(zeroRatingMeal)
        
        // Highest positive rating
        let positiveRatingMeal = Meal.init(name: "Positive", photo: nil, rating: 5)
        XCTAssertNotNil(positiveRatingMeal)
    }
    
    func testMealInitializationFails(){
        
        // Negative ratings
        let negativeRatingMeal = Meal.init(name: "Negative", photo: nil, rating: -1)
        XCTAssertNil(negativeRatingMeal)
        
        // Rating exceeds maximum
        let largeRatingMeal = Meal.init(name: "large", photo: nil, rating: 6)
        XCTAssertNil(largeRatingMeal)
        // Empty String
        let emptyStringMeal = Meal.init(name: "", photo: nil, rating: 0)
        XCTAssertNil(emptyStringMeal)
    }
    
    
}
