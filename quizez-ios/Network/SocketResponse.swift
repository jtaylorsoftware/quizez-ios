//
//  Responses.swift
//  quizez-ios
//
//  Created by Jeremy Taylor on 7/16/21.
//

import Foundation

/// A  response from the socket server
protocol SocketResponse {
    /// The ID of the session for the response
    var session: String { get }
    
    /// Creates a SocketResponse from a JSON Dictionary
    /// - Parameter json: Dictionary of `String: Any` pairs, where it is expected that `json` has keys for `Self.Type` properties
    init?(json: [String: Any])
}

/// Quiz session was created successfully
struct CreatedSession: SocketResponse {
    let session: String
    
    init?(json: [String : Any]) {
        guard let id = json["session"] as? String else {
            return nil
        }
        self.session = id
    }
}

/// A user has joined the session (the user might be the socket receiving the response)
struct UserJoined: SocketResponse {
    let session: String
    
    /// The name of the user joining
    let name: String
    
    init?(json: [String : Any]) {
        guard let session = json["session"] as? String,
              let name = json["name"] as? String else {
            return nil
        }
        self.session = session
        self.name = name
    }
}

/// User kicked successfully
struct KickedUser: SocketResponse {
    let session: String
    
    /// The name of the user kicked
    let name: String
    
    init?(json: [String : Any]) {
        guard let session = json["session"] as? String,
              let name = json["name"] as? String else {
            return nil
        }
        self.session = session
        self.name = name
    }
}

/// A user has manually disconnected from the session
struct UserDisconnected: SocketResponse {
    let session: String
    
    /// The name of the user disconnected
    let name: String
    
    init?(json: [String : Any]) {
        guard let session = json["session"] as? String,
              let name = json["name"] as? String else {
            return nil
        }
        self.session = session
        self.name = name
    }
}

/// The next Question being received from session
class NextQuestion: SocketResponse {
    let session: String
    
    /// Index of the Question in the quiz
    let index: Int
    
    /// The associated Question
    let question: Question
    
    required init?(json: [String : Any]) {
        guard let session = json["session"] as? String,
              let index = json["index"] as? Int,
              let question = json["question"] as? [String: Any],
              let text = question["text"] as? String,
              let timeLimit = question["timeLimit"] as? Int,
              let totalPoints = question["totalPoints"] as? Int,
              let rawBody = question["body"] as? [String: Any],
              let rawType = rawBody["type"] as? Int,
              let questionType = QuestionType(rawValue: rawType) else {
            return nil
        }
        
        self.session = session
        self.index = index
        
        var questionBody: Question.Body
        switch questionType {
        case .multipleChoice:
            guard let rawChoices = rawBody["choices"] as? [[String: Any]] else {
                return nil
            }
            guard let answer = rawBody["answer"] as? Int else {
                return nil
            }
            
            var choices: [Question.Body.Choice] = []
            for rawChoice in rawChoices {
                guard let text = rawChoice["text"] as? String,
                      let points = rawChoice["points"] as? Int
                else {
                    return nil
                }
                choices.append(.init(text: text, points: points))
            }
            
            questionBody = Question.Body.multipleChoice(choices: choices, answer: answer)
        case .fillInTheBlank:
            guard let rawAnswers = rawBody["answers"] as? [[String: Any]] else {
                return nil
            }
            
            var answers: [Question.Body.Answer] = []
            for rawAnswer in rawAnswers {
                guard let text = rawAnswer["text"] as? String,
                      let points = rawAnswer["points"] as? Int
                else {
                    return nil
                }
                answers.append(.init(text: text, points: points))
            }
            
            questionBody = Question.Body.fillInTheBlank(answers: answers)
        }
        
        self.question = Question(text: text, timeLimit: timeLimit, body: questionBody)
    }
}

/// The user has submitted their response to a question and is receiving their grade
struct QuestionResponseSubmitted : SocketResponse {
    let session: String
    
    /// The index of the question that was responded to originally
    let index: Int
    
    /// True if the user was the first to submit the correct response
    let firstCorrect: Bool
    
    /// Points earned for the answer
    let points: Int
    
    init?(json: [String : Any]) {
        guard let session = json["session"] as? String,
              let index = json["index"] as? Int,
              let firstCorrect = json["firstCorrect"] as? Bool,
              let points = json["points"] as? Int else {
            return nil
        }
        
        self.session = session
        self.index = index
        self.firstCorrect = firstCorrect
        self.points = points
    }
}

/// The session owner is receiving a graded, user-submitted response
struct QuestionResponseAdded : SocketResponse {
    /// The id of the session containing the Question
    let session: String
    
    ///The Question index
    let index: Int
    
    /// The user submitting Response
    let user: String
    
    /// The user's response value
    let response: String
    
    /// Points the user received for their response
    let points: Int
    
    /// Name of the first correct responder
    let firstCorrect: String
    
    /// The frequency of the user's response at the time of submission
    let frequency: Int
    
    /// The relative frequency of the user's response at the time of submission
    let relativeFrequency: Int
    
    init?(json: [String : Any]) {
        guard let session = json["session"] as? String,
              let index = json["index"] as? Int,
              let user = json["user"] as? String,
              let response = json["response"] as? String,
              let points = json["points"] as? Int,
              let firstCorrect = json["firstCorrect"] as? String,
              let frequency = json["frequency"] as? Int,
              let relativeFrequency = json["relativeFrequency"] as? Int else {
            return nil
        }
        
        self.session = session
        self.index = index
        self.user = user
        self.response = response
        self.points = points
        self.firstCorrect = firstCorrect
        self.frequency = frequency
        self.relativeFrequency = relativeFrequency
    }
}

/// The user is receiving confirmation of their feedback submission
struct FeedbackSubmitted : SocketResponse {
    /// The id of the session
    let session: String
    
    init?(json: [String : Any]) {
        guard let session = json["session"] as? String else {
            return nil
        }
        
        self.session = session
    }
}

/// The Session owner is receiving feedback for a Question from a user
struct FeedbackReceived : SocketResponse {
    /// The id of the session
    let session: String
    
    /// The name of the user submitting feedback
    let user: String
    
    /// The index of the question the feedback is for
    let question: Int
    
    /// The user's feedback
    let feedback: Feedback
    
    init?(json: [String : Any]) {
        guard let session = json["session"] as? String,
              let user = json["user"] as? String,
              let question = json["question"] as? Int,
              let rawFeedback = json["feedback"] as? [String: Any],
              let rawRating = rawFeedback["rating"] as? Int,
              let rating = Feedback.Rating(rawValue: rawRating),
              let message = rawFeedback["message"] as? String else {
            return nil
        }
        
        self.session = session
        self.user = user
        self.question = question
        self.feedback = Feedback(rating: rating, message: message)
    }
}

/// The session owner is receiving confirmation that their question hint sent.
struct HintSubmitted: SocketResponse {
    /// The id of the session
    let session: String
    
    init?(json: [String : Any]) {
        guard let session = json["session"] as? String else {
            return nil
        }
        self.session = session
    }
}

/// A user in a session is receiving a hint for the current question
struct HintReceived: SocketResponse {
    /// The id of the session
    let session: String
    
    /// The index of question the hint is for
    let question: Int
    
    /// The hint message
    let hint: String
    
    init?(json: [String : Any]) {
        guard let session = json["session"] as? String,
              let question = json["question"] as? Int,
              let hint = json["hint"] as? String
        else {
            return nil
        }
        
        self.session = session
        self.question = question
        self.hint = hint
    }
}
