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
    
    // MARK: - Properties
    
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
        case memory
    }
    
    // Enum describing the Calculator's memory
    private enum Memory: CustomStringConvertible {
        case number(Double)
        case opearationSymbol(String)
        case variable(String)
        
        var description: String {
            switch self {
            case .number(let number):
                return String(number)
            case .opearationSymbol(let symbol):
                return symbol
            case .variable(let named):
                return named
            }
        }
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
        "x⁻¹": Operation.unary({ 1 / $0 }),
        "x²": Operation.unary({ pow($0, 2) }),
        "x³": Operation.unary({ pow($0, 3) }),
        "+": Operation.binary({ $0 + $1 }),
        "−": Operation.binary({ $0 - $1 }),
        "÷": Operation.binary({ $0 / $1 }),
        "×": Operation.binary({ $0 * $1 }),
        "=": Operation.equals,
        "Rand": Operation.custom({ 1 / Double(arc4random()) * 1000000 }), // closure to generate a random double precision number
    ]
    
    // A read-only computed property to get the accumulator's value
    var result: (accumulator: Double?, description: String?) {
        let (resultValue, _, _) = evaluate()
        return (resultValue, description)
    }
    
    // Calculator's property to auxiliate binary operations
    //private var pendingBinaryOperation: PendingBinaryOperation?
    
    // Computed property to inform if there is a pending binary operation in the calculator
    var resultIsPending: Bool {
        let (_, resultIsPending, _) = evaluate()
        return resultIsPending
    }
    
    // Property to obtain the symbol of the last operation performed
    private var lastSymbol: String?
    
    // The calculator's description
    private var description: String {
        let (_, _, description) = evaluate()
        return description
    }
    
    // Property to format value in the description to have at maximum 6 decimal digits
    private let numberFormat = NumberFormatter()
    
    private var operandName = ""
    
    private var memory = [Memory]()
    
    // MARK: - Methods
    
    // Method to return a format value as String, which will be used in the description
    private func formatNumberToString(_ number: Double) -> String {
        numberFormat.maximumFractionDigits = 6
        // the value .x will be printed out as 0.x
        numberFormat.minimumIntegerDigits = 1
        // if the formatting was not possible, the stringfied number is returned
        return numberFormat.string(from: NSNumber(value: number)) ?? String(number)
    }
    
    mutating func setOperand(_ operand: Double) {
        memory.append(.number(operand))
    }
    
    mutating func setOperand(variable named: String) {
        memory.append(.variable(named))
    }
    
    func evaluate(using variables: [String: Double]? = nil) -> (result: Double?, isPending: Bool, description: String) {
        
        func calculate() -> (result: Double?, isPending: Bool, description: String) {
            
            var accumulator: Double?
            var pendingOperation: PendingBinaryOperation?
            var lastOperation: Operation?
            var operationIsPending: Bool {
                return pendingOperation != nil
            }
            var description = ""
            
            // This nested function is used to control how description in build when the previous operation is binary (e.g 7+√9)
            func lastOperationIsBinary() -> Bool {
                if let operation = lastOperation {
                    switch operation {
                    case .binary:
                        return true
                    default:
                        return false
                    }
                }
                return false
            }

            func lastOperationIsUnary() -> Bool {
                if let operation = lastOperation {
                    switch operation {
                    case .unary:
                        return true
                    default:
                        return false
                    }
                }
                return false
            }
            
            print(memory)
            for m in memory {
                switch m {
                case .number(let number):
                    accumulator = number
                    if lastOperationIsBinary() {
                        break
                    }
                    if operationIsPending {
                        description = description + formatNumberToString(number)
                    } else {
                        description = formatNumberToString(number)
                    }
                case .opearationSymbol(let symbol):
                    if let operation = operations[symbol] {
                        switch operation {
                        case .constant(let value):
                            accumulator = value
                            description = (operationIsPending) ? description + formatNumberToString(value) : formatNumberToString(value)
                        
                        case .unary(let function):
                            guard let value = accumulator else { break }
                            if operationIsPending {
                                description = description + symbol + "(" + formatNumberToString(value) + ")"
                            } else {
                                description = symbol + "(" + description + ")"
                            }
                            accumulator = function(accumulator!)
                        case .binary(let function):
                            guard let value = accumulator else { break }
                            if operationIsPending {
                                description = description + formatNumberToString(value) + symbol
                                accumulator = pendingOperation?.perform(with: value)
                                pendingOperation = PendingBinaryOperation(function: function, firstOperand: value)
                            } else {
                                pendingOperation = PendingBinaryOperation(function: function, firstOperand: value)
                                description.append(symbol)
                            }
                        case .equals:
                            guard let value = accumulator else { break }
                            if lastOperationIsBinary() {
                                description.append(formatNumberToString(value))
                            }
                            
                            if operationIsPending {
                                accumulator = pendingOperation?.perform(with: value)
                                pendingOperation = nil
                            }
                        case .custom(let function):
                            let value = function()
                            accumulator = value
                            if operationIsPending {
                                description.append(formatNumberToString(value))
                            } else {
                                description = formatNumberToString(value)
                            }
                        case .memory:
                            break
                        }
                        lastOperation = operation
                    }
                case .variable(let named):
                    accumulator = variables?[named] ?? 0.0
                    description = (operationIsPending) ? description + named : named
                    lastOperation = Operation.memory
                }
            }
            
            return (accumulator, operationIsPending, description)
        }

        return calculate()
    }
    
    mutating func performOperation(_ operationSymbol: String) {
        memory.append(.opearationSymbol(operationSymbol))
    }
    
    mutating func undo() {
        _ = memory.popLast()
    }
    
    mutating func clean() {
        memory = []
    }
}
