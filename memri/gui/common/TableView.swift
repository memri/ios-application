//
// TableView.swift
// Copyright © 2020 memri. All rights reserved.

import SwiftUI

private let cellIdentifier = "aTableViewCell"

struct TableView<Item, Content: View>: UIViewControllerRepresentable where Item: AnyObject {
    public var context: MemriContext!
    public var canDelete: Bool!
    public var canReorder: Bool!
    public var editMode: EditMode

    init(context: MemriContext, canDelete: Bool? = true, canReorder: Bool? = true) {
        self.context = context
        self.canDelete = canDelete
        self.canReorder = canReorder
        editMode = context.currentSession?.swiftUIEditMode ?? EditMode.inactive
    }

    func makeCoordinator() -> Coordinator<Item, Content> {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> UITableViewController {
        context.coordinator.tableViewController
    }

    func updateUIViewController(_: UITableViewController, context: Context) {
        if editMode.isEditing {
            context.coordinator.tableViewController.setEditing(true, animated: true)
        }
        else {
            context.coordinator.tableViewController.setEditing(false, animated: true)
        }
    }
}

class Coordinator<Item, Content: View>: NSObject, UITableViewDelegate,
    UITableViewDataSource where Item: AnyObject
{
    var parent: TableView<Item, Content>
    let tableViewController = TableViewController(style: UITableView.Style.plain)

    init(parent: TableView<Item, Content>) {
        self.parent = parent
        super.init()
        tableViewController.tableView.dataSource = self
        tableViewController.tableView.delegate = self
        tableViewController.tableView.register(
            HostingTableViewCell<Content>.self,
            forCellReuseIdentifier: cellIdentifier
        )
        tableViewController.tableView.tableHeaderView = UIView(frame: .zero)
        tableViewController.tableView.tableFooterView = UIView(frame: .zero)
        if Item.self == NavigationItem.self {
            UITableView.appearance().separatorColor = .clear
            UITableView.appearance().backgroundColor = .clear
            UITableViewCell.appearance().backgroundColor = .clear
        }
    }

    let name = "list"
    public var renderConfig: CascadingListConfig? {
        parent.context.cascadingView?.renderConfig as? CascadingListConfig
    }

    func item(_ navigationItem: NavigationItem) -> AnyView {
        switch navigationItem.type {
        case "item":
            return AnyView(NavigationItemView(item: navigationItem, hide: hide))
        case "heading":
            return AnyView(NavigationHeadingView(title: navigationItem.title))
        case "line":
            return AnyView(NavigationLineView())
        default:
            return AnyView(NavigationItemView(item: navigationItem, hide: hide))
        }
    }

    func hide() {
        withAnimation {
            self.parent.context.showNavigation = false
        }
    }

    //

    // MARK: Source Delegate

    //

    func numberOfSections(in _: UITableView) -> Int {
        1
    }

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        if Item.self == Item.self {
            return parent.context.items.count
        }
        else if Item.self == NavigationItem.self {
            return parent.context.navigation.getItems().count
        }
        else {
            fatalError("Object type not recognized")
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView
            .dequeueReusableCell(
                withIdentifier: cellIdentifier,
                for: indexPath
            ) as! HostingTableViewCell<Content>

        print("indexPath.row = \(indexPath.row)")
        if Item.self == Item.self {
            let dataItem = parent.context.items[indexPath.row]
            let guiView = renderConfig?.render(item: dataItem)
            cell.host(guiView as! Content, parent: tableViewController)
        }
        else if Item.self == NavigationItem.self {
            let navigationItem = parent.context.navigation.getItems()[indexPath.row]
            let guiView = item(navigationItem)
            cell.host(guiView as! Content, parent: tableViewController)
        }
        else {
            fatalError("Object type not recognized")
        }

        return cell
    }

    //

    // MARK: View Delegate

    //

    func tableView(_: UITableView, didSelectRowAt: IndexPath) {
        if Item.self == Item.self {
            let dataItem = parent.context.items[didSelectRowAt.row]
            if let press = renderConfig?.press {
                parent.context.executeAction(press, with: dataItem)
            }
        }
    }

    func tableView(_: UITableView, canEditRowAt _: IndexPath) -> Bool {
        if parent.canReorder || parent.canDelete {
            return true
        }
        else {
            return false
        }
    }

    func tableView(_: UITableView, canMoveRowAt _: IndexPath) -> Bool {
        parent.canReorder
    }

    func tableView(
        _: UITableView,
        moveRowAt sourceIndexPath: IndexPath,
        to destinationIndexPath: IndexPath
    ) {
        if Item.self == Item.self {
            let itemMoving = parent.context.items[sourceIndexPath.row]
            parent.context.items.remove(at: sourceIndexPath.row)
            parent.context.items.insert(itemMoving, at: destinationIndexPath.row)
        }
        else if Item.self == NavigationItem.self {
            //			let itemMoving = parent.context.navigation.getItems()[sourceIndexPath.row]
            #warning("This needs to be implemented. it needs to adjust the sequence value")
            //			parent.context.navigation.items.remove(at: sourceIndexPath.row)
            //			parent.context.navigation.items.insert(itemMoving, at: destinationIndexPath.row)
        }
        else {
            fatalError("Object type not recognized")
        }
    }

    func tableView(
        _: UITableView,
        commit editingStyle: UITableViewCell.EditingStyle,
        forRowAt _: IndexPath
    ) {
        if editingStyle == UITableViewCell.EditingStyle.delete {
        }
        else if editingStyle == UITableViewCell.EditingStyle.insert {}
    }

    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        if tableView.isEditing {
            let delete = deleteAction(deleteItemAtRow: indexPath)
            return UISwipeActionsConfiguration(actions: [delete])
        }
        else {
            let share = shareAction()
            let favorite = favoriteAction()
            return UISwipeActionsConfiguration(actions: [share, favorite])
        }
    }

