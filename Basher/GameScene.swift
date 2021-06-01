import SpriteKit
import GameplayKit
import CoreMotion

class GameScene: SKScene, SKPhysicsContactDelegate {

    var starfield : SKEmitterNode!
    var player : SKSpriteNode!
    var scoreLabel : SKLabelNode!
    var score : Int = 0 {
        didSet {
            scoreLabel.text = "Хайкик: \(score)"
        }
    }
    var gameTimer : Timer!
    var aliens = ["ars", "boris", "voldir"]
    
    let alienCategory : UInt32 = 0x1 << 1
    let bulletCategory : UInt32 = 0x1 << 0

    let motionManager = CMMotionManager()
    var xAccelerate : CGFloat = 0
    
    override func didMove(to view: SKView) {
        starfield = SKEmitterNode(fileNamed: "back")
        starfield.position = CGPoint (x: 0, y: 1472)
        starfield.advanceSimulationTime(10)
        self.addChild(starfield)
        
        starfield.zPosition = -1
        
        player = SKSpriteNode (imageNamed: "hero")
        player.position = CGPoint (x: 0, y: -450)
        self.addChild(player)
        
        self.physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        self.physicsWorld.contactDelegate = self
        
        scoreLabel = SKLabelNode (text: "Хайкик: 0")
        scoreLabel.fontName = "AmericanTypewriter-Bold"
        scoreLabel.fontSize = 56
        scoreLabel.fontColor = UIColor.white
        scoreLabel.position = CGPoint (x: -150, y: 500)
        score = 0
        self.addChild(scoreLabel)
        
        gameTimer = Timer.scheduledTimer (timeInterval: 1, target: self, selector: #selector(addAlien), userInfo: nil, repeats: true)
        
        motionManager.accelerometerUpdateInterval = 0.2
        motionManager.startAccelerometerUpdates(to: OperationQueue.current!) { (data: CMAccelerometerData?, error: Error!) in
            if let accelerometerData = data {
                let acceleration = accelerometerData.acceleration
                self.xAccelerate = CGFloat(acceleration.x) * 0.75 + self.xAccelerate * 0.25
            }
        }
    }
    
    override func didSimulatePhysics() {
        player.position.x += xAccelerate * 70
        
        if player.position.x < -350 {
            player.position = CGPoint (x: 350, y: player.position.y)
        } else if player.position.x > 350 {
            player.position = CGPoint (x: -350, y: player.position.y)
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        var alienBody : SKPhysicsBody
        var bulletBody : SKPhysicsBody
        
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            alienBody = contact.bodyB
            bulletBody = contact.bodyA
        } else {
            alienBody = contact.bodyA
            bulletBody = contact.bodyB
        }
        
        if (alienBody.categoryBitMask & alienCategory) != 0 && (bulletBody.categoryBitMask & bulletCategory) != 0 {
            collisionElements(bulletNode: bulletBody.node as! SKSpriteNode, alienNode: alienBody.node as! SKSpriteNode)
        }
    }
    
    var zvuk = ["bereg", "kaskad", "eiei", "foto", "hleb", "jesus", "klitor", "kraft", "lezhat", "moruak", "nasuval", "obochina", "poedu", "taran", "vrot", "zhopu"]
    
    func collisionElements(bulletNode: SKSpriteNode, alienNode: SKSpriteNode) {
        let explosion = SKEmitterNode (fileNamed: "bah")
        explosion?.position = alienNode.position
        self.addChild(explosion!)
        
        let sounds = GKRandomSource.sharedRandom().arrayByShufflingObjects(in: zvuk) as! [String]
        self.run(SKAction.playSoundFileNamed(sounds[0], waitForCompletion: false))
        
        bulletNode.removeFromParent()
        alienNode.removeFromParent()
        
        self.run(SKAction.wait(forDuration: 2)) {
            explosion?.removeFromParent()
        }
        
        score += 1
    }

    @objc func addAlien () {
        aliens = GKRandomSource.sharedRandom().arrayByShufflingObjects(in: aliens) as! [String]
        
        let alien = SKSpriteNode (imageNamed: aliens[0])
        let randomPos = GKRandomDistribution (lowestValue: -350, highestValue: 350)
        let pos = CGFloat(randomPos.nextInt())
        alien.position = CGPoint (x: pos, y: 800)
        
        alien.physicsBody = SKPhysicsBody(rectangleOf: alien.size)
        alien.physicsBody?.isDynamic = true
        
        alien.physicsBody?.categoryBitMask = alienCategory
        alien.physicsBody?.contactTestBitMask = bulletCategory
        alien.physicsBody?.collisionBitMask = 0
        
        self.addChild(alien)
        
        let animDuration : TimeInterval = 6
        
        var actions = [SKAction()]
        actions.append(SKAction.move(to: CGPoint(x: pos, y: -800), duration: animDuration))
        actions.append(SKAction.removeFromParent())
        
        alien.run(SKAction.sequence(actions))
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        fireBullet()
    }
    
    func fireBullet() {
        let bullet = SKSpriteNode (imageNamed: "kick")
        bullet.position = player.position
        bullet.position.y += 5
        
        bullet.physicsBody = SKPhysicsBody(circleOfRadius: bullet.size.width / 2)
        bullet.physicsBody?.isDynamic = true
        
        bullet.physicsBody?.categoryBitMask = bulletCategory
        bullet.physicsBody?.contactTestBitMask = alienCategory
        bullet.physicsBody?.collisionBitMask = 0
        bullet.physicsBody?.usesPreciseCollisionDetection = true
        
        self.addChild(bullet)
        
        let animDuration : TimeInterval = 0.6
        var actions = [SKAction()]
        actions.append(SKAction.move(to: CGPoint(x: player.position.x, y: 800), duration: animDuration))
        actions.append(SKAction.removeFromParent())
        
        bullet.run(SKAction.sequence(actions))
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
}
