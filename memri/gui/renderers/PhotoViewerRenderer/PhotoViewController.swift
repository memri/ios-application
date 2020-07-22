//
//  PhotoViewerPhotoController.swift
//  MemriPlayground
//
//  Created by Toby Brennan on 4/7/20.
//  Copyright © 2020 Memri. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI


struct PhotoViewerView: UIViewControllerRepresentable {
	var photoItemProvider: (Int) -> PhotoViewerController.PhotoItem?
	var initialIndex: Int
	
	func makeUIViewController(context: Context) -> PhotoViewerController {
		let vc = PhotoViewerController()
		vc.initialIndex = initialIndex
		vc.photoItemProvider = photoItemProvider
		return vc
	}
	
	func updateUIViewController(_ photosController: PhotoViewerController, context: Context) {
		photosController.photoItemProvider = photoItemProvider
	}
}


class PhotoViewerController: UIViewController {
	struct PhotoItem {
		var index: Int
		var imageURL: URL
		var overlay: AnyView
	}
	
	var initialIndex: Int = 0
	var photoItemProvider: (Int) -> PhotoViewerController.PhotoItem? = { _ in nil }
    
    let pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: [.interPageSpacing: 5])
    let overlayViewController = UIHostingController<AnyView>(rootView: AnyView(EmptyView()))
    
    lazy var tapGestureRecogniser = UITapGestureRecognizer(target: self, action: #selector(onTapGesture))
    lazy var doubleTapGestureRecogniser: UITapGestureRecognizer = {
        let recog = UITapGestureRecognizer(target: self, action: #selector(onDoubleTapGesture))
        recog.numberOfTapsRequired = 2
        return recog
    }()
    
    var backgroundColor: UIColor {
        _overlayVisible ? .systemBackground : .black
    }
    
    var _overlayVisible: Bool = true
    func toggleOverlayVisibleAnimated(animated: Bool) {
        _overlayVisible.toggle()
        if animated {
            if _overlayVisible { overlayViewController.view.isHidden = false }
            UIView.animate(withDuration: 0.2, animations: {
                self.pageViewController.view.backgroundColor = self.backgroundColor
                self.overlayViewController.view.alpha = self._overlayVisible ? 1 : 0
            }) { _ in
                if !self._overlayVisible { self.overlayViewController.view.isHidden = true }
            }
        } else {
            self.pageViewController.view.backgroundColor = self.backgroundColor
            overlayViewController.view.alpha = _overlayVisible ? 1 : 0
            self.overlayViewController.view.isHidden = !_overlayVisible
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        pageViewController.willMove(toParent: self)
        view.addSubview(pageViewController.view)
        addChild(pageViewController)
        overlayViewController.view.backgroundColor = .clear
        overlayViewController.willMove(toParent: self)
        view.addSubview(overlayViewController.view)
        addChild(overlayViewController)
        
        view.addGestureRecognizer(tapGestureRecogniser)
        view.addGestureRecognizer(doubleTapGestureRecogniser)
        tapGestureRecogniser.require(toFail: doubleTapGestureRecogniser)
        
        pageViewController.view.backgroundColor = self.backgroundColor
        pageViewController.delegate = self
        pageViewController.dataSource = self
        setInitialController()
    }
    
    func setInitialController() {
		guard let item = photoItemProvider(initialIndex) else {
			return
		}
		let initialController = photoViewController(forPhotoItem: item)
		pageViewController.setViewControllers([initialController], direction: .forward, animated: false, completion: nil)
		updateOverlay(forPhotoItem: item)
    }
    
	func updateOverlay(forPhotoItem photoItem: PhotoItem?) {
		if let photoItem = photoItem {
			overlayViewController.rootView = photoItem.overlay
		} else {
			overlayViewController.rootView = EmptyView().eraseToAnyView()
		}
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        let preferredOverlaySize = overlayViewController.sizeThatFits(in: CGSize(width: view.bounds.width, height: UIView.noIntrinsicMetric))
        pageViewController.view.frame = view.bounds
        overlayViewController.view.frame = CGRect(x: 0, y: view.bounds.height - preferredOverlaySize.height,
                                                  width: view.bounds.width, height: preferredOverlaySize.height)
    }
    
    @objc func onTapGesture() {
        toggleOverlayVisibleAnimated(animated: true)
    }
    
    @objc func onDoubleTapGesture() {
        (pageViewController.viewControllers?.first as? PhotoViewerPhotoController)?.toggleZoom()
    }
    
    func photoViewController(forPhotoItem photoItem: PhotoItem) -> PhotoViewerPhotoController {
        let controller = PhotoViewerPhotoController(photoItem: photoItem)
        return controller
    }
}

extension PhotoViewerController: UIPageViewControllerDelegate, UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
		guard let oldIndex = (viewController as? PhotoViewerPhotoController)?.photoItem.index,
			  let newItem = photoItemProvider(oldIndex - 1)
		else { return nil }
		return PhotoViewerPhotoController(photoItem: newItem)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
		guard let oldIndex = (viewController as? PhotoViewerPhotoController)?.photoItem.index,
			  let newItem = photoItemProvider(oldIndex + 1)
		else { return nil }
		return PhotoViewerPhotoController(photoItem: newItem)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
		guard let currentItem = (pageViewController.viewControllers?.last as? PhotoViewerPhotoController)?.photoItem else { return }
		updateOverlay(forPhotoItem: currentItem)
    }
}