    func tableView(
        _: UITableView,
        leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        let delete = deleteAction(deleteItemAtRow: indexPath)
        return UISwipeActionsConfiguration(actions: [delete])
    }

    //
    // TODO: Abstract based on data source, convert to use an image
    //
    private func shareAction() -> UIContextualAction {
        let share = UIContextualAction(
            style: .normal,
            title: "Share",
            handler: { (_: UIContextualAction, _: UIView, success: (Bool) -> Void) in
                print("Share Button Tapped")
                //
                // TODO: Call action on context
                //
                success(true)
            }
        )
        share.backgroundColor = .blue
        return share
    }

    private func favoriteAction() -> UIContextualAction {
        let favorite = UIContextualAction(
            style: .normal,
            title: "Favorite",
            handler: { (_: UIContextualAction, _: UIView, success: (Bool) -> Void) in
                print("Favorite Button Tapped")
                //
                // TODO: Call action on context
                //
                success(true)
            }
        )
        favorite.backgroundColor = .orange
        return favorite
    }

    private func deleteAction(deleteItemAtRow indexPath: IndexPath) -> UIContextualAction {
        let itemAtRow = indexPath
        let delete = UIContextualAction(
            style: .destructive,
            title: "Delete",
            handler: { (_: UIContextualAction, _: UIView, success: (Bool) -> Void) in
                print("Delete Button Tapped")
                if Item.self == Item.self {
                    self.parent.context.executeAction(
                        Action(self.parent.context, "delete"),
                        with: self.parent.context.items[itemAtRow.row]
                    )
                    self.tableViewController.tableView.deleteRows(
                        at: [indexPath],
                        with: UITableView.RowAnimation.automatic
                    )
                }
                else if Item.self == NavigationItem.self {
                    //
                    // TODO:
                    //
                }
                else {
                    fatalError("Object type not recognized")
                }
                success(true)
            }
        )
        delete.backgroundColor = .red
        return delete
    }
}

class TableViewController: UITableViewController {
    override init(style: UITableView.Style) {
        super.init(style: style)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = false
    }
}

