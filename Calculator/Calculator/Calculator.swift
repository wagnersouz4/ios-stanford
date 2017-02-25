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
        let firstOperand: Double
        let operation: BinaryOperation
        
        func perform(with secondOperand: Double) -> Double {
            return operation(firstOperand, secondOperand)
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
    private var lastOperationSymbol: String?
    
    // The calculator's description
    private var description = ""
    
    mutating func setOperand(_ operand: Double) {
        accumulator = operand
        
        // if the last operation was not a binary one, the description is reseted
        if let symbol = lastOperationSymbol, let operation = operations[symbol] {
            switch operation {
            case .binary:
                break
            default:
                description = ""
            }
        }
    }
    
    // @escaping is needed as the closure mathFunction will be called from outside the performBinaryOperation's enclosing scope
    private mutating func performBinaryOperation(withMathFunction mathFunction: @escaping BinaryOperation) {
        guard let value = accumulator else { return }
        
        if resultIsPending {
            accumulator = pendingBinaryOperation?.perform(with: value)
            if let newAccumulator = accumulator {
                pendingBinaryOperation = PendingBinaryOperation(firstOperand: newAccumulator, operation: mathFunction)
            }
        } else {
            pendingBinaryOperation = PendingBinaryOperation(firstOperand: value, operation: mathFunction)
        }
    }
    
    mutating func performOperation(_ mathematicalSymbol: String) {
        if let operation = operations[mathematicalSymbol] {
            switch operation {
            case .constant(let value):
                // if the current operation is not in the middle of another operation
                if let symbol = lastOperationSymbol, let lastOperation = operations[symbol] {
                    switch lastOperation {
                    // if the last performed operation was from binary one, the description needs to be concatenated
                    case .binary:
                        description = description + mathematicalSymbol
                    // if the las operation wasn't a binary one the current description will be discarded
                    default:
                        description =  mathematicalSymbol
                    }
                } else {
                    description = mathematicalSymbol
                }
                accumulator = value
            case .unary(let mathFunction):
                if let value = accumulator {
                    if let symbol = lastOperationSymbol, let lastOperation = operations[symbol] {
                        switch lastOperation {
                        case .binary:
                            description = description + "\(mathematicalSymbol)(\(String(value)))"
                        default:
                            description = "\(mathematicalSymbol)(\(description))"
                        }
                    } else {
                        description = "\(mathematicalSymbol)(\(String(value)))"
                    }
                    accumulator = mathFunction(value)
                }
            case .binary(let mathFunction):
                var lastOperationWasBinary = false
                if let value = accumulator {
                    if let symbol = lastOperationSymbol, let lastOperation = operations[symbol] {
                        switch lastOperation {
                        case .binary:
                            // if the user has typed 7+7+7 (without using the equals operator)
                            description = description + String(value) + mathematicalSymbol
                            lastOperationWasBinary = true
                        default:
                            break
                        }
                    }
                    // the last operation was not binary the description needs to be concatenated differently
                    if !lastOperationWasBinary {
                        description = (description != "") ? description + mathematicalSymbol : description + String(value) + mathematicalSymbol
                    }
                    performBinaryOperation(withMathFunction: mathFunction)
                }
            case .equals:
                // there must be a value in the accumulator in order to perform a pending binary operation
                guard let value = accumulator else { return }
                if resultIsPending, let symbol = lastOperationSymbol, let lastOperation = operations[symbol] {
                    switch lastOperation {
                    case .binary:
                        description = description + String(value)
                    default:
                        break
                    }
                    
                    accumulator = pendingBinaryOperation?.perform(with: value)
                    pendingBinaryOperation = nil
                }
            case .custom(let customFunction):
                let customValue = customFunction()
                accumulator = customValue
                description = String(customValue)
            }
            // saving the symbol of the last operation performed
            lastOperationSymbol = mathematicalSymbol
        }
    }
    
    mutating func clean() {
        accumulator = nil
        description = ""
        pendingBinaryOperation = nil
        lastOperationSymbol = nil
    }
}
