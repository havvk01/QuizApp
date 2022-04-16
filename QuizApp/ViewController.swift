//
//  ViewController.swift
//  QuizApp
//
//  Created by Slava Havvk on 21.02.2022.
//

import UIKit

class ViewController: UIViewController, QuizProtocol, UITableViewDelegate, UITableViewDataSource, ResultViewControllerProtocol {

    

    @IBOutlet weak var questionLabel: UILabel!
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var stackViewLeadingConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var stackViewTrailingConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var rootStackView: UIStackView!
    
    var model = QuizModel()
    var questions = [Question]()
    var currentQuestionIndex = 0
    var nunCorrect = 0
    
    var resultDialog:ResultViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize the result dialog
        resultDialog = storyboard?.instantiateViewController(withIdentifier: "ResultVC") as? ResultViewController
        
        resultDialog?.modalPresentationStyle = .overCurrentContext
        resultDialog?.delegate = self
        
        // Set self as the delegate and datasource for the tableview
        tableView.delegate = self
        tableView.dataSource = self
        
        // Dynamic row heights
        tableView.estimatedRowHeight = 100
        tableView.rowHeight = UITableView.automaticDimension
        
        // set up the model
        model.delegate = self
        model.getQuestions()
        
    }
    
    func slideInQuestion() {
        
        // Set the initital state
        stackViewLeadingConstraint.constant = 1000
        stackViewTrailingConstraint.constant = -1000
        rootStackView.alpha = 0
        view.layoutIfNeeded()
        
        // Animate it to the end state
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
            self.stackViewLeadingConstraint.constant = 0
            self.stackViewTrailingConstraint.constant = 0
            self.rootStackView.alpha = 1
            self.view.layoutIfNeeded()
        }, completion: nil)

    }
    
    func slideOutQuestion() {
        
        // Set the initital state
        stackViewLeadingConstraint.constant = 0
        stackViewTrailingConstraint.constant = 0
        rootStackView.alpha = 1
        view.layoutIfNeeded()
        
        // Animate it to the end state
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
            self.stackViewLeadingConstraint.constant = -1000
            self.stackViewTrailingConstraint.constant = 1000
            self.rootStackView.alpha = 0
            self.view.layoutIfNeeded()
        }, completion: nil)

    }
    
    func displayQuestion() {
        // Check if there are the questions and check that the currentQuestionsIndex in not out of bounds
        guard questions.count > 0 && currentQuestionIndex < questions.count else {
            return
        }
        
        // Display question text
        
        questionLabel.text = questions[currentQuestionIndex].question
        
        // Reload the answers table
        tableView.reloadData()
        
        // Animate the question in
        slideInQuestion()
    }
    
    // MARK: - QuizProtocol Methods
    
    func questionRetrieved(_ questions: [Question]) {
        print(questions[0].question)
        
        // Get a reference to the questions
        self.questions = questions
        
        
        // Check if we should restore the state, before showing question #1
        let savedIndex = StateManager.retrieveValue(key: StateManager.questionIndexKey) as? Int
        
        if savedIndex != nil && savedIndex! < self.questions.count {
            
            // Set the current question to the saved index
            currentQuestionIndex = savedIndex!
            
            // Retrieve the number correct from storage
            let savedNumCorrect = StateManager.retrieveValue(key: StateManager.numCorrectKey) as? Int
            
            if savedNumCorrect != nil {
                nunCorrect = savedNumCorrect!
            }
        }
        
        
        // Display the first question
        displayQuestion()
        
//        // Reload the tableView
//        tableView.reloadData()
    }
    
    // MARK: - UITableView Delegate Methods

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        
        // Make sure that the questions array actually contains at least a question
        guard questions.count > 0 else {
            return 0
        }
        
        // Return the number of answers for this questions
        let currentQuestion = questions[currentQuestionIndex]
        
        if currentQuestion.answers != nil {
            return currentQuestion.answers!.count
        }
        
        else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // Get a cell
        let cell = tableView.dequeueReusableCell(withIdentifier: "AnswerCell", for: indexPath)
        
        // Customize it
        let label = cell.viewWithTag(1) as? UILabel
        
        if label != nil {
            
            let question = questions[currentQuestionIndex]
            if question.answers != nil && indexPath.row < question.answers!.count {
                // TODO: Set the answer text for the label
                label!.text = question.answers![indexPath.row]
            }
            
        }
        // Return the cell
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
     
        // User has tapped on a row, check if it's the right answer
        
        var titleText = ""
        
        let question = questions[currentQuestionIndex]
        
        if question.correctAnswerIndex == indexPath.row {
            // User got it right
            print("right")
            titleText = "Correct!"
            nunCorrect += 1
        }
        
        else {
            // User got it wrong
            print("wrong")
            titleText = "Wrong!"
        }
        
        // Slide out the question
        DispatchQueue.main.async {
            self.slideOutQuestion()
        }
        
        // Show the popup
        if resultDialog != nil {
            // Customize the dialog text
            resultDialog!.titleText = titleText
            resultDialog!.feedbackText = question.feedback!
            resultDialog!.buttonText = "next"
            
            DispatchQueue.main.async {
                self.present(self.resultDialog!, animated: true, completion: nil)
            }
            
        }

        
    }
    
    func dialogDismissed() {
        
        // Increment the current QuestionIndex
        currentQuestionIndex += 1
        
        if currentQuestionIndex == questions.count {
            // The user has just answered the last queston
            
            // Show a summary dialog

            if resultDialog != nil {
                // Customize the dialog text
                resultDialog!.titleText = "Summary"
                let resultCount = Int(Double(nunCorrect) / Double(questions.count) * 100)
                resultDialog!.feedbackText = "\(resultCount)% \n\nYou got \(nunCorrect) correct out of \(questions.count) questions"
                resultDialog!.buttonText = "Restart"
                
                present(resultDialog!, animated: true, completion: nil)
                
                // Clear the state
                StateManager.clearState()
            }
        }
        
        else if currentQuestionIndex > questions.count {
            // Restart
            nunCorrect = 0
            currentQuestionIndex = 0
            displayQuestion()
        }
        else if currentQuestionIndex < questions.count {
            // We have more question to show
            
            // Diplay the next question
            displayQuestion()
            
            // Save state
            StateManager.saveState(numCorrect: nunCorrect, questionIndex: currentQuestionIndex)
            
        }
        
//        tableView.reloadData()
    }
    
}

