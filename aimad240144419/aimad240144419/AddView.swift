//
//  AddView.swift
//  aimad240144419
//
//  Created by user on 17/12/2025.
//

import Foundation
import SwiftUI
struct AddView : View {

 //Given Two binding from the Student List Page
 @Binding var showAdd : Bool
 @Binding var manager : StudentManager

 //TASK A: - create two states, var name : String and var programme : String with @State
 //assign a default value empty string ("")
    @State var name : String = ""
    @State var programme : String = ""
    
    
 var body : some View {

 VStack {
 Text("Add New Student").bold()

 //TASK B: - create the TWO textfields
 //.textFieldStyle(.roundedBorder) <== use this modifier to decorate the TextFields
     TextField("Name",text: $name).textFieldStyle(.roundedBorder)
     TextField("Programme",text: $programme).textFieldStyle(.roundedBorder)
 //TASK C: - create the Text elements
 //.font(.footnote) <== use these modifiers to decorate the TextField
 //.foregroundStyle(.gray)
     Text("For programme, please enter either AIMAD, SE,GA or MM only!")
         .font(.footnote)
         .foregroundStyle(.gray)

 if isValid == false {
 //TASK D: - create the Text elements (error message)
 //.font(.footnote) <== use these modifiers to decorate the TextField
 //.foregroundStyle(.red)
     Text("All textfields must not by empty").font(.footnote).foregroundStyle(.red)
 }

 Spacer()

 HStack {
 Button(action: {
 //TASK D: - complete the validation and functionalities
     
     if isValid {
         let new_student = Student(name: name, programme: programme)
         manager.addStudent(_student: new_student)
         showAdd = false
     }
 }, label : {
 Spacer()
Text("Add")
Spacer()
 })
 .frame(height: 50)
 .buttonStyle(.bordered)
 .padding(10)

 Button(action: {
 //TASK E: - complete the functionalities
     showAdd = false
 }, label : {
 Spacer()
Text("Cancel")
Spacer()
 })
 .frame(height: 10)
 .buttonStyle(.bordered)
 .padding(10)

 }
 }
 .padding()

 }

 //This is a computed property
 var isValid : Bool {
 //TASK F: - if the name.count > 0 and programme.count > 0 , then return true
     if name.count > 0 && programme.count > 0 {
         return true
     }
 return false
 }
}
struct AddView_Preview : PreviewProvider {
 @State static var manager : StudentManager = StudentManager()
 @State static var showAdd = false
 static var previews: some View {
 AddView(showAdd: $showAdd, manager: $manager)
 }
}
