//
//  PhotosCollectionViewController.swift
//  Astronomy
//
//  Created by Andrew R Madsen on 9/5/18.
//  Copyright © 2018 Lambda School. All rights reserved.
//

import UIKit

class PhotosCollectionViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    //Properties
    let cache = Cache<Int, Data>()
    private let photoFetchQueue = OperationQueue()
    private var operations = [Int : Operation]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        client.fetchMarsRover(named: "curiosity") { (rover, error) in
            if let error = error {
                NSLog("Error fetching info for curiosity: \(error)")
                return
            }
            
            self.roverInfo = rover
        }
    }
    
    // UICollectionViewDataSource/Delegate
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photoReferences.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: indexPath) as? ImageCollectionViewCell ?? ImageCollectionViewCell()
        
        loadImage(forCell: cell, forItemAt: indexPath)
        
        return cell
    }
    
    // Cancellation implement 
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        if photoReferences.count > 0 {
            let imageRef = photoReferences[indexPath.item]
            operations[imageRef.id]?.cancel()
            
        } else {
            for (_, operation) in operations {
                operation.cancel()
            }
        }
    }
    
    // Make collection view cells fill as much available width as possible
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let flowLayout = collectionViewLayout as! UICollectionViewFlowLayout
        var totalUsableWidth = collectionView.frame.width
        let inset = self.collectionView(collectionView, layout: collectionViewLayout, insetForSectionAt: indexPath.section)
        totalUsableWidth -= inset.left + inset.right
        
        let minWidth: CGFloat = 150.0
        let numberOfItemsInOneRow = Int(totalUsableWidth / minWidth)
        totalUsableWidth -= CGFloat(numberOfItemsInOneRow - 1) * flowLayout.minimumInteritemSpacing
        let width = totalUsableWidth / CGFloat(numberOfItemsInOneRow)
        return CGSize(width: width, height: width)
    }
    
    // Add margins to the left and right side
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 10.0, bottom: 0, right: 10.0)
    }
    
    // MARK: - Private
    
    private func loadImage(forCell cell: ImageCollectionViewCell, forItemAt indexPath: IndexPath) {
        
        let photoReference = photoReferences[indexPath.item]
        
//        let url = photoReference.imageURL.usingHTTPS!
        
        if let cachedPhoto = cache.value(key: photoReference.id) {
            cell.imageView.image = UIImage(data: cachedPhoto)
            return
        }
        
        // TODO: Implement image loading here
        let fetchOpertation = FetchPhotoOperation(roverImageReference: photoReference)
        let cacheOperation = BlockOperation {
            if let data = fetchOpertation.imageData {
                self.cache.cache(value: data, key: photoReference.id)
            }
        }
        
        let reusedOperations = BlockOperation {
            if let currentOperation = self.collectionView.indexPath(for: cell),
                currentOperation != indexPath {
                return
            }
            if let data = fetchOpertation.imageData {
                cell.imageView.image = UIImage(data: data)
            }
        }
        
        cacheOperation.addDependency(fetchOpertation)
        reusedOperations.addDependency(fetchOpertation)
        
        photoFetchQueue.addOperation(fetchOpertation)
        photoFetchQueue.addOperation(cacheOperation)
        
        OperationQueue.main.addOperation(reusedOperations)
        
        operations[photoReference.id] = fetchOpertation
    }
    
    // Properties
    
    private let client = MarsRoverClient()
    
    private var roverInfo: MarsRover? {
        didSet {
            solDescription = roverInfo?.solDescriptions[3]
        }
    }
    private var solDescription: SolDescription? {
        didSet {
            if let rover = roverInfo,
                let sol = solDescription?.sol {
                client.fetchPhotos(from: rover, onSol: sol) { (photoRefs, error) in
                    if let e = error { NSLog("Error fetching photos for \(rover.name) on sol \(sol): \(e)"); return }
                    self.photoReferences = photoRefs ?? []
                }
            }
        }
    }
    private var photoReferences = [MarsPhotoReference]() {
        didSet {
            DispatchQueue.main.async { self.collectionView?.reloadData() }
        }
    }
    
    @IBOutlet var collectionView: UICollectionView!
}
