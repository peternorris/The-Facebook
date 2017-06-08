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
    @IBOutlet var spinner: UIActivityIndicatorView!
    @IBOutlet var noFaceLabel: UILabel!
    
    @IBAction func lauchImagePicker() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let image = info[UIImagePickerControllerOriginalImage] as! UIImage
        picker.dismiss(animated: true, completion: nil)
        
        if self.noFaceLabel.textColor == .red {
            self.noFaceLabel.textColor = .white
        }
        
        self.imageView.backgroundColor = .white
        self.imageView.image = image
        
        self.spinner.color = .darkGray
        self.spinner.startAnimating()
        
        DispatchQueue.main.async {
            self.findFace() { (faceBoxes: [FaceCube]) in
                
                self.spinner.stopAnimating()
                self.spinner.color = .white
                
                if faceBoxes.count > 0 {
                    self.drawBoxes(faceBoxes)
                } else {
                    self.noFaceLabel.textColor = .red
                }
            }
        }
    }
    
    func findFace(_ fileURL: URL, completionHandler: @escaping ([FaceCube]) -> Void) {
        let detectionRequest = VNDetectFaceRectanglesRequest()
        let requestHandler = VNImageRequestHandler(url: fileURL, options: [:])
        
        do {
            try requestHandler.perform([detectionRequest])
        } catch {
            print("error performing request")
        }
        
        var faceBoxes: [FaceCube] = []
        
        for observation in detectionRequest.results as! [VNFaceObservation] {
            print("observation: \(observation)")
            print("observation boundingBox: \(String(describing: observation.boundingBox))")
            
            let box = observation.boundingBox
            faceBoxes.append(FaceCube(x: box.origin.x, y: box.origin.y, width: box.size.width, height: box.size.height))
            
            completionHandler(faceBoxes)
        }
    }
    
    func findFace(completionHandler: @escaping ([FaceCube]) -> Void) {
        if let cgImage = self.imageView.image?.cgImage {
            let requestHandler = VNImageRequestHandler.init(cgImage: cgImage, options:[:])
            let faceRequest = VNDetectFaceRectanglesRequest.init(completionHandler: { (self, error) in
                if (error != nil) {
                    print("error: \(String(describing: error))")
                } else {
                    var faceBoxes: [FaceCube] = []
                    if self.results?.isEmpty == false, let resultsArray = self.results {
                        for tmpObservation in resultsArray {
                            let observation = tmpObservation as! VNFaceObservation
                            print("observation: \(observation)")
                            print("observation boundingBox: \(String(describing: observation.boundingBox))")
                            
                            let box = observation.boundingBox
                            faceBoxes.append(FaceCube(x: box.origin.x, y: box.origin.y, width: box.size.width, height: box.size.height))
                        }
                        completionHandler(faceBoxes)
                    } else {
                        print("No Faces Detected")
                        completionHandler([])
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
    
    func drawBoxes(_ coordinateBoxes: [FaceCube]) {
        for coordinates in coordinateBoxes {
            let image = self.imageView.image
            
            let imageSize = image?.size
            let scale: CGFloat = 0
            UIGraphicsBeginImageContextWithOptions(imageSize!, false, scale)
            
            image?.draw(at: .zero)
            
            let x = coordinates.x * (imageSize?.width)!
            let y = coordinates.y * (imageSize?.height)!
            let width = coordinates.width * (imageSize?.width)!
            let height = coordinates.height * (imageSize?.height)!
            
            let rectangle = CGRect(x: x, y: y, width: width, height: height)
            
            if let context = UIGraphicsGetCurrentContext() {
                
                context.translateBy(x: 0, y: (imageSize?.height)!)
                context.scaleBy(x: 1, y: -1)
                
                context.setFillColor(UIColor.black.cgColor)
                context.setStrokeColor(UIColor.red.cgColor)
                context.setLineWidth(5)
                context.addRect(rectangle)
                context.drawPath(using: .stroke)
            }
            
            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            self.imageView.image = newImage
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.noFaceLabel.textColor = .white
        self.imageView.contentMode = .scaleAspectFit
        self.spinner.color = .white
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

