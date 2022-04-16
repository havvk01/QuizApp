//
//  Question.swift
//  QuizApp
//
//  Created by Slava Havvk on 21.02.2022.
//

import Foundation

struct Question: Codable {
    
    var question:String
    var answers:[String]?
    var correctAnswerIndex:Int?
    var feedback:String?
    
}

