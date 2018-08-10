//
//  ViewController.swift
//  FoodTracker2
//
//  Created by Vanessa on 6/29/18.
//  Copyright © 2018 BESTFOODS Inc. All rights reserved.
//

import UIKit
import os.log
import Foundation
import CoreData
import CoreGraphics
import AWSS3

class MealViewController: UIViewController, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextViewDelegate {
    // MARK: Properties
    var mealsContentProvider: MealsContentProvider? = nil
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var ratingControl: RatingControl!
//    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var ingredientsTextView: UITextView!
    @IBOutlet weak var recipeTextView: UITextView!
    var dismissKeyboardTapGesture: UITapGestureRecognizer?
//    var meal: Meal? //change
    
    var autoSaveTimer: Timer!
    static var mealId: String?
    var meals: [NSManagedObject] = []
    var filePath: String = ""
    var is_presenting_picker = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.isUserInteractionEnabled = true
        
        autoSaveTimer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(autoSave), userInfo: nil, repeats: true)
        
        mealsContentProvider = MealsContentProvider()
        
        configureView()
    }
    
    var myMeal: Meal? {
        didSet{
            MealViewController.mealId = myMeal?.value(forKey: "mealId") as? String
            configureView()
            self.filePath = myMeal?.value(forKey: "filePath") as! String
        }
    }
    
    func configureView(){
        if let meal_name = myMeal?.value(forKey: "name") as? String {
            nameTextField?.text = meal_name
        }
        if let meal_rating = myMeal?.value(forKey: "rating") as? Int {
            ratingControl?.rating = meal_rating
        }
        if let meal_recipe = myMeal?.value(forKey: "recipe") as? String {
            recipeTextView?.text = meal_recipe
        }
        if let meal_ingredients = myMeal?.value(forKey: "ingredients") as? String {
            ingredientsTextView?.text = meal_ingredients
        }
        if let meal_photo_path = myMeal?.value(forKey: "filePath") as? String{
            let absFilePath = MealTableViewController.absDocURL!.appendingPathComponent(meal_photo_path).path
            if !absFilePath.isEmpty && FileManager.default.fileExists(atPath: absFilePath){
                if let photo = UIImage(contentsOfFile: absFilePath){
                    self.photoImageView?.image = photo
                }
            }
        }
    }
    
    @objc func autoSave(){
        if (MealViewController.mealId == nil){
            // new meal
            let id = mealsContentProvider?.insert(mealName: "new meal", rating: 0, ingredients: "ingredients", recipe: "recipe", filePath: "")
            mealsContentProvider?.insertMealDDB(mealId: id!, mealName: "new meal", rating: 0, ingredients: ingredientsTextView.text!, recipe: recipeTextView.text!)
            MealViewController.mealId = id
        }
        else{
            // update meal
            let meal_id = MealViewController.mealId
            var meal_name = self.nameTextField.text!
            if meal_name.isEmpty{
                meal_name = "new meal"
            }
            let meal_rating = self.ratingControl.rating
            let meal_ingredients = self.ingredientsTextView.text
            let meal_recipe = self.recipeTextView.text
            let meal_photo_path = self.filePath
            mealsContentProvider?.update(mealId: meal_id!, mealName: meal_name, rating: meal_rating, ingredients: meal_ingredients!, recipe: meal_recipe!, filePath: meal_photo_path)
            mealsContentProvider?.updateMealDDB(mealId: meal_id!, mealName: meal_name, rating: meal_rating, ingredients: meal_ingredients!, recipe: meal_recipe!)
        }
    }
    override func viewDidAppear(_ animated: Bool){
        super.viewDidAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(MealViewController.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MealViewController.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        print("View about to disappear")
        NotificationCenter.default.removeObserver(self)
        super.viewWillDisappear(animated)
        if !is_presenting_picker{
            if autoSaveTimer != nil{
                autoSaveTimer.invalidate()
            }
            
            let mealId = MealViewController.mealId
            
            if mealId == nil {
                print("no meal id")
            }
            if mealId != nil{ // update new meal one last time
                let meal_id = MealViewController.mealId
                var meal_name = self.nameTextField.text!
                if meal_name.isEmpty{
                    meal_name = "new meal"
                }
                let meal_rating = self.ratingControl.rating
                let meal_ingredients = self.ingredientsTextView.text
                let meal_recipe = self.recipeTextView.text
                let meal_photo_path = self.filePath
                mealsContentProvider?.update(mealId: meal_id!, mealName: meal_name, rating: meal_rating, ingredients: meal_ingredients!, recipe: meal_recipe!, filePath: meal_photo_path)
                mealsContentProvider?.updateMealDDB(mealId: meal_id!, mealName: meal_name, rating: meal_rating, ingredients: meal_ingredients!, recipe: meal_recipe!) // ?
            }
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        if !is_presenting_picker{
            MealViewController.mealId = nil
        }
        return
    }
    
    @objc func keyboardWillShow(notification: NSNotification){
        if dismissKeyboardTapGesture == nil{
            dismissKeyboardTapGesture = UITapGestureRecognizer(target: self, action: #selector(MealViewController.dismissKeyboard))
            self.view.addGestureRecognizer(dismissKeyboardTapGesture!)
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification){
        if dismissKeyboardTapGesture != nil{
            self.view.removeGestureRecognizer(dismissKeyboardTapGesture!)
            dismissKeyboardTapGesture = nil
        }
    }
    
    @objc func dismissKeyboard(sender: AnyObject){
//        self.view.endEditing(true)
        ingredientsTextView.resignFirstResponder()
        recipeTextView.resignFirstResponder()
    }
    
    //MARK: UITextView Methods
    
    // UITextView Delegate Methods
    func textViewDidBeginEditing(_ textView: UITextView) {
        textView.backgroundColor = UIColor.lightGray
    }
    func textViewDidEndEditing(_ textView: UITextView) {
        textView.backgroundColor = UIColor.white
    }
    
    //MARK: UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    func textFieldDidEndEditing(_ textField: UITextField) {
//        updateSaveButtonState()
        navigationItem.title = textField.text
    }
    //MARK: UIImagePickerControllerDelegate
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController){
        is_presenting_picker = false
        picker.dismiss(animated: true, completion: nil)
        
    }
    @objc func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String:Any]){
        
        print("mealId: \(String(describing: MealViewController.mealId))")
        let fileManager = FileManager.default
        let documentPath = MealTableViewController.absDocURL!.path
        let selectedImageTag = NSUUID().uuidString
        let relFilePath = "\(String(selectedImageTag)).png"
        let absFilePath = MealTableViewController.absDocURL!.appendingPathComponent(relFilePath)
        guard let selectedImage = info[UIImagePickerControllerOriginalImage] as? UIImage else{
            fatalError("Expected a dictionary containing an image, but was provided the following: \(info)")
        }
        do{ // change?
            let files = try fileManager.contentsOfDirectory(atPath: "\(documentPath)")
            print("Accessed files")
            for file in files {
                if "\(documentPath)/\(file)" == absFilePath.path {
                    print("Removed file if it already exists.")
                    try fileManager.removeItem(atPath: absFilePath.path)
                }
            }
        }
        catch{
            print("Could not add image from document directory: \(error)")
        }
        
        do{
            if let pngImageData = UIImagePNGRepresentation(selectedImage) {
                try pngImageData.write(to: absFilePath, options: .atomic)
                print("Wrote image to file path")
            }
        }
        catch{
            print("Couldn't write image")
        }
        self.filePath = relFilePath
        photoImageView.image = selectedImage
        print("Dismissing image picker")
        is_presenting_picker = false
        picker.dismiss(animated: true, completion: nil)
    }
    
    //MARK: Actions
    
    @IBAction func selectImageFromPhotoLibrary(_ sender: UITapGestureRecognizer) {
        self.nameTextField.resignFirstResponder()
        let imagePickerController = UIImagePickerController()
        imagePickerController.sourceType = .photoLibrary
        imagePickerController.delegate = self
        print("mealId before picker: \(String(describing: MealViewController.mealId))")
        is_presenting_picker = true
        present(imagePickerController, animated: true, completion: nil)
    }
    
    
    
}
