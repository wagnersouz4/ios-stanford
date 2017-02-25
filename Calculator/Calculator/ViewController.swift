//
//  ViewController.swift
//  Calculator
//
//  Created by @wagnersouz4 on 22/02/17.
//  Copyright © 2017 Wagner Souza. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    // Label corresponding the calculator's display
    @IBOutlet weak var displayLabel: UILabel!
  
    // Label containing the sequence of operands and operations
    @IBOutlet weak var descriptionLabel: UILabel!
    
    // Property of type NumberFormatter to auxiliate the restriction of 6 decimal digits at maximum
    private var numberFormat = NumberFormatter()
    
    // Property to control when the user is the middle of a typing
    private var userIsInTheMiddleOfTyping = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Setting the number of digits after a decimal point.
        numberFormat.maximumFractionDigits = 6
        numberFormat.minimumIntegerDigits = 1
    }
    
    // Computed property to get and set the display's label as a double value
    private var displayValue: Double? {
        get {
            // In order to return, the display's label should be a value convertible to Double.
            // This property is optional as Double(" ") is nil, and " " is the initial display's value
            if let currentDisplayText = displayLabel.text, let value = Double(currentDisplayText) {
                return value
            }
            return nil
        }
        set {
            // If the new value is nil the display label will be set to " ", its initial value
            if let value = newValue {
                // If a number is <= 0.0000001 (6 times 0s) it will be 0, according to the rule of 6 decimal digits at maximum
                displayLabel.text = numberFormat.string(from: NSNumber(value: value))
            } else {
                displayLabel.text = " "
            }
        }
    }
    
    // Calculator's instance to be used in this view
    private var calculator = Calculator()
    
    // Update the display when a number (0-9) is clicked in the calculator's keyboard
    @IBAction func touchDigit(_ sender: UIButton) {
        // Make sure the digit pressed has a title
        guard let digit = sender.currentTitle else { return }
        
        // If the user is still typing and there is a value in the display, the digit will be appended to the previous one
        if userIsInTheMiddleOfTyping, let currentDisplayText = displayLabel.text {
            // The dot symbol will only be added into the number if there was no previous one
            if (digit == "." && !currentDisplayText.contains(".")) || digit != "." {
                displayLabel.text = currentDisplayText + digit
            }
        } else {
            displayLabel.text = digit
        }
        
        userIsInTheMiddleOfTyping = true
    }
    
    // Action that will perform the operations in the calculator
    @IBAction func performOperation(_ sender: UIButton) {
        if userIsInTheMiddleOfTyping, let value = displayValue {
            calculator.setOperand(value)
            userIsInTheMiddleOfTyping = false
        }
        
        if let mathematicalSymbol = sender.currentTitle {
            calculator.performOperation(mathematicalSymbol)
        }
        
        
        if let accumulator = calculator.result.accumulator, let description = calculator.result.description {
            displayValue = accumulator
            if !userIsInTheMiddleOfTyping {
                descriptionLabel.text = (calculator.resultIsPending) ? description + "..." : description + " = "
            }
        }
    }
    
    // Calculator's feature to erase typed digits
    @IBAction func erase() {
        if let labelText = displayLabel.text, labelText != " " {
            // supressing the last element returned by the method popLast
            _ = displayLabel.text!.characters.popLast()
            
            if displayLabel.text?.characters.count == 0 {
                displayValue = nil
                userIsInTheMiddleOfTyping = false
            }
        }
    }
    
    // Action to clean/reset the calculator
    @IBAction func clean() {
        calculator.clean()
        displayValue = nil
        descriptionLabel.text = " "
        userIsInTheMiddleOfTyping = false
    }
}

