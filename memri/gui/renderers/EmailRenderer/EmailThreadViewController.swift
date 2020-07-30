//
//  EmailThreadViewController.swift
//  memri
//
//  Created by Toby Brennan on 30/7/20.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import UIKit
import Combine

class EmailThreadedViewController: UITableViewController {
    var dataSource: UITableViewDiffableDataSource<Int, EmailThreadItem>?
    
    let resizeSubject = PassthroughSubject<Void, Never>()
    var resizeCancellable: AnyCancellable?
    
    var emails: [EmailThreadItem] = [] {
        didSet {
            updateDatasource()
        }
    }
    
    var displayCount: Int = 15
    
    
    var cachedEmailContentSize: [String: CGFloat] = [:]
    
    var userHasScrolled: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        resizeCancellable = resizeSubject.throttle(for: .milliseconds(100), scheduler: DispatchQueue.main, latest: true).sink { [weak self] in
            self?.invalidateCellLayout()
        }
        
        view.backgroundColor = .clear
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(EmailThreadCell.self, forCellReuseIdentifier: EmailThreadCell.reuseID)
        
        let dataSource = UITableViewDiffableDataSource<Int, EmailThreadItem>(tableView: tableView) { [weak self] (tableView, indexPath, email) -> UITableViewCell? in
            let cell = tableView.dequeueReusableCell(withIdentifier: EmailThreadCell.reuseID, for: indexPath) as! EmailThreadCell
            cell.setContent(email: email)
            cell.emailView.contentHeight = self?.cachedEmailContentSize[email.uuid] ?? cell.emailView.defaultSize
            cell.onEmailContentSizeUpdated = { [weak self] in
                self?.cachedEmailContentSize[email.uuid] = $0
                self?.resizeSubject.send()
            }
            return cell
        }
        
        self.dataSource = dataSource
        tableView.dataSource = dataSource
        updateDatasource()
    }
    
    func updateDatasource(animated: Bool = false) {
        guard let dataSource = dataSource else { return }
        var snapshot = NSDiffableDataSourceSnapshot<Int, EmailThreadItem>()
        snapshot.appendSections([0])
        snapshot.appendItems(emails.suffix(displayCount), toSection: 0)
        let update = {
            dataSource.apply(snapshot, animatingDifferences: true) { [weak self] in
                self?.onDataSourceUpdated()
            }
        }
        if animated {
            update()
        } else {
            UIView.performWithoutAnimation {
                update()
            }
        }
    }
    
    func onDataSourceUpdated() {
        isLoadingMoreItems = false
    }
    
    func invalidateCellLayout() {
        print(Date())
        tableView.beginUpdates()
        tableView.endUpdates()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !userHasScrolled, let snapshot = dataSource?.snapshot(), snapshot.numberOfItems > 0 {
            let lastSection = max(0, snapshot.numberOfSections - 1)
            let lastIndexPath = IndexPath(row: max(0, snapshot.numberOfItems(inSection: lastSection) - 1), section: lastSection)
            tableView.scrollToRow(at: lastIndexPath, at: .bottom, animated: false)
        }
    }
    
    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        userHasScrolled = true
    }
    
    var isLoadingMoreItems: Bool = false
    override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if scrollView.contentOffset.y < 0, displayCount < emails.count {
            isLoadingMoreItems = true
            displayCount += 2
            updateDatasource(animated: false)
        }
    }
}
