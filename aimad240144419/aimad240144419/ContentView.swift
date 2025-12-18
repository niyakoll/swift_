//
//  ContentView.swift
//  aimad240144419
//
//  Created by user on 11/12/2025.
//

import SwiftUI
struct ContentView: View {
    
    //TASK A - Define a state (a variable named manager) using @State
    //Create and assign an instance of StudentManager() into it
    //Example: @State var manager = .....
    @State var manager = StudentManager()
    @State var showGroup: Bool = false
    @State var showAdd: Bool = false
    var body: some View {
        //TASK B - Use a NavigationView / NavigationTack
        //(replace [SwiftUI Element A]) to wrap the content)
        
        NavigationStack {
            //TASK C - Use a VStack (replace [SwiftUI Element B]) to wrap the content
            VStack {
                //TASK D - Use a List (replace [SwiftUI Element C]) to wrap the content
                List {
                    ForEach(0..<manager.getCount(), id:\.self){
                        i in
                        
                        //Task E - Get a instance of student,
                        //e.g., let student = manager.... (think of the correct function)
                        let student = manager.getStudent(at: i)
                        
                        //Task F - Make a Text element to display the student name
                        
                        NavigationLink{
                            DetailView(student:student)
                        }label:{
                            Text(student.name)
                        }
                        
                    }
                    .onDelete { indexSet in  // Advanced: Deletion feature
                        indexSet.forEach { index in
                            manager.removeStudent(at: index)
                        }
                        
                    }
                }
                .navigationTitle("Student List")
                //TASK G - Use the .navigationTitle modifier to change the title
                .toolbar {
                    ToolbarItem(content: {
                        HStack {
                            //TASK H - Use two buttons showing "Group Now!" and "+"
                            Button("Group Now!"){
                                showGroup = true
                            }
                            Button("+"){
                                showAdd = true
                            }
                        }
                    })
                }.sheet(isPresented: $showGroup){
                    GroupView(manager:$manager)
                }
                .sheet(isPresented: $showAdd){
                    AddView(showAdd: $showAdd, manager: $manager)
                }
            }
        }
    }
    struct ContentView_Preivew : PreviewProvider {
        static var previews: some View {
            ContentView()
        }
    }
}
