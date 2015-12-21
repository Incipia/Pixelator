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
      self.translatesAutoresizingMaskIntoConstraints = false
      superView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-0-[subview]-0-|", options: NSLayoutFormatOptions.DirectionLeadingToTrailing, metrics:nil, views:["subview":self]))
      superView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-0-[subview]-0-|", options: NSLayoutFormatOptions.DirectionLeadingToTrailing, metrics:nil, views:["subview":self]))
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
      let gpuImageView = GPUImageView()
      gpuImageView.fillMode = kGPUImageFillModePreserveAspectRatioAndFill
      gpuImageView.translatesAutoresizingMaskIntoConstraints = false
      return gpuImageView
   }()
   
   private lazy var _pixellateFilter: GPUImagePixellateFilter = {
      let pixellateFilter = GPUImagePixellateFilter()
      pixellateFilter.fractionalWidthOfAPixel = 0
      return pixellateFilter
   }()
   
   private var _gpuImagePicture = GPUImagePicture(image: UIImage(named: "wind")!)
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
   
   private func _setupGPUImagePictureWithImage(image: UIImage)
   {
      _gpuImagePicture = GPUImagePicture(image: image)
      
      _gpuImagePicture.addTarget(_pixellateFilter)
      _pixellateFilter.addTarget(_gpuImageView)
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
      let image = _images[_currentImageIndex]
      _currentImageIndex = (_currentImageIndex + 1) % _images.count
      _setupGPUImagePictureWithImage(image)
      setNeedsStatusBarAppearanceUpdate()
   }
   
   func updateDisplay()
   {
      if _shouldPixellate {
         if _pixellateFilter.fractionalWidthOfAPixel < _maxPixellateValue {
            let newValue = min(_pixellateFilter.fractionalWidthOfAPixel + _pixellateStepValue, _maxPixellateValue)
            _pixellateFilter.fractionalWidthOfAPixel = newValue
            _gpuImagePicture.processImage()
            
            if newValue == _maxPixellateValue {
               _shouldPixellate = false
               _displayLink?.invalidate()
               _animating = false
            }
         }
      }
      else {
         if _pixellateFilter.fractionalWidthOfAPixel > 0 {
            let newValue = max(_pixellateFilter.fractionalWidthOfAPixel - _pixellateStepValue, 0)
            _pixellateFilter.fractionalWidthOfAPixel = newValue
            _gpuImagePicture.processImage()
            if newValue <= 0.0004 {
               _shouldPixellate = true
               _displayLink?.invalidate()
               _animating = false
            }
         }
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