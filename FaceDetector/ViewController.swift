//
//  ViewController.swift
//  FaceDetector
//
//  Created by Hickey, Rodhan on 13/03/2016.
//  Copyright © 2016 Rodhan. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, VideoFeedDelegate {
    let videoFeed = VideoFeed()

    @IBOutlet weak var feedImageView: UIImageView!
    @IBOutlet weak var faceLabel: UILabel!
    @IBOutlet weak var instructionsLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        videoFeed.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        try! videoFeed.start()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        videoFeed.stop()
    }

    func videoFeed(_ videoFeed: VideoFeed, didUpdateWithSampleBuffer sampleBuffer: CMSampleBuffer!) {
        let detector = CIDetector(ofType: CIDetectorTypeFace, context:nil, options:[CIDetectorMinFeatureSize: 0.5])

        let image = CIImage(cvPixelBuffer: CMSampleBufferGetImageBuffer(sampleBuffer)!)
        let faceFeatures = detector?.features(in: image, options: [CIDetectorSmile: true])

        var instructions: String
        var smiley: String

        if let face = faceFeatures?.first as? CIFaceFeature {
            if face.hasSmile {
                smiley = "😀"
                instructions = ""
            } else {
                smiley = "😐"
                instructions = "Smile at me and I'll smile back at you!"
            }
        } else {
            smiley = "❓"
            instructions = "Where are you? I can't see your face!"
        }

        DispatchQueue.main.async(execute: { () -> Void in
            self.faceLabel.text = smiley
            self.instructionsLabel.text = instructions
            self.feedImageView.image = UIImage(ciImage: image)
        })
    }
}

