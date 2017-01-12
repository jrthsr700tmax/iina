//
//  PlaySlider.swift
//  iina
//
//  Created by lhc on 25/7/16.
//  Copyright © 2016年 lhc. All rights reserved.
//

import Cocoa

class PlaySliderCell: NSSliderCell {

  override var knobThickness: CGFloat {
    return knobWidth
  }

  let knobWidth: CGFloat = 3
  let knobHeight: CGFloat = 15
  let knobRadius: CGFloat = 1

  static let darkColor = NSColor(red: 1, green: 1, blue: 1, alpha: 0.5)
  static let lightColor = NSColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1)

  static let darkBarColorLeft = NSColor(white: 1, alpha: 0.3)
  static let darkBarColorRight = NSColor(white: 1, alpha: 0.1)
  static let lightBarColorLeft = NSColor(red: 0.239, green: 0.569, blue: 0.969, alpha: 1)
  static let lightBarColorRight = NSColor(white: 0.5, alpha: 0.5)

  var isInDarkTheme: Bool = true {
    didSet {
      self.knobColor = isInDarkTheme ? PlaySliderCell.darkColor : PlaySliderCell.lightColor
      self.barColorLeft = isInDarkTheme ? PlaySliderCell.darkBarColorLeft : PlaySliderCell.lightBarColorLeft
      self.barColorRight = isInDarkTheme ? PlaySliderCell.darkBarColorRight : PlaySliderCell.lightBarColorRight
    }
  }
  private var knobColor: NSColor = PlaySliderCell.darkColor
  private var barColorLeft: NSColor = PlaySliderCell.darkBarColorLeft
  private var barColorRight: NSColor = PlaySliderCell.darkBarColorRight
  private var chapterStrokeColor: NSColor = NSColor(white: 0, alpha: 0.8)

  var drawChapters = UserDefaults.standard.bool(forKey: Preference.Key.showChapterPos)

  override func awakeFromNib() {
    minValue = 0
    maxValue = 100
  }

  override func drawKnob(_ knobRect: NSRect) {
    // Round the X position for cleaner drawing
    let rect = NSMakeRect(round(knobRect.origin.x),
                          knobRect.origin.y + 0.5 * (knobRect.height - knobHeight),
                          knobRect.width,
                          knobHeight)
    let path = NSBezierPath(roundedRect: rect, xRadius: knobRadius, yRadius: knobRadius)
    knobColor.setFill()
    path.fill()
  }

  override func knobRect(flipped: Bool) -> NSRect {
    let slider = self.controlView as! NSSlider
    let bounds = super.barRect(flipped: flipped)
    let percentage = slider.doubleValue / (slider.maxValue - slider.minValue)
    let pos = CGFloat(percentage) * bounds.width
    let rect = super.knobRect(flipped: flipped)
    let flippedMultiplier = flipped ? CGFloat(-1) : CGFloat(1)
    return NSMakeRect(pos - flippedMultiplier * 0.5 * knobWidth, rect.origin.y, knobWidth, rect.height)
  }

  override func drawBar(inside rect: NSRect, flipped: Bool) {
    let info = PlayerCore.shared.info
    
    let slider = self.controlView as! NSSlider
    
    /// The position of the knob, rounded for cleaner drawing
    let knobPos : CGFloat = round(knobRect(flipped: flipped).origin.x);
    
    /// How far progressed the current video is, used for drawing the bar background
    var progress : CGFloat = 0;
    
    if info.isNetworkResource, info.cacheTime != 0, let duration = info.videoDuration {
      let pos = Double(info.cacheTime) / Double(duration.second) * 100
      progress = round(rect.width * CGFloat(pos / (slider.maxValue - slider.minValue))) + 2;
    } else {
      progress = knobPos;
    }
    
    let rect = NSMakeRect(rect.origin.x, rect.origin.y + 1, rect.width, rect.height - 2)
    let path = NSBezierPath(roundedRect: rect, xRadius: 3, yRadius: 3)

    // draw left
    let pathLeftRect : NSRect = NSMakeRect(rect.origin.x, rect.origin.y, progress, rect.height)
    NSBezierPath(rect: pathLeftRect).addClip();
    
    // Clip 1px around the knob
    path.append(NSBezierPath(rect: NSRect(x: knobPos - 1, y: rect.origin.y, width: knobWidth + 2, height: rect.height)).reversed);
    
    barColorLeft.setFill()
    path.fill()
    NSGraphicsContext.restoreGraphicsState()

    // draw right
    NSGraphicsContext.saveGraphicsState()
    let pathRight = NSMakeRect(rect.origin.x + progress, rect.origin.y, rect.width - progress, rect.height)
    NSBezierPath(rect: pathRight).setClip()
    barColorRight.setFill()
    path.fill()
    NSGraphicsContext.restoreGraphicsState()

    // draw chapters
    NSGraphicsContext.saveGraphicsState()
    if drawChapters {
      if let totalSec = info.videoDuration?.second {
        chapterStrokeColor.setStroke()
        var chapters = info.chapters
        if chapters.count > 0 {
          chapters.remove(at: 0)
          chapters.forEach { chapt in
            let chapPos = CGFloat(chapt.time.second) / CGFloat(totalSec) * rect.width
            let linePath = NSBezierPath()
            linePath.move(to: NSPoint(x: chapPos, y: rect.origin.y))
            linePath.line(to: NSPoint(x: chapPos, y: rect.origin.y + rect.height))
            linePath.stroke()
          }
        }
      }
    }
    NSGraphicsContext.restoreGraphicsState()
  }

  override func barRect(flipped: Bool) -> NSRect {
    let rect = super.barRect(flipped: flipped)
    return NSMakeRect(0, rect.origin.y, rect.width + rect.origin.x * 2, rect.height)
  }

}
