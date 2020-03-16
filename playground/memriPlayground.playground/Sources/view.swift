import Foundation

class ActionDescription: Codable{
    var icon: String
    var title: String
    var actionName: String
    // TODO: Make serializeble
//    var actionArgs: [Any]
    
//    init(icon: String, title: String, actionName: String, actionArgs: [Any]){
    init(icon: String, title: String, actionName: String){

        self.icon=icon
        self.title=title
        self.actionName=actionName
//        self.actionArgs=actionArgs
    }
}

class RenderConfig: Codable{
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
    
    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
}

public class SessionView: Codable {
    public var searchResult: SearchResult
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
    
    public class func from_json(_ file: String, ext: String = "json") throws -> [SessionView] {
        let fileURL = Bundle.main.url(forResource: file, withExtension: ext)
        let jsonString = try String(contentsOf: fileURL!, encoding: String.Encoding.utf8)
        let jsonData = jsonString.data(using: .utf8)!
        let items: [SessionView] = try! JSONDecoder().decode([SessionView].self, from: jsonData)
        return items
    }
}


public class Session: Codable {
    var currentSessionViewIndex: Int
    var sessionViews: [SessionView]
    public var currentSessionView: SessionView {
        if currentSessionViewIndex >= 0 {
            return sessionViews[currentSessionViewIndex]
        } else{
            return sessionViews[0]
        }
    }
    
    public init(currentSessionViewIndex: Int = 0, sessionViews: [SessionView]){
        self.currentSessionViewIndex = currentSessionViewIndex
        self.sessionViews = sessionViews
    }
    
    public func back(){
        self.currentSessionViewIndex -= 1
    }
    public func forward(){
        self.currentSessionViewIndex += 1
    }
    
    public class func from_json(_ file: String, ext: String = "json") throws -> Session {
        let fileURL = Bundle.main.url(forResource: file, withExtension: ext)
        let jsonString = try String(contentsOf: fileURL!, encoding: String.Encoding.utf8)
        let jsonData = jsonString.data(using: .utf8)!
        let session: Session = try! JSONDecoder().decode(Session.self, from: jsonData)
        return session
    }
}
