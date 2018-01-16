//
//  GameViewController.swift
//  Hopper
//
//  Created by Dalina Dao on 1/13/18.
//  Copyright © 2018 Team Uno. All rights reserved.
//

import UIKit
import QuartzCore
import SceneKit
import CoreMotion

class GameViewController: UIViewController {
    
    var motionManager = CMMotionManager()
    let opQueue = OperationQueue()
    
    var gameView: SCNView!
    var gameScene: SCNScene!
    var cameraNode: SCNNode!
    
    var player: SCNNode!
    var landingPlatform: SCNNode!
    var nextPlatform: SCNNode!
    var feedbackMessage: SCNNode!
    
    var childNodeIdx = 4
    var nextPlatIndex = 4
    var gameScore = 0
    var startPitch: Double!
    
    var checkInProgress: Bool = false
    let colors = [UIColor.red, UIColor.orange,UIColor.yellow, UIColor.green, UIColor.cyan, UIColor.blue, UIColor.purple, UIColor.magenta, UIColor.gray, UIColor.darkGray]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        startGame()
    }
    
    
    func startGame(){
        if motionManager.isDeviceMotionAvailable {
            print("We can detect device motion")
            startReadingMotionData()
        }
        else {
            print("We cannot detect device motion")
        }
        
        initView()
        initScene()
        initCamera()
        self.player = createPlayer()
        
        self.feedbackMessage = createFeedback()
        
        self.landingPlatform = createPlatform()
        player.position.z = landingPlatform.position.z
        self.landingPlatform.name = "landing"
        
        self.nextPlatform = createPlatform()
        self.nextPlatform.position.z = -20
    }
    
    func initView(){
        gameView = self.view as! SCNView
        gameView.backgroundColor = UIColor.lightGray
        gameView.autoenablesDefaultLighting = true
    }
    
    func initScene(){
        gameScene = SCNScene()
        gameView.scene = gameScene
        gameView.isPlaying = true
    }
    
    func initCamera(){
        cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.usesOrthographicProjection = true
        cameraNode.camera?.orthographicScale = 9
        cameraNode.camera?.zNear = -200
        cameraNode.camera?.zFar = 1500
        
        cameraNode.position = SCNVector3(x:0, y: 20, z:20)
        
        let cameraOrbit = SCNNode()
        cameraOrbit.addChildNode(cameraNode)
        
        gameScene.rootNode.addChildNode(cameraOrbit)
        
        cameraOrbit.eulerAngles.x -= .pi/4 * 1.5
        cameraOrbit.eulerAngles.y -= .pi/4 * 8
    }
    
    func startReadingMotionData() {
        // set read speed
        motionManager.deviceMotionUpdateInterval = 1/25
        
        var check = false
        // start reading
        motionManager.startDeviceMotionUpdates(to: opQueue) {
            (data: CMDeviceMotion?, error: Error?) in
            
            if let mydata = data {
                if mydata.userAcceleration.z < 0.55 && check == false {
                    self.startPitch = self.degrees(mydata.attitude.pitch)
                    check = true
                }
                else if mydata.userAcceleration.z > 0.55 && check == true{
                    let motionPitch = self.degrees(mydata.attitude.pitch)
                    
                    if motionPitch - self.startPitch > 10 {
                        let delta = motionPitch - self.startPitch
                        self.playerJumped(delta)
                        check = false
                    }
                }
            }
        }
    }

    func degrees(_ radians: Double) -> Double {
        return 180/Double.pi * radians
    }
    
    func createPlayer() -> SCNNode {
        let newPlayer:SCNGeometry  = SCNSphere(radius: 0.5)
        newPlayer.materials.first?.diffuse.contents = UIColor.white
        
        let playerNode = SCNNode(geometry: newPlayer)
        playerNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        playerNode.position = SCNVector3(x:0, y:2.5, z:0)
        gameScene.rootNode.addChildNode(playerNode)
        
        return playerNode
    }
    
    func createPlatform() -> SCNNode{
        let platform:SCNGeometry = SCNBox(width:2, height:2, length:2, chamferRadius:0.25)
        let randomNum = arc4random_uniform(10)
        let platformColor = colors[Int(randomNum)]
        platform.materials.first?.diffuse.contents = platformColor
        
        let platformNode = SCNNode(geometry: platform)
        platformNode.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
        platformNode.position = SCNVector3(x:0, y:0, z:-15)
        gameScene.rootNode.addChildNode(platformNode)
        
        return platformNode
    }
    
    func createFeedback() ->SCNNode {
        let feedback: SCNText = SCNText()
        feedback.string = "You missed"
        feedback.font = UIFont(name: "Arial", size: 1)
        feedback.materials.first?.diffuse.contents = UIColor.black
        
        let feedbackNode = SCNNode(geometry: feedback)
        feedbackNode.position = SCNVector3Make( -2.25, 0, -17)
        feedbackNode.isHidden = true
        gameScene.rootNode.addChildNode(feedbackNode)
        return feedbackNode
    }
    
    func playerStatus (_ typeofJump: String) -> SCNNode {
        if typeofJump == "short" {
            let temp = player.position
            self.player.position.z =  self.nextPlatform.position.z + 2

            self.feedbackMessage.isHidden = false
            
            let newPlayer = createPlayer()
            childNodeIdx += 1
            print("childNodeIdx: ", childNodeIdx)
            newPlayer.position = temp
            self.player = newPlayer
        }
        else if typeofJump == "perfect" {
            self.feedbackMessage.isHidden = true
            print("landedPlatform Index: ", nextPlatIndex)
            let landedPlatform = gameScene.rootNode.childNodes[nextPlatIndex]
            print("landedPlatform node: ",landedPlatform)
            
            self.player.position.z = landedPlatform.position.z
            let newPlatform = createPlatform()
            childNodeIdx += 1
            nextPlatIndex = childNodeIdx
            print("updated nextPlatIndex: ",nextPlatIndex)
            
            newPlatform.position = SCNVector3(x:0, y:0, z: landedPlatform.position.z - 5.0)
            print("newPlatform node: ", newPlatform)
            
            self.nextPlatform = newPlatform

            if  nextPlatIndex < 90 {
                self.cameraNode.position.y += 4.5
            }
            else if nextPlatIndex >= 90 {
                self.cameraNode.position.y += 4.60
            }
            else if nextPlatIndex >= 320 {
                self.cameraNode.position.y += 4.7
            }
            
            
            self.feedbackMessage.position.z = nextPlatform.position.z + 3
        }
        else if typeofJump == "long" {
            let temp = player.position
            self.player.position.z =  self.nextPlatform.position.z - 2
            
            self.feedbackMessage.isHidden = false
            
            let newPlayer = createPlayer()
            childNodeIdx += 1
            print("childNodeIdx: ", childNodeIdx)
            newPlayer.position = temp
            self.player = newPlayer
        }
        
        print("***********************************")
        return self.player
    }
    
    func playerJumped(_ delta: Double) {
        if checkInProgress == false {
            checkInProgress = true
            
            if delta < 15 {
                print("Too Short")
                playerStatus("short")
                checkInProgress = false
            }
                
            else if delta >= 15 && delta < 500{
                checkInProgress = false
                print("Perfect Jump from playerJumped(delta)")
                playerStatus("perfect")
            }
                
            else{
                print("Too Far")
                playerStatus("long")
                checkInProgress = false
            }
        } else {
            print("You already fell off. Stop it")
        }
    }
    
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
}

