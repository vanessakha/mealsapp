//
//  RatingControl.swift
//  FoodTracker2Tests
//
//  Created by Vanessa on 6/29/18.
//  Copyright © 2018 BESTFOODS Inc. All rights reserved.
//

import UIKit

@IBDesignable class RatingControl: UIStackView{
    
    //MARK: Properties
    private var ratingButtons = [UIButton]()
    var rating = 0{
        didSet{
            updateButtonSelectionStates()
        }
    }
    @IBInspectable var starSize: CGSize = CGSize(width: 44.0, height: 44.0){
        didSet{ // property observer
            setUpButtons()
        }
    }
    @IBInspectable var starCount: Int = 5{
        didSet{
            setUpButtons()
        }
    }
    
    // MARK: Iniitalization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpButtons()
    }
    
    required init(coder: NSCoder){
        super.init(coder: coder)
        setUpButtons()
    }
    
    //MARK: Button action
    
    @objc func ratingButtonTapped(button: UIButton){
        guard let index = ratingButtons.index(of: button) else{
            fatalError("The button, \(button), is not in the ratingButtons array: \(ratingButtons).")
            }
        
        let selectedRating = index + 1
        
        if selectedRating == rating{
            rating = 0
        }
        else{
            rating = selectedRating
        }
    }
    
    //MARK: Private methods
    private func setUpButtons(){
        for button in ratingButtons{
            removeArrangedSubview(button)
            button.removeFromSuperview()
        }
        ratingButtons.removeAll()
        
        let bundle = Bundle(for: type(of: self))
        let filledCarrot = UIImage(named: "colorCarrot", in: bundle, compatibleWith: self.traitCollection)
        let emptyCarrot = UIImage(named: "emptyCarrot", in: bundle, compatibleWith: self.traitCollection)
        let highlightedCarrot = UIImage(named: "lightCarrot", in: bundle, compatibleWith: self.traitCollection)
        
        for index in 0..<starCount {
            let button = UIButton()
            
            button.setImage(emptyCarrot, for: .normal)
            button.setImage(filledCarrot, for: .selected)
            button.setImage(highlightedCarrot, for: .highlighted)
            button.setImage(highlightedCarrot, for: [.highlighted, .selected])
            
            button.translatesAutoresizingMaskIntoConstraints = false
            button.heightAnchor.constraint(equalToConstant: starSize.height).isActive = true
            button.widthAnchor.constraint(equalToConstant: starSize.width).isActive = true

            button.accessibilityLabel = "Set \(index + 1) star rating."
            
            button.addTarget(self, action: #selector(RatingControl.ratingButtonTapped(button:)), for: .touchUpInside)
            
            addArrangedSubview(button)
            ratingButtons.append(button)
        }
        updateButtonSelectionStates()
    }
    
    private func updateButtonSelectionStates(){
        for (index, button) in ratingButtons.enumerated(){
            button.isSelected = index < rating
            let hintString: String?
            if rating == index + 1{
                hintString = "Tap to reset the rating to zero."
            }
            else{
                hintString = nil
            }
            
            let valueString: String
            switch (rating) {
            case 0:
                valueString = "No rating set."
            case 1:
                valueString = "1 star set."
            default:
                valueString = "\(rating) stars set."
        }
        button.accessibilityHint = hintString
        button.accessibilityValue = valueString
        }
    }
}
