import Foundation

class ActionDescription{
    var icon: String
    var title: String
    var actionName: String
    var actionArgs: [Any]
    
    init(icon: String, title: String, actionName: String, actionArgs: [Any]){
        self.icon=icon
        self.title=title
        self.actionName=actionName
        self.actionArgs=actionArgs
    }
}

class RenderConfig{
    var name: String
    var icon: String
    var category: String
    var items: [ActionDescription]
    var options1: [ActionDescription]
    var options2: [ActionDescription]
    
    init(name: String, icon: String, category: String, items: [ActionDescription], options1: [ActionDescription],
         options2: [ActionDescription]){
        self.name=name
        self.icon=icon
        self.category=category
        self.items=items
        self.options1=options1
        self.options2=options2
    }
}


class ListConfig: RenderConfig{
    
    var cascadeOrder: [String]
    var slideLeftActions: [ActionDescription]
    var slideRightActions: [ActionDescription]
    var type: String
    var browse: String
    var sortProperty: String
    var sortAscending: Int
    var itemRenderer: String
    var longPress: ActionDescription
    
    init(name: String, icon: String, category: String, items: [ActionDescription], options1: [ActionDescription],
         options2: [ActionDescription], cascadeOrder: [String], slideLeftActions: [ActionDescription],
         slideRightActions: [ActionDescription], type: String, browse: String, sortProperty: String,
         sortAscending: Int, itemRenderer: String, longPress: ActionDescription){
        self.cascadeOrder=cascadeOrder
        self.slideLeftActions=slideLeftActions
        self.slideRightActions=slideRightActions
        self.type=type
        self.browse=browse
        self.sortProperty=sortProperty
        self.sortAscending=sortAscending
        self.itemRenderer=itemRenderer
        self.longPress=longPress
        super.init(name: name, icon: icon, category: category, items: items, options1: options1, options2: options2)
        

    }
}

public class View {
    var searchResult: SearchResult
    var title: String
    var subtitle: String
    var renderName: String
    var selection: [String]
    var renderConfigs: [String: RenderConfig]
    var editButtons: [ActionDescription]
    var filterButtons: [ActionDescription]
    var actionItems: [ActionDescription]
    var navigateItems: [ActionDescription]
    var contextButtons: [ActionDescription]
    var icon: String
    var showLabels: Bool
    var contextMode: Bool
    var filterMode: Bool
    var editMode: Bool
    var browsingMode: Bool

    init(searchResult: SearchResult, title: String, subtitle: String, renderName: String, selection: [String],
         renderConfigs: [String: RenderConfig], editButtons: [ActionDescription], filterButtons: [ActionDescription],
         actionItems: [ActionDescription], navigateItems: [ActionDescription], contextButtons: [ActionDescription],
         icon: String, showLabels: Bool, contextMode: Bool, filterMode: Bool, editMode: Bool, browsingMode: Bool){
        self.searchResult = searchResult
        self.title = title
        self.subtitle=subtitle
        self.renderName=renderName
        self.selection=selection
        self.renderConfigs=renderConfigs
        self.editButtons=editButtons
        self.filterButtons=filterButtons
        self.actionItems=actionItems
        self.navigateItems=navigateItems
        self.contextButtons=contextButtons
        self.icon=icon
        self.showLabels=showLabels
        self.contextMode=contextMode
        self.filterMode=filterMode
        self.editMode=editMode
        self.browsingMode=browsingMode
    }

}


public class Session {
    var currentViewIndex: Int
    var views: [View]
    var currentView: View? {
        if currentViewIndex != -1 {
            return views[currentViewIndex]
        } else{
            return nil
        }
    }
    
    public init(currentViewIndex: Int = -1, views: [View]=[]){
        self.currentViewIndex = currentViewIndex
        self.views = views
    }
    
    public func back(){
        self.currentViewIndex -= 1
    }
    public func forward(){
        self.currentViewIndex += 1
    }

    
}
