//
//  FileViewerController.swift
//  memri
//
//  Created by Toby Brennan on 1/8/20.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import SwiftUI
import QuickLook

class FileViewerItem: NSObject, QLPreviewItem {
    init(url: URL, title: String? = nil) {
        self.url = url
        self.title = title
    }
    
    var url: URL?
    var title: String?
    
    public var previewItemURL: URL? {
        url
    }
    
    public var previewItemTitle: String? { title ?? "" }
}

struct MemriFileViewController: UIViewControllerRepresentable {
    var files: [FileViewerItem]
    var initialIndex: Int?
    var navBarHiddenBinding: Binding<Bool>?
    
    func makeUIViewController(context: Context) -> MemriFileViewController_UIKit {
        let vc = MemriFileViewController_UIKit(coordinator: context.coordinator)
        vc.previewController.currentPreviewItemIndex = initialIndex ?? 0
        return vc
    }
    
    func updateUIViewController(_ uiViewController: MemriFileViewController_UIKit, context: Context) {
        context.coordinator.parent = self
        uiViewController.navBarHiddenBinding = navBarHiddenBinding
        //uiViewController.previewController.reloadData()
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    class Coordinator: NSObject, QLPreviewControllerDelegate, QLPreviewControllerDataSource {
        init(parent: MemriFileViewController) {
            self.parent = parent
        }
        
        var parent: MemriFileViewController
        
        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            parent.files.count
        }
        
        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            parent.files[index]
        }
        
        //        func previewController(_ controller: QLPreviewController, editingModeFor previewItem: QLPreviewItem) -> QLPreviewItemEditingMode {
        //            .updateContents
        //        }
    }
}

class MemriFileViewController_UIKit: UINavigationController {
    let previewController = QLPreviewController()
    
    var navBarHiddenBinding: Binding<Bool>?
    
    init(coordinator: MemriFileViewController.Coordinator) {
        super.init(nibName: nil, bundle: nil)
        previewController.delegate = coordinator
        previewController.dataSource = coordinator
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setViewControllers([previewController], animated: false)
    }
    
    override func setNavigationBarHidden(_ hidden: Bool, animated: Bool) {
        super.setNavigationBarHidden(hidden, animated: animated)
        updateNavBarBinding()
    }
    
    override var isNavigationBarHidden: Bool{
        didSet { updateNavBarBinding() }
    }
    
    func updateNavBarBinding() {
        DispatchQueue.main.async {
            self.navBarHiddenBinding?.wrappedValue = self.isNavigationBarHidden
        }
    }
}
