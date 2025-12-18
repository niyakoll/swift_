//
//  GroupView.swift
//  aimad240144419
//
//  Created by user on 17/12/2025.
//

import Foundation
import SwiftUI
struct GroupView : View {
    @Binding var manager : StudentManager
    @State var allGroups : [[Student]] = []
    @State private var animatedGroupIndex = 0
     
    
    
    var body: some View {
        @State var allStudents = manager.getStudents()
        @State var unassignedCount: Int = allStudents.count  // Use manager's count
            
        VStack{
            Text("Grouping!")
            if unassignedCount >= 2 {
                            Text("Unassigned students: \(unassignedCount)")
                        } else {
                            Text("Not enough student left for grouping!")
                        }
            Button("Group Now!"){
                allStudents = performGrouping()
                unassignedCount = allStudents.count
            }
            Divider()
            List{
                
                ForEach(0..<allGroups.count, id: \.self){
                    groupIndex in
                    if groupIndex < animatedGroupIndex {  // Advanced: Show one by one
                                            Text("Group \(groupIndex + 1): \(allGroups[groupIndex].map { $0.name }.joined(separator: ", "))")
                                        }
                }
            }.listStyle(.plain)
            Spacer()
        }
        
        
    }
    private func performGrouping()->[Student] {
        var allStudents = manager.getStudents()  // Copy array
        allGroups = []  // Reset groups
        animatedGroupIndex = 0
        
        while allStudents.count >= 2 {
            if allStudents.count <= 3 {
                allGroups.append(allStudents)
                allStudents.removeAll()
                
            } else {
                let randomIndex1 = Int.random(in: 0..<allStudents.count)
                let student1 = allStudents.remove(at: randomIndex1)
                let randomIndex2 = Int.random(in: 0..<allStudents.count)
                let student2 = allStudents.remove(at: randomIndex2)
                allGroups.append([student1, student2])
            }
        }
            animateGroups()
        return allStudents
        }
    private func animateGroups() {  // Advanced: Timer to show groups one by one
            Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
                if animatedGroupIndex < allGroups.count {
                    animatedGroupIndex += 1
                } else {
                    timer.invalidate()  // Stop when done
                }
            }
        }
        
    }
    struct GroupView_Preivew : PreviewProvider {
        @State static var manager : StudentManager = StudentManager()
        static var previews: some View {
            GroupView(manager:$manager)
        }
    }

