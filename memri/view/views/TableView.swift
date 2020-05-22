//
//  TableView.swift
//  memri
//
//  Created by Jess Taylor on 5/21/20.
//  Copyright © 2020 memri. All rights reserved.
//

import SwiftUI

private let cellIdentifier = "aTableViewCell"

struct TableView: UIViewControllerRepresentable {
               
    public var main: Main!
    public var canDelete: Bool!
    public var canReorder: Bool!
    public var editMode: EditMode
    
    let name = "list"
    public var renderConfig: ListConfig {
        return self.main.computedView.renderConfigs[name] as? ListConfig ?? ListConfig()
    }

    init(main: Main, canDelete: Bool? = true, canReorder: Bool? = true) {
        self.main = main
        self.canDelete = canDelete
        self.canReorder = canReorder
        self.editMode = main.currentSession.isEditMode
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> UITableViewController {
        context.coordinator.tableViewController
    }

    func updateUIViewController(_ tableViewController: UITableViewController, context: Context) {
        if self.editMode.isEditing {
            context.coordinator.tableViewController.setEditing(true, animated: true)
        } else {
            context.coordinator.tableViewController.setEditing(false, animated: true)
        }
    }
}

class Coordinator : NSObject, UITableViewDelegate, UITableViewDataSource {

    let parent: TableView
    let tableViewController = TableViewController(style: UITableView.Style.plain)
    
    init(parent: TableView) {
        self.parent = parent
        super.init()
        tableViewController.tableView.dataSource = self
        tableViewController.tableView.delegate = self
        tableViewController.tableView.register(HostingTableViewCell<GUIElementInstance>.self, forCellReuseIdentifier: cellIdentifier)
    }

    //
    // MARK: Source Delegate
    //

    func numberOfSections(in tableView: UITableView) -> Int {
        //
        // TODO: # sections? Headers, Footers?
        //
        1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.parent.main.items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView
            .dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! HostingTableViewCell<GUIElementInstance>
        
        let dataItem = self.parent.main.items[indexPath.row]
        let guiView = self.parent.renderConfig.render(item: dataItem)
        cell.host(guiView, parent: self.tableViewController)
                
        return cell
    }
    
    //
    // Mark: View Delegate
    //
    
    func tableView(_ tableView: UITableView, didSelectRowAt: IndexPath) {
        let dataItem = self.parent.main.items[didSelectRowAt.row]
        if let press = self.parent.renderConfig.press {
            self.parent.main.executeAction(press, dataItem)
        }
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if self.parent.canReorder || self.parent.canDelete {
            return true
        } else {
            return false
        }
    }

    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        self.parent.canReorder
    }

    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let itemMoving = self.parent.main.items[sourceIndexPath.row]
        self.parent.main.items.remove(at: sourceIndexPath.row)
        self.parent.main.items.insert(itemMoving, at: destinationIndexPath.row)
    }
    
    let deleteItemAction = ActionDescription(icon: "", title: "", actionName: .delete, actionArgs: [], actionType: .none)
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == UITableViewCell.EditingStyle.delete {
        } else if editingStyle == UITableViewCell.EditingStyle.insert {}
    }
    
    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration?
    {
        if tableView.isEditing {
            let delete = self.deleteAction(deleteItemAtRow: indexPath)
            return UISwipeActionsConfiguration(actions: [delete])
        } else {
            let share = self.shareAction()
            let favorite = self.favoriteAction()
            return UISwipeActionsConfiguration(actions: [share, favorite])
        }
    }
    
    func tableView(_ tableView: UITableView,
                   leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration?
    {
        let delete = self.deleteAction(deleteItemAtRow: indexPath)
        return UISwipeActionsConfiguration(actions: [delete])
    }

    //
    // TODO: Abstract based on data source, convert to use an image
    //
    private func shareAction() -> UIContextualAction {
        let share = UIContextualAction(style: .normal, title:  "Share", handler: { (ac: UIContextualAction, view: UIView, success: (Bool) -> Void) in
            print("Share Button Tapped")
            //
            // TODO: Call action on main
            //
            success(true)
        })
        share.backgroundColor = .blue
        return share
    }

    private func favoriteAction() -> UIContextualAction {
        let favorite = UIContextualAction(style: .normal, title:  "Favorite", handler: { (ac: UIContextualAction, view: UIView, success: (Bool) -> Void) in
            print("Favorite Button Tapped")
            success(true)
        })
        favorite.backgroundColor = .orange
        return favorite
    }

    private func deleteAction(deleteItemAtRow indexPath: IndexPath) -> UIContextualAction {
        let itemAtRow = indexPath
        let delete = UIContextualAction(style: .destructive, title:  "Delete", handler: { (ac: UIContextualAction, view: UIView, success: (Bool) -> Void) in
            print("Delete Button Tapped")
            self.parent.main.executeAction(self.deleteItemAction, self.parent.main.items[itemAtRow.row])
            self.tableViewController.tableView.deleteRows(at: [indexPath], with: UITableView.RowAnimation.automatic)
            success(true)
        })
        delete.backgroundColor = .red
        return delete
    }
}

class TableViewController: UITableViewController {
 
    override init(style: UITableView.Style) {
        super.init(style: style)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}

class HostingTableViewCell<Content: View>: UITableViewCell {
    
    private weak var controller: UIHostingController<Content>?
    
    func host(_ view: Content, parent: UIViewController) {
        if let controller = controller {
            controller.rootView = view
            controller.view.layoutIfNeeded()
        } else {
            let swiftUICellViewController = UIHostingController(rootView: view)
            controller = swiftUICellViewController
            swiftUICellViewController.view.backgroundColor = .clear
            layoutIfNeeded()
            parent.addChild(swiftUICellViewController)
            contentView.addSubview(swiftUICellViewController.view)
            swiftUICellViewController.view.translatesAutoresizingMaskIntoConstraints = false
            contentView.addConstraint(NSLayoutConstraint(item: swiftUICellViewController.view!, attribute: NSLayoutConstraint.Attribute.leading, relatedBy: NSLayoutConstraint.Relation.equal, toItem: contentView, attribute: NSLayoutConstraint.Attribute.leading, multiplier: 1.0, constant: 0.0))
            contentView.addConstraint(NSLayoutConstraint(item: swiftUICellViewController.view!, attribute: NSLayoutConstraint.Attribute.trailing, relatedBy: NSLayoutConstraint.Relation.equal, toItem: contentView, attribute: NSLayoutConstraint.Attribute.trailing, multiplier: 1.0, constant: 0.0))
            contentView.addConstraint(NSLayoutConstraint(item: swiftUICellViewController.view!, attribute: NSLayoutConstraint.Attribute.top, relatedBy: NSLayoutConstraint.Relation.equal, toItem: contentView, attribute: NSLayoutConstraint.Attribute.top, multiplier: 1.0, constant: 0.0))
            contentView.addConstraint(NSLayoutConstraint(item: swiftUICellViewController.view!, attribute: NSLayoutConstraint.Attribute.bottom, relatedBy: NSLayoutConstraint.Relation.equal, toItem: contentView, attribute: NSLayoutConstraint.Attribute.bottom, multiplier: 1.0, constant: 0.0))

            swiftUICellViewController.didMove(toParent: parent)
            swiftUICellViewController.view.layoutIfNeeded()
        }
    }
}
