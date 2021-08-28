//
//  YZMTKImageView.swift
//  YZVideoFilterDemo
//
//  Created by Lester‘s Mac on 2021/8/28.
//

import UIKit
import MetalKit

class YZMTKImageView: UIView, MTKViewDelegate {

    private var imageContext: CIContext!
    var renderImage: CIImage? {
        didSet {
            mtkView.display(layer)
        }
    }
    
    private var mtkView: MTKView!
    private var device = MTLCreateSystemDefaultDevice()!
    private var commandQueue: MTLCommandQueue!

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        mtkView = MTKView.init(frame: .zero, device: device)
        mtkView.delegate = self
        mtkView.framebufferOnly = false
        addSubview(mtkView)
        commandQueue = device.makeCommandQueue()!
        
        imageContext = CIContext.init(mtlDevice: mtkView.device!, options: [.priorityRequestLow: NSNumber(booleanLiteral: true)])
        
        mtkView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {

    }
    
    func draw(in view: MTKView) {
        guard let renderImage = renderImage,
              let buffer = commandQueue.makeCommandBuffer(),
              let drawable = mtkView.currentDrawable else {
            return
        }
        
        imageContext.render(renderImage, to: drawable.texture, commandBuffer: buffer, bounds: renderImage.extent, colorSpace: CGColorSpaceCreateDeviceRGB())
        buffer.present(drawable)
        buffer.commit()
    }
    
}
