//
//  VideoFeed.swift
//  FaceDetection
//
//  Created by Rodhan Hickey on 13/03/2016.
//  Based on https://github.com/iotize/FaceDetection
//  Copyright © 2016 Ryan Davies. All rights reserved.
//
//

import AVFoundation

protocol VideoFeedDelegate {
    func videoFeed(_ videoFeed: VideoFeed, didUpdateWithSampleBuffer sampleBuffer: CMSampleBuffer!)
}

class VideoFeed: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    // create a serial dispatch queue used for the sample buffer delegate as well as when a still image is captured
    // a serial dispatch queue must be used to guarantee that video frames will be delivered in order
    // see the header doc for setSampleBufferDelegate:queue: for more information
    let outputQueue = DispatchQueue(label: "VideoDataOutputQueue", attributes: [])

    let device: AVCaptureDevice? = {
        let devices = AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo) as! [AVCaptureDevice]
        var camera: AVCaptureDevice? = nil
        for device in devices {
            if device.position == .front {
                camera = device
            }
        }
        return camera
    }()

    var input: AVCaptureDeviceInput? = nil
    var delegate: VideoFeedDelegate? = nil

    let session: AVCaptureSession = {
        let session = AVCaptureSession()
        session.sessionPreset = AVCaptureSessionPresetHigh
        return session
    }()

    let videoDataOutput: AVCaptureVideoDataOutput = {
        let output = AVCaptureVideoDataOutput()
        output.videoSettings = [ kCVPixelBufferPixelFormatTypeKey as AnyHashable: NSNumber(value: kCMPixelFormat_32BGRA as UInt32) ]
        output.alwaysDiscardsLateVideoFrames = true
        return output
    }()

    func start() throws {
        var error: NSError! = NSError(domain: "Migrator", code: 0, userInfo: nil)
        do {
            try configure()
            session.startRunning()
            return
        } catch let error1 as NSError {
            error = error1
        }
        throw error
    }

    func stop() {
        session.stopRunning()
    }

    fileprivate func configure() throws {
        var error: NSError! = NSError(domain: "Migrator", code: 0, userInfo: nil)
        do {
            let maybeInput: AnyObject = try AVCaptureDeviceInput(device: device!)
            input = maybeInput as? AVCaptureDeviceInput
            if session.canAddInput(input) {
                session.addInput(input)
                videoDataOutput.setSampleBufferDelegate(self, queue: outputQueue);
                if session.canAddOutput(videoDataOutput) {
                    session.addOutput(videoDataOutput)
                    let connection = videoDataOutput.connection(withMediaType: AVMediaTypeVideo)
                    connection?.videoOrientation = AVCaptureVideoOrientation.portrait
                    return
                } else {
                    print("Video output error.");
                }
            } else {
                print("Video input error. Maybe unauthorised or no camera.")
            }
        } catch let error1 as NSError {
            error = error1
            print("Failed to start capturing video with error: \(error)")
        }
        throw error
    }

    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        // Update the delegate
        if delegate != nil {
            delegate!.videoFeed(self, didUpdateWithSampleBuffer: sampleBuffer)
        }
    }
}
