//
//  DetailView.swift
//  aimad240144419
//
//  Created by user on 17/12/2025.
//

import Foundation
import SwiftUI
struct DetailView : View {
 var student : Student
 var body : some View {
 VStack {
 //TASK A: - Define Two Text Elements and Show the information correctly
     Text("Name: \(student.name)")
     Text("Programme: \(getProgrammeIcon())")
 }
 }

 func getProgrammeIcon() -> String {
 //TASK B: - COMPLETE the getProgrammeIcon() function
     if (student.programme == "AIMAD"){
         return "�"
     }
    else if (student.programme == "SE"){
        return "💻"
    }
     else if (student.programme == "MM"){
         return "�"
     }
     else if (student.programme == "GA"){
         return "�"
     }
         
     
 return ""
 }
}
struct DetailView_Preview : PreviewProvider {
 @State static var student = Student(name: "Test Student", programme: "AIMAD")
 static var previews: some View {
 DetailView(student: student)
 }
}
