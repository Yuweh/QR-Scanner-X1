//
//  QRScannerViewController.swift
//  QR Scanner
//
//  Created by Jay Bergonia on 9/2/22.
//

import Foundation
import UIKit
import AVFoundation
import CameraBackground

class QRScannerViewController: UIViewController {
    
    @IBOutlet weak var takeQRViewContainer: UIView!
    @IBOutlet weak var scannerView: QRScannerView! {
        didSet {
            //scannerView.delegate = self
        }
    }
    @IBOutlet weak var scanButton: UIButton! {
        didSet {
            scanButton.setTitle("STOP", for: .normal)
        }
    }
    
    var useQRScanner = false
    var imageData: Data?
    
    var qrData: QRData? = nil {
        didSet {
            if qrData != nil {
                self.performSegue(withIdentifier: "detailSeuge", sender: self)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard AVCaptureDevice.authorizationStatus(for: .video) == .authorized else {
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { [weak self] (granted: Bool) in
                guard let weakSelf = self else { return }
                guard granted == true else {
                    DispatchQueue.main.async {
                        weakSelf.presentAlert(withTitle: "Error", message: "Application needs to have access to camera to take your selfie")
                    }
                    
                    return
                }
                
                weakSelf.addCameraBackground()
                
            })
            return
        }
        
        self.addCameraBackground()
        
    }
    
 
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if useQRScanner {
            if !scannerView.isRunning {
                //scannerView.startScanning()
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if useQRScanner {
            if !scannerView.isRunning {
                //scannerView.stopScanning()
            }
        }
    }

    @IBAction func scanButtonAction(_ sender: UIButton) {
        
        if useQRScanner {
            scannerView.isRunning ? scannerView.stopScanning() : scannerView.startScanning()
            let buttonTitle = scannerView.isRunning ? "STOP" : "SCAN"
            sender.setTitle(buttonTitle, for: .normal)
        } else {
            self.takeQRViewContainer.takeCameraSnapshot({
                  // animate snapshot capture
                  self.view.alpha = 0
                UIView.animate(withDuration: 0.5) { self.view.alpha = 1 }
            }, completion: { [weak self] (capturedImage, error) -> Void in
                guard let weakSelf = self else { return }
                weakSelf.takeQRViewContainer.freeCameraSnapshot() // unfreeze image
                
                guard error == nil else {
                    self?.presentAlert(withTitle: "Error", message: "Scanning Failed. Please try again")
                    return
                }

                weakSelf.imageData = capturedImage!.fixedOrientation().jpeg(.medium)
                weakSelf.processImageData(uplopadedImage: (capturedImage!.fixedOrientation()))
            })
        }
        
    }
}


extension QRScannerViewController: QRScannerViewDelegate {
    func qrScanningDidStop() {
        let buttonTitle = scannerView.isRunning ? "STOP" : "SCAN"
        scanButton.setTitle(buttonTitle, for: .normal)
    }
    
    func qrScanningDidFail() {
        presentAlert(withTitle: "Error", message: "Scanning Failed. Please try again")
    }
    
    func qrScanningSucceededWithCode(_ str: String?) {
        self.qrData = QRData(codeString: str)
    }
    
}


extension QRScannerViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "detailSeuge", let viewController = segue.destination as? DetailViewController {
            viewController.qrData = self.qrData
        }
    }
}

extension QRScannerViewController {
    
    private func addCameraBackground() {
        DispatchQueue.main.async {
            self.takeQRViewContainer.addCameraBackground(.back, showButtons: false, buttonMargins: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0), buttonsLocation: .top)
        }
    }
    
    private func processImageData(uplopadedImage: UIImage) {
        let detector:CIDetector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy:CIDetectorAccuracyHigh])!
        let ciImage:CIImage = CIImage(image:uplopadedImage)!
        var qrCodeLink=""

        let features=detector.features(in: ciImage)
        for feature in features as! [CIQRCodeFeature] {
            
            if let qrData = feature.messageString {
                qrCodeLink += qrData
            } else {
                qrCodeLink = ""
            }
        }
        
        if qrCodeLink == "" {
            print("nothing")
            presentAlert(withTitle: "Error", message: "Scanning Failed. QR Data is nil")
        }else{
            print("message: \(qrCodeLink)")
            presentAlert(withTitle: "Success", message: "Scanned Data: \(qrCodeLink)")
        }
    }
    
}
