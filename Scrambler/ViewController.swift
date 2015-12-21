//
//  ViewController.swift
//  Scrambler
//
//  Created by Gregory Klein on 12/18/15.
//  Copyright © 2015 Incipia. All rights reserved.
//

import UIKit
import GPUImage

extension UIView
{
   func boundInside(superView: UIView)
   {
      translatesAutoresizingMaskIntoConstraints = false
      for formattingString in ["H:|-0-[subview]-0-|", "V:|-0-[subview]-0-|"]
      {
         let constraints = NSLayoutConstraint.constraintsWithVisualFormat(
            formattingString,
            options: .DirectionLeadingToTrailing,
            metrics: nil,
            views: ["subview" : self])
         superView.addConstraints(constraints)
      }
   }
}

class ViewController: UIViewController
{
   @IBOutlet weak private var _gpuImageViewContainer: UIView! {
      didSet {
         _gpuImageViewContainer.addSubview(_gpuImageView)
         _gpuImageView.boundInside(_gpuImageViewContainer)
      }
   }
   private lazy var _gpuImageView: GPUImageView = {
      let imageView = GPUImageView()
      imageView.fillMode = kGPUImageFillModePreserveAspectRatioAndFill
      return imageView
   }()
   private lazy var _pixellateFilter: GPUImagePixellateFilter = {
      let filter = GPUImagePixellateFilter()
      filter.fractionalWidthOfAPixel = 0
      return filter
   }()
   private var _gpuImagePicture: GPUImagePicture! {
      didSet {
         _gpuImagePicture.addTarget(_pixellateFilter)
         _pixellateFilter.addTarget(_gpuImageView)
         _gpuImagePicture.processImage()
      }
   }
   
   private var _shouldPixellate = true
   private var _animating = false
   
   private var _displayLink: CADisplayLink?
   private let _pixellateStepValue: CGFloat = 0.0008
   private let _maxPixellateValue: CGFloat = 0.08
   private var _currentImageIndex = 0
   
   private let _images = [
      UIImage(named: "cloudy")!,
      UIImage(named: "partly-cloudy-night")!,
      UIImage(named: "rain")!,
      UIImage(named: "wind")!,
      UIImage(named: "clear-day")!,
      UIImage(named: "clear-day2")!,
      UIImage(named: "clear-night")!,
      UIImage(named: "partly-cloudy-day")!,
      UIImage(named: "thunderstorm")!
   ]
   
   override func viewDidLoad()
   {
      super.viewDidLoad()
      _advanceToNextImage()
      _pixellateFilter.fractionalWidthOfAPixel = 0
   }
   
   override func viewDidAppear(animated: Bool)
   {
      super.viewDidAppear(animated)
      _gpuImagePicture.processImage()
   }
   
   override func preferredStatusBarStyle() -> UIStatusBarStyle
   {
      switch _currentImageIndex
      {
      case 2, 3, 5, 8:
         return .Default
      default:
         return .LightContent
      }
   }
   
   @IBAction private func _nextButtonPressed()
   {
      if _animating == false {
         _advanceToNextImage()
      }
   }
   
   private func _advanceToNextImage()
   {
      // This is slightly misleading.. check out didSet for _gpuImagePicture
      // to see what needs to happen for this to work
      let image = _images[_currentImageIndex]
      _gpuImagePicture = GPUImagePicture(image: image)
      
      _currentImageIndex = (_currentImageIndex + 1) % _images.count
      setNeedsStatusBarAppearanceUpdate()
   }
   
   private func _invalidateDisplayLink()
   {
      _displayLink?.invalidate()
      _animating = false
   }
   
   private func _advancePixelationAnimation()
   {
      if _pixellateFilter.fractionalWidthOfAPixel < _maxPixellateValue
      {
         let newValue = min(_pixellateFilter.fractionalWidthOfAPixel + _pixellateStepValue, _maxPixellateValue)
         _pixellateFilter.fractionalWidthOfAPixel = newValue
         _gpuImagePicture.processImage()
         
         if newValue == _maxPixellateValue {
            _shouldPixellate = false
            _invalidateDisplayLink()
         }
      }
   }
   
   private func _advanceUnpixelationAnimation()
   {
      if _pixellateFilter.fractionalWidthOfAPixel > 0
      {
         let newValue = max(_pixellateFilter.fractionalWidthOfAPixel - _pixellateStepValue, 0)
         _pixellateFilter.fractionalWidthOfAPixel = newValue
         _gpuImagePicture.processImage()
         
         // This is sort of hacky.  The docs for the pixellateFilter say "Values below one pixel width in the source image
         // are ignored", so if newValue is lower than some arbitrary threshold, we know the pixelation animation should be complete
         if newValue <= 0.0004 {
            _pixellateFilter.fractionalWidthOfAPixel = 0
            _shouldPixellate = true
            _invalidateDisplayLink()
         }
      }
   }

   func updateDisplay()
   {
      if _shouldPixellate {
         _advancePixelationAnimation()
      }
      else {
         _advanceUnpixelationAnimation()
      }
   }
   
   @IBAction private func _animateButtonPressed()
   {
      if _animating == false {
         _animating = true
         _displayLink = CADisplayLink(target: self, selector: "updateDisplay")
         _displayLink?.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
      }
   }
}