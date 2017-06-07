//
//  ViewController.swift
//  The Facebook
//
//  Created by Peter Norris on 2017-06-06.
//  Copyright © 2017 Marketcircle. All rights reserved.
//

import UIKit
import Vision

struct FaceCube {
    var x: CGFloat
    var y: CGFloat
    var width: CGFloat
    var height: CGFloat
}

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var button: UIButton!
    
    //var boxCoordinates: FaceCube?
    
    @IBAction func lauchImagePicker() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let image = info[UIImagePickerControllerOriginalImage] as! UIImage
        picker.dismiss(animated: true, completion: nil)
        
        self.imageView.image = image
        
        //self.findFace()
        self.findFace() { (faceBox: FaceCube) in
            self.drawBox(faceBox)
        }
        //self.drawBox(self.boxCoordinates)
    }
    
    func findFace(completionHandler: @escaping (FaceCube) -> Void) {
        if let cgImage = self.imageView.image?.cgImage {
            let requestHandler = VNImageRequestHandler.init(cgImage: cgImage, options:[:])
            let faceRequest = VNDetectFaceRectanglesRequest.init(completionHandler: { (self, error) in
                if (error != nil) {
                    print("error: \(String(describing: error))")
                } else {
                    if self.results?.isEmpty == false, let resultsArray = self.results {
                        let observation = resultsArray.first as! VNFaceObservation
                        print("observation: \(observation)")
                        print("observation boundingBox: \(String(describing: observation.boundingBox))")
                        
                        let box = observation.boundingBox
                        
//                        print("*****")
//                        print("observation landmark 0 nose points: \(String(describing: observation.landmarks?.nose?.points))")
//                        print("*****")
//                        print("observation landmark 0 allPoints: \(String(describing: observation.landmarks?.allPoints))")
                        
                        //return FaceCube(x: box.origin.x, y: box.origin.y, width: box.size.width, height: box.size.height)
                        completionHandler(FaceCube(x: box.origin.x, y: box.origin.y, width: box.size.width, height: box.size.height))
                        
                    } else {
                        print("No Face Detected")
                    }
                }
            })
            
            do {
                try requestHandler.perform([faceRequest])
            } catch {
                print("error performing request")
            }
        }
    }
    
    func drawBox(_ coordinates: FaceCube?) {
        if let coordinates = coordinates {
            let image = self.imageView.image
            
            let imageSize = image?.size
            let scale: CGFloat = 0
            UIGraphicsBeginImageContextWithOptions(imageSize!, false, scale)
            
            image?.draw(at: .zero)
            
            let x = coordinates.x * (imageSize?.width)!
            let width = coordinates.width * (imageSize?.width)!
            let height = coordinates.height * (imageSize?.height)!
            let y = coordinates.y > 0 ? height - (coordinates.y * (imageSize?.height)!) : coordinates.y * (imageSize?.height)!
            
            let rectangle = CGRect(x: x, y: y, width: width, height: height)
            
            //let heightSpan = floor(height / 2 - rectangle.size.height / 2)
            //let widthSpan = floor(width / 2 - rectangle.size.width / 2)
            
            UIColor.green.setFill()
            UIRectFill(rectangle)
            
            // fill outer rect
            //UIColor(red: 0, green: 0, blue: 0, alpha: 0.5).set()
//            UIRectFill(rectangle)
            
            // fill inner border
            //UIColor(red: 1, green: 1, blue: 1, alpha: 0.5).set()
//            UIColor.clear.setFill()
//            UIRectFill(CGRect(x: x + 10, y: y + 10, width: width-20, height: height-20))
            
            // fill inner rect
            //UIColor.clear.set()
            //UIRectFill(CGRect(x: widthSpan, y: heightSpan, width: rectangle.size.width, height: rectangle.size.height))
            
            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            self.imageView.image = newImage
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