class HostingTableViewCell<Content: View>: UITableViewCell {
    private weak var controller: UIHostingController<Content>?

    func host(_ view: Content, parent: UIViewController) {
        if let controller = controller {
            controller.rootView = view
            controller.view.layoutIfNeeded()
        }
        else {
            let swiftUICellViewController = UIHostingController(rootView: view)
            controller = swiftUICellViewController
            swiftUICellViewController.view.backgroundColor = .clear
            layoutIfNeeded()
            parent.addChild(swiftUICellViewController)
            contentView.addSubview(swiftUICellViewController.view)
            swiftUICellViewController.view.translatesAutoresizingMaskIntoConstraints = false
            contentView.addConstraint(NSLayoutConstraint(
                item: swiftUICellViewController.view!,
                attribute: NSLayoutConstraint.Attribute.leading,
                relatedBy: NSLayoutConstraint.Relation.equal,
                toItem: contentView,
                attribute: NSLayoutConstraint.Attribute.leading,
                multiplier: 1.0,
                constant: 0.0
            ))
            contentView.addConstraint(NSLayoutConstraint(
                item: swiftUICellViewController.view!,
                attribute: NSLayoutConstraint.Attribute.trailing,
                relatedBy: NSLayoutConstraint.Relation.equal,
                toItem: contentView,
                attribute: NSLayoutConstraint.Attribute.trailing,
                multiplier: 1.0,
                constant: 0.0
            ))
            contentView.addConstraint(NSLayoutConstraint(
                item: swiftUICellViewController.view!,
                attribute: NSLayoutConstraint.Attribute.top,
                relatedBy: NSLayoutConstraint.Relation.equal,
                toItem: contentView,
                attribute: NSLayoutConstraint.Attribute.top,
                multiplier: 1.0,
                constant: 0.0
            ))
            contentView.addConstraint(NSLayoutConstraint(
                item: swiftUICellViewController.view!,
                attribute: NSLayoutConstraint.Attribute.bottom,
                relatedBy: NSLayoutConstraint.Relation.equal,
                toItem: contentView,
                attribute: NSLayoutConstraint.Attribute.bottom,
                multiplier: 1.0,
                constant: 0.0
            ))

            swiftUICellViewController.didMove(toParent: parent)
            swiftUICellViewController.view.layoutIfNeeded()
        }
    }
}

// struct TableView: UIViewControllerRepresentable {
//
//    public var context: MemriContext!
//    public var canDelete: Bool!
//    public var canReorder: Bool!
//    public var editMode: EditMode
//
//    let name = "list"
//    public var renderConfig: ListConfig {
//        return self.context.computedView.renderConfigs[name] as? ListConfig ?? ListConfig()
//    }
//
//    init(context: MemriContext, canDelete: Bool? = true, canReorder: Bool? = true) {
//        self.context = context
//        self.canDelete = canDelete
//        self.canReorder = canReorder
//        self.editMode = context.currentSession.isEditMode
//    }
//
//    func makeCoordinator() -> Coordinator {
//        Coordinator(parent: self)
//    }
//
//    func makeUIViewController(context: Context) -> UITableViewController {
//        context.coordinator.tableViewController
//    }
//
//    func updateUIViewController(_ tableViewController: UITableViewController, context: Context) {
//        if self.editMode.isEditing {
//            context.coordinator.tableViewController.setEditing(true, animated: true)
//        } else {
//            context.coordinator.tableViewController.setEditing(false, animated: true)
//        }
//    }
// }
//

