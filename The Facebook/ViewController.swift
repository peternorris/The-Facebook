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

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIScrollViewDelegate {
    
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var button: UIButton!
    @IBOutlet var spinner: UIActivityIndicatorView!
    @IBOutlet var noFaceLabel: UILabel!
    @IBOutlet var scrollView: UIScrollView!
    
    //Status Texts
    let welcome = "Tap 'Select Image' to see the Vision API in play. 🤓"
    let working = "🤔 Working on your selected image...👓"
    let noFaceDetected = "🙁 We did not detect a face"
    let aFaceDetected = "😱 Magic! "
    let multipleFaceDetected = "😉 Multiple faces. Sneaky"
    
    
    
    var coordinatesArray: [FaceCube] = []
    var rectArray: [CGRect] = []
    var faceZoomRect: CGRect!
    
    
    @IBAction func lauchImagePicker() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let image = info[UIImagePickerControllerOriginalImage] as! UIImage
        picker.dismiss(animated: true, completion: nil)
        
        self.noFaceLabel.text = working
        
        
        self.imageView.backgroundColor = .white
        self.imageView.image = image
        
        self.spinner.color = .darkGray
        self.spinner.startAnimating()
        
        DispatchQueue.main.async {
            self.findFace() { (faceBoxes: [FaceCube]) in
                
                self.spinner.stopAnimating()
                self.spinner.color = .white
                
                /*
                if faceBoxes.count > 0 {
                    self.drawBoxes(faceBoxes)
                } else {
                    self.noFaceLabel.textColor = .red
                } */
                
                switch faceBoxes.count {
                case _ where faceBoxes.count == 0 :
                    self.noFaceLabel.text = self.noFaceDetected
                case _ where faceBoxes.count == 1 :
                    self.drawBoxes(faceBoxes)
                    self.noFaceLabel.text = self.aFaceDetected
                default :
                    self.drawBoxes(faceBoxes)
                    self.noFaceLabel.text = self.multipleFaceDetected
                    print("Sean! What did you do!!!!")
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
            let faceRequest = VNDetectFaceRectanglesRequest.init(completionHandler: { (request, error) in
                if (error != nil) {
                    print("error: \(String(describing: error))")
                } else {
                    var faceBoxes: [FaceCube] = []
                    if request.results?.isEmpty == false, let resultsArray = request.results {
                        for tmpObservation in resultsArray {
                            let observation = tmpObservation as! VNFaceObservation
                            print("observation: \(observation)")
                            print("observation boundingBox: \(String(describing: observation.boundingBox))")
                            
                            let box = observation.boundingBox
                            let faceCube = FaceCube(x: box.origin.x, y: box.origin.y, width: box.size.width, height: box.size.height)
                            faceBoxes.append(faceCube)
                            self.coordinatesArray.append(faceCube)
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
            self.rectArray.append(rectangle)
            
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
        
        navigationController?.navigationBar.prefersLargeTitles = true
        
        self.noFaceLabel.textColor = .black
        self.noFaceLabel.text = "Tap 'Select Image' to see the Vision API in play."
        self.imageView.image = UIImage(named:"Mystery-Person-Silhouette")
        self.imageView.contentMode = .scaleAspectFit
        self.spinner.color = .white
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView?{
        return self.imageView
    }
    
    @IBAction func handleDoubleTapScrollView(recognizer: UITapGestureRecognizer) {
        
        var relativePoint = recognizer.view?.convert(recognizer.location(in: recognizer.view), to: self.imageView)
        //relativePoint?.y = self.imageView.frame.size.height
           //var p = self.scrollView.convertPoint(recognizer.location(in: recognizer.view), to: self.imageView)
        for rect in self.rectArray {
            print(rect)
            
            print(recognizer.location(in: recognizer.view))
            
            
            let isPointInFrame = rect.contains(relativePoint!)
            if(isPointInFrame){
                faceZoomRect = rect
            }
            
            
            
            // 1. Extract rects from array - NSRect struct
            // 2. Check if the tapped point is in any of tha array rects
            // 3. If the condition is true - Return the right rect object, else nothing
            // 4. Get the rect and zoom in
        }
        
        if scrollView.zoomScale == 1 {
            if((faceZoomRect) != nil){
                scrollView.zoom(to: faceZoomRect, animated: true)
            }
            else{
                scrollView.zoom(to: zoomRectForScale(scale: scrollView.maximumZoomScale, center: recognizer.location(in: recognizer.view)), animated: true)
            }
            
        } else {
            scrollView.setZoomScale(1, animated: true)
            //scrollView.zoom(to: faceZoomRect, animated: true)
        }
    }
    
    func zoomRectForScale(scale: CGFloat, center: CGPoint) -> CGRect {
        var zoomRect = CGRect.zero
        zoomRect.size.height = imageView.frame.size.height / scale
        zoomRect.size.width  = imageView.frame.size.width  / scale
        let newCenter = imageView.convert(center, from: scrollView)
        zoomRect.origin.x = newCenter.x - (zoomRect.size.width / 2.0)
        zoomRect.origin.y = newCenter.y - (zoomRect.size.height / 2.0)
        return zoomRect
    }
    
}

