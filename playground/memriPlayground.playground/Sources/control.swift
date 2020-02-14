import Foundation
import SwiftUI


class Application {
    var lastSavedAppState: DataItem
    var name: String
    
    init(lastSavedAppState: DataItem, name: String){
        self.lastSavedAppState=lastSavedAppState
        self.name=name
    }
}


class NavigationItem{}

public struct Renderer: View {
    var name: String
    public var body: some View{
        return List(0..<3) { item in
                    Text("Title")
                }
    }
    public init(name: String?=nil){
        self.name=name ?? ""
    }
    
    mutating func setState(_ session: SessionView){
    }
}

public struct Search:View {
    @State var text=""

    public var body: some View{
        TextField("type your search query here", text: $text)
    }
    public init(text: String?=nil){
        self.text=text ?? ""
    }
    
    mutating func setState(_ session: SessionView){
    }
    
}

public struct TopNavigation: View {
    
    var title: String
    public var body: some View {
        return HStack {
                Button(action: /*@START_MENU_TOKEN@*/{}/*@END_MENU_TOKEN@*/) {
                    Image(systemName: "line.horizontal.3")
                }.padding(.horizontal , 5)
                
                Button(action: /*@START_MENU_TOKEN@*/{}/*@END_MENU_TOKEN@*/) {
                    Image(systemName: "chevron.left")
                }.padding(.horizontal , 5)
                
                Spacer()
                
                Text("\(self.title)")
                    .font(.headline)
                
                Spacer()
                
                Button(action: /*@START_MENU_TOKEN@*/{}/*@END_MENU_TOKEN@*/) {
                    Image(systemName: "plus")
                }.padding(.horizontal , 5)
                
                Button(action: /*@START_MENU_TOKEN@*/{}/*@END_MENU_TOKEN@*/) {
                    Image(systemName: "ellipsis")
                }.padding(.horizontal , 5)
                
            }.padding(.all, 30)
    }
    
    public init(title: String?=nil){
        self.title=title ?? ""
    }
    
    mutating func setState(_ session: SessionView){
        self.title=session.title
    }

    
}

public struct Browser: View {
    public var currentSession: Session
    var topNavigation: TopNavigation
    var renderer: Renderer
    var search: Search
    
    public var body: some View{
        return VStack{
            self.topNavigation
            self.renderer
            self.search
        }
    }
    
    public init(_ currentSession: Session){
        self.currentSession=currentSession
        self.topNavigation=TopNavigation()
        self.renderer=Renderer()
        self.search=Search()
        self.setState()
    }
    
    mutating func setState(){
        self.topNavigation.setState(self.currentSession.currentSessionView)
        self.renderer.setState(self.currentSession.currentSessionView)
        self.search.setState(self.currentSession.currentSessionView)
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
