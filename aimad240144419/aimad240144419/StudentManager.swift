//
//  StudentManager.swift
//  aimad240144419
//
//  Created by user on 17/12/2025.
//
import SwiftUI
import Foundation
struct StudentManager {

 //GIVEN, the student array
 fileprivate var students : [Student] = []

 //GIVEN, preload 5 set of data
 init() {
 let student1 = Student(name: "CC Lui", programme: "AIMAD")
 let student2 = Student(name: "KC Cheung", programme: "SE")
 let student3 = Student(name: "Marcus Kwok", programme: "AIMAD")
 let student4 = Student(name: "Frieda Lee", programme: "SE")
 let student5 = Student(name: "Cheng Lok Lok", programme: "AIMAD")

 self.students = [student1, student2, student3, student4, student5]
 }

 func getCount() -> Int {
 //TASK A: - return the number of the students Array
     return students.count
 }

 func getStudent(at index : Int) -> Student {
 //TASK B: return the student instance at the given index in students array
     return students[index]
 }


 //TASK C: define the function mutating func add(_ student : Student)
 //function: append the student into the students array
    mutating func addStudent(_student:Student){
        students.append(_student)
    }

 //TASK D: define a mutating function remove, it accepts 1 int parameter named index
 //function: remove the element in students at the given index by students.remove(at: index)
    mutating func removeStudent(at index:Int){
        students.remove(at:index)
    }
 //TASK E: define the function name getStudents
 //function: The function will return the students array
    func getStudents()->[Student]{
        return students
    }
    
}

