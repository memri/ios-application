//
//  SwiftUIView.swift
//  memri
//
//  Created by Koen van der Veen on 20/03/2020.
//  Copyright © 2020 memri. All rights reserved.
//

import SwiftUI

enum NavigationType: Int, Decodable {
    case item, heading, line
}
extension StringProtocol {
    var firstUppercased: String { prefix(1).uppercased() + dropFirst() }
    var firstCapitalized: String { prefix(1).capitalized + dropFirst() }
}

class NavigationItem: ObservableObject, Decodable, Identifiable{
        
    public var id = UUID()

    /**
     * Used as the caption in the navigation
     */
    public var title: String? = nil
    /**
     * Name of the view it opens
     */
    public var view: String? = nil
    /**
     * Defines the position in the navigation
     */
    public var count: Int = 0
    /**
     *  0 = Item
     *  1 = Heading
     *  2 = Line
     */
    public var type: NavigationType = .item
    
    public convenience required init(from decoder: Decoder) throws {
        self.init()
        jsonErrorHandling(decoder) {
            self.title = try decoder.decodeIfPresent("title") ?? self.title
            self.view = try decoder.decodeIfPresent("view") ?? self.view
            self.count = try decoder.decodeIfPresent("count") ?? self.count
            self.type = try decoder.decodeIfPresent("type") ?? self.type
        }
    }
    public class func fromJSON(_ file: String, ext: String = "json") throws -> [NavigationItem] {
        let jsonData = try jsonDataFromFile(file, ext)
        let items: [NavigationItem] = try! JSONDecoder().decode([NavigationItem].self, from: jsonData)
        return items
    }
}

struct NavigationItemView: View{
    var title: String?
    
    var body: some View {
        HStack{
            Text(title != nil ? title!.firstUppercased: "")
                .font(.body)
                .padding(.vertical, 15)
                .padding(.horizontal, 50)
                .foregroundColor(Color(red: 0.85,
                                       green: 0.85,
                                       blue: 0.85))
            Spacer()
        }
    }
}
struct NavigationHeadingView: View{
    var title: String?

    var body: some View {
        HStack{
            Text(title != nil ? title!.uppercased() : "")
                .font(.title)
                .fontWeight(.bold)
                .padding(.horizontal, 25)
                .padding(.vertical, 8)
                .foregroundColor(Color(red: 0.55, green: 0.5, blue: 0.7))
            Spacer()
        }
    }
}
struct NavigationLineView: View{
    var body: some View {
        VStack {
            Divider().background(Color(.black))
        }.padding(.horizontal,50)
    }
}

struct NavigationItemView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationItemView()
    }
}
