//
//  SearchResultsViewController.swift
//  FoodTracker2
//
//  Created by Vanessa on 8/14/18.
//  Copyright © 2018 BESTFOODS Inc. All rights reserved.
//

import UIKit

class SearchResultsViewController: UIViewController {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var ratingView: RatingControl!
    @IBOutlet weak var ingredientsLabel: UILabel!
    @IBOutlet weak var recipeLabel: UILabel!
    var searchedMeal: SearchedMeal?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        // Do any additional setup after loading the view.
    }

    func configureView(){
        nameLabel.text = searchedMeal!.mealName
        ratingView.rating = searchedMeal!.rating
        ingredientsLabel.text = searchedMeal!.mealIngredients
        recipeLabel.text = searchedMeal!.mealRecipe
        if searchedMeal!.s3Key != "empty"{
            let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(searchedMeal!.s3Key)
            photoImageView.image = UIImage(contentsOfFile: url.path)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func backButtonTapped(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
