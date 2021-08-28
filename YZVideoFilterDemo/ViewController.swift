//
//  ViewController.swift
//  YZVideoFilterDemo
//
//  Created by Lester‘s Mac on 2021/8/28.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {

    private var player: AVPlayer!
    private var playLink: CADisplayLink!
    private var renderQueue = DispatchQueue(label: "com.render")
    private var videoOutPut: AVPlayerItemVideoOutput!
    
    private var blurView = YZMTKImageView()
    private var mtkImgView = YZMTKImageView()
    private var effectView: UIVisualEffectView = {
        let blur = UIBlurEffect.init(style: .light)
        let view = UIVisualEffectView(effect: blur)
        view.alpha = 0.95
        return view
    }()
    
    //亮度
    private var light: Float = 0
    //饱和度
    private var saturation: Float = 1
    //对比度
    private var contrast: Float = 1

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        guard let filePath = Bundle.main.path(forResource: "smallVideo0.mp4", ofType: nil) else {
            return
        }
        
        let url = URL(fileURLWithPath: filePath)
        let playerItem = AVPlayerItem(url: url)
        videoOutPut = AVPlayerItemVideoOutput.init()
        player = AVPlayer.init(playerItem: playerItem)
        player.currentItem?.add(videoOutPut)
        
        //视频尺寸
        guard let asset = player.currentItem?.asset,
              let track = asset.tracks.first else {
            return
        }
        let naturalSize = track.naturalSize
        var newWidth: CGFloat = 0
        var newHeight: CGFloat = 0
        if naturalSize.width > naturalSize.height {
            newWidth = UIScreen.main.bounds.width
            newHeight = newWidth * naturalSize.height / naturalSize.width
        } else if naturalSize.width < naturalSize.height {
            newHeight = UIScreen.main.bounds.width
            newWidth = newHeight * naturalSize.width / naturalSize.height
        } else {
            newWidth = UIScreen.main.bounds.width
            newHeight = newWidth
        }
        
        view.addSubview(blurView)
        blurView.addSubview(effectView)
        view.addSubview(mtkImgView)
        
        blurView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalToSuperview().offset(100)
            make.height.equalTo(UIScreen.main.bounds.width)
        }
        
        effectView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        
        mtkImgView.snp.makeConstraints { (make) in
            make.width.equalTo(newWidth)
            make.height.equalTo(newHeight)
            make.center.equalTo(blurView.snp.center)
        }
        
        //滑块
        let maxValues: [Float] = [1, 2, 4]
        let minValues: [Float] = [-1, 0, 0]
        let values: [Float] = [light, saturation, contrast]
        for i in 0..<3 {
            let slider = UISlider.init()
            slider.value = values[i]
            slider.maximumValue = maxValues[i]
            slider.minimumValue = minValues[i]
            slider.tag = i
            view.addSubview(slider)
            slider.snp.makeConstraints { (make) in
                make.left.equalToSuperview().offset(20)
                make.right.equalToSuperview().offset(-20)
                make.height.equalTo(40)
                make.top.equalTo(blurView.snp.bottom).offset(i * 50 + 20)
            }
            slider.addTarget(self, action: #selector(slidervalueChangeAction(_:)), for: .valueChanged)
        }
        
        //计时器
        playLink = CADisplayLink(target: self, selector: #selector(playerRender))
        playLink.preferredFramesPerSecond = 2
        playLink.add(to: .current, forMode: .common)
        
        NotificationCenter.default.addObserver(self, selector: #selector(playToEnd), name: .AVPlayerItemDidPlayToEndTime, object: nil)
        
        player.play()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        player.pause()
        playLink.invalidate()
    }

    @objc func playToEnd() {
        player.seek(to: CMTimeMakeWithSeconds(0, preferredTimescale: player.currentItem!.duration.timescale))
        player.play()
    }
    
    @objc func playerRender() {
        let itemTime = videoOutPut.itemTime(forHostTime: CACurrentMediaTime())
        if videoOutPut.hasNewPixelBuffer(forItemTime: itemTime) {
            renderQueue.async {
                guard let pixelBuffer = self.videoOutPut.copyPixelBuffer(forItemTime: itemTime, itemTimeForDisplay: nil) else {
                    return
                }
                let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
                let outPutImg = self.renderCIImage(ciImage)
                
                DispatchQueue.main.async {
                    self.blurView.renderImage = outPutImg
                    self.mtkImgView.renderImage = outPutImg
                }
            }
            
        } else {
            
        }
    }
    
    /// 渲染处理输出画像
    private func renderCIImage(_ ciImg: CIImage) -> CIImage {
        guard let filter = CIFilter(name: "CIColorControls") else {
            return ciImg
        }
        filter.setValue(ciImg, forKey: kCIInputImageKey)
        filter.setDefaults()
        
        //修改亮度   -1---1   数越大越亮
        filter.setValue(self.light, forKey: "inputBrightness")
        
        //修改饱和度  0---2
        filter.setValue(self.saturation, forKey: "inputSaturation")
        
        //修改对比度  0---4
        filter.setValue(self.contrast, forKey: "inputContrast")
        
        let outputImage = filter.outputImage
        return outputImage ?? ciImg
    }
    
    @objc func slidervalueChangeAction(_ sender: UISlider) {
        switch sender.tag {
        case 0:
            light = sender.value
        case 1:
            saturation = sender.value
        case 2:
            contrast = sender.value
        default:
            break
        }
    }


}

