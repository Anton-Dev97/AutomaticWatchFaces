//
//  InterfaceController.swift
//  WatchFace Extension
//
//  Created by Sylvain Guillier on 27/12/2018.
//  Copyright © 2018 Sylvain Guillier. All rights reserved.
//
import WatchKit
import SpriteKit
import Foundation


class InterfaceController: WKInterfaceController,WKCrownDelegate {
    
    @IBOutlet weak var skInterface: WKInterfaceSKScene!
    
    let watchList = WatchDatabase.init().watchDatabase
    var crownAccumulator = 0.0
    
    var alternativeWatchNb = 0
    
    
    //let currentDeviceSize = WKInterfaceDevice.current().screenBounds.size
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        crownSequencer.delegate = self
        skInterface.isPaused = false
        WatchManager.actualWatch = watchList[WatchManager.actualWatchNB]
        setWatchFace()
        
    }
    
    override func didAppear() {
        hideTime()
        crownSequencer.focus()
    }
    
    func crownDidRotate(_ crownSequencer: WKCrownSequencer?, rotationalDelta: Double) {
        crownAccumulator += rotationalDelta
        if (crownAccumulator > 0.5 && WatchManager.actualWatchNB < watchList.count-1){
            WatchManager.actualWatchNB += 1
            WatchManager.actualWatch = watchList[WatchManager.actualWatchNB]
            crownAccumulator = 0.0
            setWatchFace()
            alternativeWatchNb = 0
        }
        else if (crownAccumulator < -0.5 && WatchManager.actualWatchNB > 0){
            WatchManager.actualWatchNB -= 1
            WatchManager.actualWatch = watchList[WatchManager.actualWatchNB]
            crownAccumulator = 0.0
            setWatchFace()
            alternativeWatchNb = 0
        }
        else if (crownAccumulator > 0.5 || crownAccumulator < -0.5){
            WKInterfaceDevice.current().play(.click)
        }
        
    }
    
    func crownDidBecomeIdle(_ crownSequencer: WKCrownSequencer?) {
        crownAccumulator = 0.0
    }
    
    func setWatchFace(){
        if let scene = WatchScene(fileNamed: "WatchScene"){
            scene.scaleMode = .aspectFit
            skInterface.presentScene(scene)
        }
    }
    
    
    @IBAction func tapGesture(_ sender: Any) {
        if (WatchManager.actualWatch.chronograph != nil) {
            
            if WatchManager.actualWatch.chronograph!.inWork == false{
                
                WatchManager.actualWatch.chronograph!.startChronograph()
                
            }
            else {
                WatchManager.actualWatch.chronograph!.stopChronograph()
                
            }
            
            WKInterfaceDevice.current().play(.click)
        }
    }
    
    
    
    @IBAction func longPressGesture(_ sender: Any) {
        
        WatchManager.actualWatch.chronograph!.resetChronograph()
        WKInterfaceDevice.current().play(.click)
    }
    
    
    @IBAction func swipeRightGesture(_ sender: Any) {
        if alternativeWatchNb > 0{
            if alternativeWatchNb == 1{
                WatchManager.actualWatch = WatchDatabase.init().watchDatabase[WatchManager.actualWatchNB]
                alternativeWatchNb = 0
            }
            else if (WatchManager.actualWatch.alternative.count > 0){
                alternativeWatchNb -= 1
                configureAlternativeWatch(watchList: watchList)
                
            }
            setWatchFace()
        }
    }
    
    @IBAction func swipeLeftGesture(_ sender: Any) {
        if (WatchManager.actualWatch.alternative.count > 0 && alternativeWatchNb < WatchManager.actualWatch.alternative.count){
            alternativeWatchNb += 1
            configureAlternativeWatch(watchList: watchList)
            
            setWatchFace()
        }
    }
    
    
    func configureAlternativeWatch(watchList:[Watch]){
        let alternativeWatch = watchList[WatchManager.actualWatchNB].alternative[alternativeWatchNb - 1]
        if alternativeWatch!.dial != nil{
            WatchManager.actualWatch.dial = alternativeWatch!.dial
        }
        if alternativeWatch!.secHand != nil{
            WatchManager.actualWatch.secHand = alternativeWatch!.secHand
        }
        if alternativeWatch!.hourHand != nil{
            WatchManager.actualWatch.hourHand = alternativeWatch!.hourHand
        }
        if alternativeWatch!.minHand != nil{
            WatchManager.actualWatch.minHand = alternativeWatch!.minHand
        }
        
        if alternativeWatch!.date != nil{
            WatchManager.actualWatch.date = alternativeWatch!.date
        }
    }
}

// Hack in order to disable the digital time on the screen
extension WKInterfaceController{
    func hideTime(){
        guard let cls = NSClassFromString("SPFullScreenView") else {return}
        let viewControllers = (((NSClassFromString("UIApplication")?.value(forKey:"sharedApplication") as? NSObject)?.value(forKey: "keyWindow") as? NSObject)?.value(forKey:"rootViewController") as? NSObject)?.value(forKey:"viewControllers") as? [NSObject]
        viewControllers?.forEach{
            let views = ($0.value(forKey:"view") as? NSObject)?.value(forKey:"subviews") as? [NSObject]
            views?.forEach{
                if $0.isKind(of:cls){
                    (($0.value(forKey:"timeLabel") as? NSObject)?.value(forKey:"layer") as? NSObject)?.perform(NSSelectorFromString("setOpacity:"),with:CGFloat(0))
                }
            }
        }
        
    }
    
    
}
