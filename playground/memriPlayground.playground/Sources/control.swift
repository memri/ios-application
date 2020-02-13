import Foundation


class Application {
    var lastSavedAppState: DataItem
    var name: String
    
    init(lastSavedAppState: DataItem, name: String){
        self.lastSavedAppState=lastSavedAppState
        self.name=name
    }
}


class NavigationItem{}


public class Browser{
    var currentSession: Session
    
    public init(_ currentSession: Session){
        self.currentSession=currentSession
    }
    
    func setState(){
    }
}


class Navigation {
    var items: [NavigationItem]
    var currentItem: NavigationItem
    var scrollState: Int
    var editMode: Bool
    var selection: [NavigationItem]

    init(items: [NavigationItem], currentItem: NavigationItem, scrollState: Int, editMode: Bool, selection: [NavigationItem]){
        self.items=items
        self.currentItem=currentItem
        self.scrollState=scrollState
        self.editMode=editMode
        self.selection=selection
    }
    
    
}
