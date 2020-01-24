//
//  FetchPhotoOperation.swift
//  Astronomy
//
//  Created by Enayatullah Naseri on 8/1/19.
//  Copyright © 2019 Lambda School. All rights reserved.
//

import Foundation


class FetchPhotoOperation: ConcurrentOperation {
    
    // Properties
    private(set) var imageData: Data?
    private var dataTask: URLSessionDataTask?
    private let session: URLSession
    
    
    let id: Int
    let sol: Int
    let camera: Camera
    let earthDate: Date
    let imageURL: URL
    
    
    init(roverImageReference: MarsPhotoReference, session: URLSession = URLSession.shared) {
        
        self.id = roverImageReference.id
        self.sol = roverImageReference.sol
        self.camera = roverImageReference.camera
        self.earthDate = roverImageReference.earthDate
        self.imageURL = roverImageReference.imageURL
        self.session = session
        super.init()
    }
    
    
    // Start
    override func start() {
        
        super.start()
        state = .isExecuting
        
        let url = imageURL.usingHTTPS!
        
        let task = session.dataTask(with: url) { (data, response, error) in
            
            defer { self.state = .isFinished }
            if self.isCancelled { return }
            
            if let error = error {
                
                NSLog("Error fetching image: \(error)")
                return
            }
            self.imageData = data
            
        }
        task.resume()
        dataTask? = task
    }

    // cancel
    override func cancel() {
        
        super.cancel()
        dataTask?.cancel()
        
    }

}