// class Coordinator : NSObject, UITableViewDelegate, UITableViewDataSource {
//
//    let parent: TableView
//    let tableViewController = TableViewController(style: UITableView.Style.plain)
//
//    init(parent: TableView) {
//        self.parent = parent
//        super.init()
//        tableViewController.tableView.dataSource = self
//        tableViewController.tableView.delegate = self
//        tableViewController.tableView.register(HostingTableViewCell<GUIElementInstance>.self, forCellReuseIdentifier: cellIdentifier)
//    }
//
//    //
//    // MARK: Source Delegate
//    //
//
//    func numberOfSections(in tableView: UITableView) -> Int {
//        //
//        // TODO: # sections? Headers, Footers?
//        //
//        1
//    }
//
//    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        self.parent.context.items.count
//    }
//
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let cell = tableView
//            .dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! HostingTableViewCell<GUIElementInstance>
//
//        let dataItem = self.parent.context.items[indexPath.row]
//        let guiView = self.parent.renderConfig.render(item: dataItem)
//        cell.host(guiView, parent: self.tableViewController)
//
//        return cell
//    }
//
//    //
//    // Mark: View Delegate
//    //
//
//    func tableView(_ tableView: UITableView, didSelectRowAt: IndexPath) {
//        let dataItem = self.parent.context.items[didSelectRowAt.row]
//        if let press = self.parent.renderConfig.press {
//            self.parent.context.executeAction(press, dataItem)
//        }
//    }
//
//    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
//        if self.parent.canReorder || self.parent.canDelete {
//            return true
//        } else {
//            return false
//        }
//    }
//
//    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
//        self.parent.canReorder
//    }
//
//    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
//        let itemMoving = self.parent.context.items[sourceIndexPath.row]
//        self.parent.context.items.remove(at: sourceIndexPath.row)
//        self.parent.context.items.insert(itemMoving, at: destinationIndexPath.row)
//    }
//
//    let deleteItemAction = ActionDescription(icon: "", title: "", actionName: .delete, actionArgs: [], actionType: .none)
//
//    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
//        if editingStyle == UITableViewCell.EditingStyle.delete {
//        } else if editingStyle == UITableViewCell.EditingStyle.insert {}
//    }
//
//    func tableView(_ tableView: UITableView,
//                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration?
//    {
//        if tableView.isEditing {
//            let delete = self.deleteAction(deleteItemAtRow: indexPath)
//            return UISwipeActionsConfiguration(actions: [delete])
//        } else {
//            let share = self.shareAction()
//            let favorite = self.favoriteAction()
//            return UISwipeActionsConfiguration(actions: [share, favorite])
//        }
//    }
//
//    func tableView(_ tableView: UITableView,
//                   leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration?
//    {
//        let delete = self.deleteAction(deleteItemAtRow: indexPath)
//        return UISwipeActionsConfiguration(actions: [delete])
//    }
//
//    //
//    // TODO: Abstract based on data source, convert to use an image
//    //
//    private func shareAction() -> UIContextualAction {
//        let share = UIContextualAction(style: .normal, title:  "Share", handler: { (ac: UIContextualAction, view: UIView, success: (Bool) -> Void) in
//            print("Share Button Tapped")
//            //
//            // TODO: Call action on context
//            //
//            success(true)
//        })
//        share.backgroundColor = .blue
//        return share
//    }
//
//    private func favoriteAction() -> UIContextualAction {
//        let favorite = UIContextualAction(style: .normal, title:  "Favorite", handler: { (ac: UIContextualAction, view: UIView, success: (Bool) -> Void) in
//            print("Favorite Button Tapped")
//            success(true)
//        })
//        favorite.backgroundColor = .orange
//        return favorite
//    }
//
//    private func deleteAction(deleteItemAtRow indexPath: IndexPath) -> UIContextualAction {
//        let itemAtRow = indexPath
//        let delete = UIContextualAction(style: .destructive, title:  "Delete", handler: { (ac: UIContextualAction, view: UIView, success: (Bool) -> Void) in
//            print("Delete Button Tapped")
//            self.parent.context.executeAction(self.deleteItemAction, self.parent.context.items[itemAtRow.row])
//            self.tableViewController.tableView.deleteRows(at: [indexPath], with: UITableView.RowAnimation.automatic)
//            success(true)
//        })
//        delete.backgroundColor = .red
//        return delete
//    }
// }
