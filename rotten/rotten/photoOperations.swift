//
//  photoOperations.swift
//  rotten
//
//  Created by Kareem Dasilva on 6/9/16.
//  Copyright © 2016 kareem. All rights reserved.
//

import UIKit
enum PhotoState {
    case New, Downloaded, FIltered, Failed
}
class PhotoRecord {
    let name:String
    let url:NSURL
    var state = PhotoState.New
    var image = UIImage(named: "Placeholder")
    
    init(name:String, url:NSURL) {
        self.name = name
        self.url = url
    }
}
class PendingOperations {
    lazy var downloadsInProgress = [NSIndexPath:NSOperation]()
    lazy var downloadQue:NSOperationQueue = {
        var que = NSOperationQueue()
        que.name = "Download que"
        que.maxConcurrentOperationCount = 1
        return que
        
    }()
    lazy var filtrationsInProgress = [NSIndexPath:NSOperation]()
    lazy var filtrationQue:NSOperationQueue = {
       var que = NSOperationQueue()
        que.name = "Image filtration que"
        que.maxConcurrentOperationCount = 1
        return que
    }()
    
    
}
class ImageDownloader: NSOperation {
    let photoRecord:PhotoRecord
    
    init(photoRecord:PhotoRecord){
        self.photoRecord = photoRecord
    }
    override func main() {
        if self.cancelled {
            return
        }
        let imageData = NSData(contentsOfURL: self.photoRecord.url)
        
        if self.cancelled {
            return
        }
        if imageData?.length > 0 {
                //if its there
            self.photoRecord.image = UIImage(data: imageData!)!
            self.photoRecord.state = .Downloaded
            
        } else {
            self.photoRecord.state = .Failed
            self.photoRecord.image = UIImage(named: "Failed")
        }
     
        
    }
    
}
class Filter: NSOperation {
    let photoRecord:PhotoRecord
    init(photoRecord:PhotoRecord){
        self.photoRecord = photoRecord
    }
    override func main(){
        if self.cancelled {
            return
        }
        if self.photoRecord.state != .Downloaded {
            return
        }
        if let filteredImage = applySepiaFilter(self.photoRecord.image!) {
            self.photoRecord.image = filteredImage
            self.photoRecord.state = .FIltered
        }
    }
}
func applySepiaFilter(image:UIImage) -> UIImage? {
    let inputImage = CIImage(data:UIImagePNGRepresentation(image)!)
    
   
    let context = CIContext(options:nil)
    let filter = CIFilter(name:"CISepiaTone")
    filter!.setValue(inputImage, forKey: kCIInputImageKey)
    filter!.setValue(0.8, forKey: "inputIntensity")
    let outputImage = filter!.outputImage
    
   
    
    let outImage = context.createCGImage(outputImage!, fromRect: outputImage!.extent)
    let returnImage = UIImage(CGImage: outImage)
    return returnImage
}

