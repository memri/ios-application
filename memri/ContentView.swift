//
//  ContentView.swift
//  memri
//
//  Created by Koen van der Veen on 11/02/2020.
//  Copyright © 2020 Koen van der Veen. All rights reserved.
//

import SwiftUI


struct ContentView: View {
    @State var searchText=""
    @State var showFilters=false
    var body: some View {
        
        return VStack {
            HStack {
                Button(action: /*@START_MENU_TOKEN@*/{}/*@END_MENU_TOKEN@*/) {
                    Image(systemName: "line.horizontal.3")
                }.padding(.horizontal , 5)
                
                Button(action: /*@START_MENU_TOKEN@*/{}/*@END_MENU_TOKEN@*/) {
                    Image(systemName: "chevron.left")
                }.padding(.horizontal , 5)
                
                Spacer()
                
                Text("Daily Notes").font(.headline)
                
                Spacer()
                
                Button(action: /*@START_MENU_TOKEN@*/{}/*@END_MENU_TOKEN@*/) {
                    Image(systemName: "plus")
                }.padding(.horizontal , 5)
                
                Button(action: /*@START_MENU_TOKEN@*/{}/*@END_MENU_TOKEN@*/) {
                    Image(systemName: "ellipsis")
                }.padding(.horizontal , 5)
                
            }.padding(.all, 30)
            List(0 ..< 3) { item in
                Text("Title")
            }
            HStack{
                TextField("type your search query here", text: $searchText)
                    .onTapGesture {
                        print("abc")
                        self.showFilters=true
                    }
                
                
                Button(action: /*@START_MENU_TOKEN@*/{}/*@END_MENU_TOKEN@*/) {
                    Image(systemName: "star.fill")
                }.padding(.horizontal , 5)
                
                Button(action: /*@START_MENU_TOKEN@*/{}/*@END_MENU_TOKEN@*/) {
                    Image(systemName: "chevron.down")
                }.padding(.horizontal , 5)
                

            }.padding(.horizontal , 10)
            
            HStack(alignment: .top){
                VStack{
                    HStack(alignment: .bottom){
                        Button(action: /*@START_MENU_TOKEN@*/{}/*@END_MENU_TOKEN@*/) {
                            Image(systemName: "line.horizontal.3")
                        }
                        .padding(.horizontal , 5)
                        .background(Color(white: 0.95))
                        
                        Button(action: /*@START_MENU_TOKEN@*/{}/*@END_MENU_TOKEN@*/) {
                            Image(systemName: "square.grid.3x2.fill")
                        }
                        
                        Button(action: /*@START_MENU_TOKEN@*/{}/*@END_MENU_TOKEN@*/) {
                            Image(systemName: "calendar")
                        }.padding(.horizontal , 5)
                        
                        Button(action: /*@START_MENU_TOKEN@*/{}/*@END_MENU_TOKEN@*/) {
                            Image(systemName: "location.fill")
                        }.padding(.horizontal , 5)
                        
                        Button(action: /*@START_MENU_TOKEN@*/{}/*@END_MENU_TOKEN@*/) {
                            Image(systemName: "chart.bar.fill")
                        }.padding(.horizontal , 5)
                    }
                    VStack(alignment: .leading){
                        Button(action: /*@START_MENU_TOKEN@*/{}/*@END_MENU_TOKEN@*/) {
                            Text("Default")
                            .foregroundColor(Color.green)

                        }
                        Button(action: /*@START_MENU_TOKEN@*/{}/*@END_MENU_TOKEN@*/) {
                            Text("Select property")
                                .foregroundColor(Color.black)
                        }
                        Button(action: /*@START_MENU_TOKEN@*/{}/*@END_MENU_TOKEN@*/) {
                            Text("Date modified")
                            .foregroundColor(Color.black)

                        }
                        Button(action: /*@START_MENU_TOKEN@*/{}/*@END_MENU_TOKEN@*/) {
                            Text("Date created")
                            .foregroundColor(Color.black)
                        }
                        
                    }

                }

                VStack(alignment: .leading){
                    Text("Sort")
                        .font(.headline)
                    
                    Button(action: /*@START_MENU_TOKEN@*/{}/*@END_MENU_TOKEN@*/) {
                        Text("Sort")
                        .foregroundColor(Color.black)

                    }
                    Button(action: /*@START_MENU_TOKEN@*/{}/*@END_MENU_TOKEN@*/) {
                        Text("Select property")
                            .foregroundColor(Color.black)
                    }
                    Button(action: /*@START_MENU_TOKEN@*/{}/*@END_MENU_TOKEN@*/) {
                        Text("Date modified")
                        .foregroundColor(Color.black)

                    }
                    Button(action: /*@START_MENU_TOKEN@*/{}/*@END_MENU_TOKEN@*/) {
                        Text("Date created")
                        .foregroundColor(Color.green)
                    }
                }
                .padding()
            }

        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
