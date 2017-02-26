//
//  Calculator.swift
//  Calculator
//
//  Created by @wagnersouz4 on 22/02/17.
//  Copyright © 2017 Wagner Souza. All rights reserved.
//

import Foundation

// Calulator's engine
struct Calculator {
    
    // Using type alias to make the code more readable and avoid code repetition
    private typealias BinaryOperation = ((Double, Double) -> Double)
    
    // Data structure of a pending binary operation to support binary operations(+, -, *, /).
    private struct PendingBinaryOperation {
        let function: BinaryOperation
        let firstOperand: Double
        
        func perform(with secondOperand: Double) -> Double {
            return function(firstOperand, secondOperand)
        }
    }
    
    // Enum accounting for the available operations in the calculator
    private enum Operation {
        case constant(Double)
        case unary((Double) -> (Double))
        case binary(BinaryOperation)
        case equals
        case custom(() -> (Double))
    }
    
    // Dictionary containing the relationship between a mathematical symbol and its corresponding operation
    private var operations: [String: Operation] = [
        "π": Operation.constant(Double.pi),
        "e": Operation.constant(M_E),
        "eˣ": Operation.unary({ pow(M_E, $0) }),
        "10ˣ": Operation.unary({ pow(10, $0) }),
        "√": Operation.unary(sqrt),
        "tan": Operation.unary(tan),
        "cos": Operation.unary(cos),
        "sin": Operation.unary(sin),
        "㏑": Operation.unary(log),
        "㏒₁₀": Operation.unary(log10),
        "±": Operation.unary({ -$0 }),
        "+": Operation.binary({ $0 + $1 }),
        "−": Operation.binary({ $0 - $1 }),
        "÷": Operation.binary({ $0 / $1 }),
        "×": Operation.binary({ $0 * $1 }),
        "=": Operation.equals,
        "⦿": Operation.custom({ 0.1 / Double(arc4random()) }),
    ]
    
    // Calculator's accumulator
    private var accumulator: Double?
    
    // A read-only computed property to get the accumulator's value
    var result: (accumulator: Double?, description: String?) {
        return (accumulator, description)
    }
    
    // Calculator's property to auxiliate binary operations
    private var pendingBinaryOperation: PendingBinaryOperation?
    
    // Computed property to inform if there is a pending binary operation in the calculator
    var resultIsPending: Bool {
        return pendingBinaryOperation != nil
    }

    // Property to obtain the last operation performed
    private var lastPerformedOperation: Operation?
    
    // The calculator's description
    private var description = ""
    
    mutating func setOperand(_ operand: Double) {
        accumulator = operand
        
        if let lasOperation = lastPerformedOperation {
            switch lasOperation {
            case .equals, .binary:
                break
            default:
                description = String(operand)
            }
        } else {
            description = description + String(operand)
        }
    }
    
    private mutating func performPendingBinaryOperation() {
        guard let value = accumulator else { return }
        accumulator = pendingBinaryOperation?.perform(with: value)
    }
    
    mutating func performOperation(_ mathematicalSymbol: String) {
        if let operation = operations[mathematicalSymbol] {
            switch operation {
            case .constant(let value):
                accumulator = value
                description = (resultIsPending) ? description + mathematicalSymbol : mathematicalSymbol
            case .unary(let function):
                guard let value = accumulator else { return }
                
                if resultIsPending {
                    description = description + mathematicalSymbol + "(" + String(value) + ")"
                }else {
                    description = mathematicalSymbol + "(" + description + ")"
                }
                
                accumulator = function(value)
            case .binary(let function):
                guard let value = accumulator else { return }
                
                if resultIsPending {
                    description = description + String(accumulator!) + mathematicalSymbol
                    performPendingBinaryOperation()
                    if let newValue = accumulator {
                        pendingBinaryOperation = PendingBinaryOperation(function: function, firstOperand: newValue)
                    }
                } else {
                    pendingBinaryOperation = PendingBinaryOperation(function: function, firstOperand: value)
                    description = description + mathematicalSymbol
                    accumulator = nil
                }
            case .equals:
                guard let value = accumulator else { return }
                if let lastOperation = lastPerformedOperation {
                    switch lastOperation {
                    case .binary:
                        description = description + String(value)
                    default:
                        break
                    }
                }
                performPendingBinaryOperation()
                pendingBinaryOperation = nil
            case .custom(let function):
                accumulator = function()
                if let value = accumulator {
                    description = String(value)
                }
            }
            lastPerformedOperation = operation
        }
    }
    
    mutating func clean() {
        accumulator = nil
        pendingBinaryOperation = nil
        lastPerformedOperation = nil
        description = ""
    }
}
