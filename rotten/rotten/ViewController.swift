//
//  ViewController.swift
//  rotten
//
//  Created by Kareem Dasilva on 6/8/16.
//  Copyright © 2016 kareem. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var names = [String]()
    var images = [UIImage]()
    var photos = [PhotoRecord]()
    let pendingOperations = PendingOperations()
    @IBOutlet var scroller: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        print("hey")
        let url:NSURL = NSURL(string: "https://api.github.com/users")!
        let urlRequest = NSMutableURLRequest(URL: url)
        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithRequest(urlRequest, completionHandler: {
            (data, response, error)-> Void in
            let httpResponse = response as! NSHTTPURLResponse
            let statusCode = httpResponse.statusCode
            
            if (statusCode == 200) {
                print("Everyone is fine, file downloaded successfully.")
                do{
                    let json = try NSJSONSerialization.JSONObjectWithData(data!, options:.AllowFragments)
                    //print(json)
                    //Iterates through Json
                    if let gitInfo = json as? [[String: AnyObject]] {
                        for info in gitInfo {
                            print(info["login"])
                            let name = info["login"] as! String
                            let profileUrl:NSURL = NSURL(string: info["avatar_url"] as! String)!
                            let photoRecord = PhotoRecord(name: name, url: profileUrl)
                            self.photos.append(photoRecord)
                            
                        }
                        self.scroller.reloadData()
                    }
                } catch{
                    print("heyl")
                }
            } else {
                print("uh oh")
            }
        })
        task.resume()
        
        // Do any additional setup after loading the view, typically from a nib.
    }
    override func viewDidAppear(animated: Bool) {


    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return photos.count
    }
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell:tomatoCell  = scroller.dequeueReusableCellWithIdentifier("cell") as!tomatoCell
        let photoDetails = photos[indexPath.row]
        cell.preview.image = photoDetails.image
        cell.texter.text = photoDetails.name
        switch (photoDetails.state){
      
            
        case .Failed:
            cell.texter.text = "Failed to load"
        case .New, .Downloaded:
            self.startOperationsForPhotoRecord(photoDetails,indexPath:indexPath)
        default:
            print("ge")
        }
        if (!scroller.dragging && !scroller.decelerating) {
            self.startOperationsForPhotoRecord(photoDetails, indexPath: indexPath)
        }
        
        return cell
    }

  
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        //1
        suspendAllOperations()
    }
    
    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        // 2
        if !decelerate {
            loadImagesForOnscreenCells()
            resumeAllOperations()
        }
    }
    
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        // 3
        loadImagesForOnscreenCells()
        resumeAllOperations()
    }
    func suspendAllOperations () {
        pendingOperations.downloadQue.suspended = true
        pendingOperations.filtrationQue.suspended = true
    }
    
    func resumeAllOperations () {
        pendingOperations.downloadQue.suspended = false
        pendingOperations.filtrationQue.suspended = false
    }
    
    func loadImagesForOnscreenCells () {
        //1
        if let pathsArray = scroller.indexPathsForVisibleRows {
            //2
            var allPendingOperations = Set(pendingOperations.downloadsInProgress.keys)
            allPendingOperations.unionInPlace(pendingOperations.filtrationsInProgress.keys)
            
            //3
            var toBeCancelled = allPendingOperations
            let visiblePaths = Set(pathsArray as! [NSIndexPath])
            toBeCancelled.subtractInPlace(visiblePaths)
            
            //4
            var toBeStarted = visiblePaths
            toBeStarted.subtractInPlace(allPendingOperations)
            
            // 5
            for indexPath in toBeCancelled {
                if let pendingDownload = pendingOperations.downloadsInProgress[indexPath] {
                    pendingDownload.cancel()
                }
                pendingOperations.downloadsInProgress.removeValueForKey(indexPath)
                if let pendingFiltration = pendingOperations.filtrationsInProgress[indexPath] {
                    pendingFiltration.cancel()
                }
                pendingOperations.filtrationsInProgress.removeValueForKey(indexPath)
            }
            
            // 6
            for indexPath in toBeStarted {
                let indexPath = indexPath as NSIndexPath
                let recordToProcess = self.photos[indexPath.row]
                startOperationsForPhotoRecord(recordToProcess, indexPath: indexPath)
            }
        }
    }

    func startOperationsForPhotoRecord(photoDetails: PhotoRecord, indexPath: NSIndexPath){
        switch (photoDetails.state) {
        case .New:
            startDownloadForRecord(photoDetails, indexPath: indexPath)
        case .Downloaded:
            startFiltrationForRecord(photoDetails, indexPath: indexPath)
        default:
            NSLog("do nothing")
        }
    }
    func startDownloadForRecord(photoDetails: PhotoRecord, indexPath: NSIndexPath){
        //1
        if let downloadOperation = pendingOperations.downloadsInProgress[indexPath] {
            return
        }
        
        
        //2
        let downloader = ImageDownloader(photoRecord: photoDetails)
        //3
        downloader.completionBlock = {
            if downloader.cancelled {
                return
            }
            dispatch_async(dispatch_get_main_queue(), {
                self.pendingOperations.downloadsInProgress.removeValueForKey(indexPath)
                self.scroller.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            })
        }
        //4
        pendingOperations.downloadsInProgress[indexPath] = downloader
        //5
        pendingOperations.downloadQue.addOperation(downloader)
    }
    
    func startFiltrationForRecord(photoDetails: PhotoRecord, indexPath: NSIndexPath){
        if let filterOperation = pendingOperations.filtrationsInProgress[indexPath]{
            return
        }
        
        let filterer = Filter(photoRecord: photoDetails)
        filterer.completionBlock = {
            if filterer.cancelled {
                return
            }
            dispatch_async(dispatch_get_main_queue(), {
                self.pendingOperations.filtrationsInProgress.removeValueForKey(indexPath)
                self.scroller.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            })
        }
        pendingOperations.filtrationsInProgress[indexPath] = filterer
        pendingOperations.filtrationQue.addOperation(filterer)
    }

}

class tomatoCell: UITableViewCell {
    @IBOutlet var preview: UIImageView!
    
    @IBOutlet var texter: UILabel!
    
    
}