class PhotoViewerPhotoController: UIViewController {
	init(photoItem: PhotoViewerController.PhotoItem) {
        self.photoItem = photoItem
        super.init(nibName: nil, bundle: nil)
        
        onSetPhotoItem()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
	var photoItem: PhotoViewerController.PhotoItem {
        didSet {
			if photoItem.imageURL != oldValue.imageURL {
                onSetPhotoItem()
            }
        }
    }
    
    private func onSetPhotoItem() {
        scalingImageView.setImageURL(photoItem.imageURL)
    }
    
    let scalingImageView = PhotoScalingView()
    
    func toggleZoom() {
        scalingImageView.toggleZoom()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(scalingImageView)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        scalingImageView.frame = view.bounds
    }
}



class PhotoScalingView: UIScrollView {
    private let imageView = UIImageView()
    
    var image: UIImage? {
        get { imageView.image }
        set {
            if imageView.image != newValue {
                imageView.image = newValue
                prepareForContents()
            }
        }
    }
    
    func setImageURL(_ url: URL?) {
        self.image = url.flatMap { UIImage(contentsOfFile: $0.path) }
        self.prepareForContents()
    }
    
    init() {
        super.init(frame: .zero)
        addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: contentLayoutGuide.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentLayoutGuide.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: contentLayoutGuide.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentLayoutGuide.bottomAnchor)
        ])
        imageView.contentMode = .center
        panGestureRecognizer.isEnabled = false
        
        delegate = self
        
        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false
        bouncesZoom = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateGestureEnabledState() {
        panGestureRecognizer.isEnabled = zoomScale > minimumZoomScale
    }
    
    func toggleZoom() {
        UIView.animate(withDuration: 0.2) {
            if self.zoomScale > self.minimumZoomScale {
                self.zoomScale = self.minimumZoomScale
            } else {
                self.zoomScale = self.maximumZoomScale
            }
        }
    }
    
    override var frame: CGRect {
        didSet {
            if frame != oldValue {
                prepareForContents()
            }
        }
    }
	
	var hasSetInitialZoomScale: Bool = false
    
    func prepareForContents() {
		if let image = imageView.image, image.size.width > 0, image.size.height > 0 {
            // Set contentSize
			if contentSize != image.size {
				self.contentSize = image.size
			}
            
            // Set scale limits
            let scaleWidth = frame.width / image.size.width
            let scaleHeight = frame.height / image.size.height
            let minZoom = min(scaleWidth, scaleHeight)
            let maxZoom = max(minZoom * 2, 1.5)
            minimumZoomScale = minZoom
            maximumZoomScale = maxZoom
			zoomScale = min(hasSetInitialZoomScale ? max(zoomScale, minZoom) : minZoom, maxZoom)
			hasSetInitialZoomScale = true
            setNeedsLayout()
        } else {
            self.contentSize = frame.size
            self.contentInset = .zero
            minimumZoomScale = 1
            maximumZoomScale = 1
        }
    }
    
    func centerContent() {
        // Set insets
        let horizontalInset = max(0, (self.frame.width - self.contentSize.width) / 2)
        let verticalInset = max(0, (self.frame.height - self.contentSize.height) / 2)
        self.contentInset = UIEdgeInsets(top: verticalInset, left: horizontalInset, bottom: verticalInset, right: horizontalInset)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        centerContent()
    }
}

extension PhotoScalingView: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        imageView
    }
    
    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        panGestureRecognizer.isEnabled = true
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        updateGestureEnabledState()
    }
}
