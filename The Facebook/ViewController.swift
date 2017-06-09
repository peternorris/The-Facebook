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
    @IBOutlet var eyeButton: UIButton!
    
    var eyeRectArray: [CGRect] = []
    
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
                
                self.eyeButton.setTitle("👁", for: .normal)
                self.eyeButton.isEnabled = true
                
                if faceBoxes.count > 0 {
                    self.drawBoxes(faceBoxes)
                } else {
                    self.noFaceLabel.textColor = .red
                    self.eyeButton.setTitle(" ", for: .normal)
                    self.eyeButton.isEnabled = false
                }
            }
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
                            //print("observation: \(observation)")
                            //print("observation boundingBox: \(String(describing: observation.boundingBox))")
                            
                            let box = observation.boundingBox
                            let faceCube = FaceCube(x: box.origin.x, y: box.origin.y, width: box.size.width, height: box.size.height)
                            faceBoxes.append(faceCube)
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
    
    @IBAction func findEyes() {
        
        self.spinner.color = .darkGray
        self.spinner.startAnimating()
        
        DispatchQueue.main.async {
            self.findEyesInImage() { (eyeRects: [CGRect]) in
                if eyeRects.count > 0 {
                    self.addEyes(eyeRects)
                    
                    self.spinner.stopAnimating()
                    self.spinner.color = .white
                }
            }
        }
    }
    
    func findEyesInImage(completionHandler: @escaping ([CGRect]) -> Void) {
        if let cgImage = self.imageView.image?.cgImage {
            let requestHandler = VNImageRequestHandler.init(cgImage: cgImage, options:[:])
            let eyesRequest = VNDetectFaceLandmarksRequest.init(completionHandler: { (request, error) in
                if (error != nil) {
                    print("error: \(String(describing: error))")
                } else {
                    if request.results?.isEmpty == false, let resultsArray = request.results {
                        for tmpObservation in resultsArray {
                            let observation = tmpObservation as! VNFaceObservation
                            
                            // Left Eye
                            let leftEyePointsCount = observation.landmarks?.leftEye?.pointCount
                            let leftEyePath = UIBezierPath.init()
                            
                            for index in 0...(leftEyePointsCount! - 1) {
                                let vectorPoint = observation.landmarks?.leftEye?.point(at: index)
                                let point = CGPoint.init(x: CGFloat((vectorPoint?.x)!), y: CGFloat((vectorPoint?.y)!))
                                if index == 0 {
                                    leftEyePath.move(to:point)
                                } else {
                                    leftEyePath.addLine(to: point)
                                }
                            }
                            
                            let leftEyeRect = leftEyePath.cgPath.boundingBoxOfPath
                            self.eyeRectArray.append(leftEyeRect)
                            
                            // Right Eye
                            let rightEyePointsCount = observation.landmarks?.rightEye?.pointCount
                            let rightEyePath = UIBezierPath.init()
                            
                            for index in 0...(rightEyePointsCount! - 1) {
                                let vectorPoint = observation.landmarks?.rightEye?.point(at: index)
                                let point = CGPoint.init(x: CGFloat((vectorPoint?.x)!), y: CGFloat((vectorPoint?.y)!))
                                if index == 0 {
                                    rightEyePath.move(to:point)
                                } else {
                                    rightEyePath.addLine(to: point)
                                }
                            }
                            
                            let rightEyeRect = rightEyePath.cgPath.boundingBoxOfPath
                            self.eyeRectArray.append(rightEyeRect)
                            
                            completionHandler(self.eyeRectArray)
                        }
                    } else {
                        print("No Eyes Detected")
                        completionHandler([])
                    }
                }
            })
            
            do {
                try requestHandler.perform([eyesRequest])
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
    
    func addEyes(_ eyeRects: [CGRect]) {
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.noFaceLabel.textColor = .white
        self.imageView.contentMode = .scaleAspectFit
        self.spinner.color = .white
        self.eyeButton.setTitle(" ", for: .normal)
        self.eyeButton.isEnabled = false
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}

