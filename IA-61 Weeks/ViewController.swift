//
//  ViewController.swift
//  IA-61 Weeks
//
//  Created by Stas Panasuk on 3/19/18.
//  Copyright © 2018 iSan4eZ. All rights reserved.
//


import UIKit
import Foundation
import Alamofire

extension String {
    
    func sliceToArray(from: String, to: String) -> [String]? {
        var result = [String]()
        if self.contains(from){
            var startRange = self.range(of: from)!
            let endRange = range(of: to, range: (startRange.upperBound..<self.endIndex))!
            while let a = range(of: from, range: (startRange.upperBound..<endRange.lowerBound)) {
                startRange = a
            }
            result.append(String(self[startRange.upperBound..<endRange.lowerBound]))
            let next = self[startRange.upperBound..<self.endIndex]
            let out = String(next).sliceToArray(from: from, to: to)
            if out != nil && out!.count > 0{
                for i in out!{
                    result.append(i)
                }
            }
        }
        return result
    }
    
    func slice(from: String, to: String) -> String? {
        if self.contains(from){
            let startRange = self.range(of: from)!
            let endRange = range(of: to, range: (startRange.upperBound..<self.endIndex))!
            return(String(self[startRange.upperBound..<endRange.lowerBound]))
        }
        return nil
    }
}

class ViewController: UIViewController {
    
    @IBOutlet weak var scheduleView: UIScrollView!
    var days = [[UILabel]]()
    var screenSize: CGRect = UIScreen.main.bounds
    let dayWidth = CGFloat(250)
    let dayHeight = CGFloat(300)
    let gap = CGFloat(20)
    var prevRotated = -1
    var currentRotation = -1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.rotated), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
        view.addSubview(scheduleView)
        
        for _ in 1...12{
            createDay()
        }
        
        grabSchedule()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func rotated() {
        currentRotation = getRotation(rotation: UIDevice.current.orientation.rawValue)
        if currentRotation != prevRotated && currentRotation != -1{
            if UIDevice.current.orientation.isPortrait {
                screenSize = CGRect(x: 0,y: 0, width: min(UIScreen.main.bounds.width, UIScreen.main.bounds.height), height: max(UIScreen.main.bounds.width, UIScreen.main.bounds.height))
            }
            else if UIDevice.current.orientation.isLandscape {
                screenSize = CGRect(x: 0,y: 0, width: max(UIScreen.main.bounds.width, UIScreen.main.bounds.height), height: min(UIScreen.main.bounds.width, UIScreen.main.bounds.height))
            }
            prevRotated = currentRotation
            placeDays()
        }
    }
    
    func grabSchedule(){
        let file = "database.txt"
        
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            
            let fileURL = dir.appendingPathComponent(file)
            
            do {
                let database = try String(contentsOf: fileURL, encoding: .utf8)
                for line in database.components(separatedBy: "\n\n\n"){
                    let info = line.split(separator: "|")
                    if info.count >= 3{
                        self.days[Int(info[0])!][Int(info[1])!].text = "\(info[2])"
                    }
                }
            }
            catch { print("Reading from database error") }
            
            Alamofire.request("http://rozklad.kpi.ua/Schedules/ViewSchedule.aspx?g=826cc7ac-5116-4e1d-beda-1c05bd09855e&mobile=true").response { response in
                if let data = response.data, let htmlCode = String(data: data, encoding: .utf8) {
                    let rawSchedule = htmlCode.sliceToArray(from: "<td", to: "</td>")!
                    var databaseInfo = ""
                    if (rawSchedule.count > 0){
                        var dayIndex = 0
                        var index = 0
                        for line in rawSchedule{
                            var lesson = line.replacingOccurrences(of: "<br>", with: "\n ")
                            if lesson.first == ">" {
                                lesson.remove(at: lesson.startIndex)
                            }
                            if lesson.contains("</a>"){
                                let parsed = lesson.sliceToArray(from: "\">", to: "</a>")!
                                lesson = ""
                                for i in parsed{
                                    lesson += " \(i)"
                                    if i != parsed.last {lesson += "\n"}
                                }
                            }
                            if lesson.first != " " { lesson = " \(lesson)" }
                            if lesson.contains("\"day_backlight\"") { lesson = "" }
                            self.days[dayIndex][index].text = "\(lesson)"
                            databaseInfo.append("\(dayIndex)|\(index)|\(lesson)\n\n\n")
                            index += 1
                            if index % 12 == 0{ dayIndex += 1; index = 0 }
                        }
                        
                        do {
                            try databaseInfo.write(to: fileURL, atomically: false, encoding: .utf8)
                        }
                        catch { print("Writing to database error") }
                    }
                }
            }
        }
    }
    
    func getRotation(rotation: Int) -> Int {
        if rotation == 1{
            return 0
        } else if rotation == 2{
            return -1
        } else if rotation == 3 || rotation == 4{
            return 1
        } else {
            return currentRotation
        }
    }
    
    func placeDays(){
        if days.count > 0{
            var dayIndex = 1.0
            var weekDayIndex = 1.0
            var maxDays = 0.0
            if screenSize.width/(dayWidth+gap) < 2 {
                maxDays = 1.0
            } else if screenSize.width/(dayWidth+gap) < 3 {
                maxDays = 2.0
            } else if screenSize.width/(dayWidth+gap) < CGFloat(days.count/2) {
                maxDays = 3.0
            } else {
                maxDays = Double(days.count/2)
            }
            var x = screenSize.width/2 - dayWidth/CGFloat(2.0/maxDays) - gap/2*CGFloat(maxDays-1)
            var y = CGFloat(gap)
            var index = 0
            for day in days{
                let width = CGFloat(dayWidth/5)
                let height = CGFloat(dayHeight/6)
                var lbIndex = 0
                for label in day{
                    label.frame = CGRect(x: x, y: y, width: label.frame.width, height: label.frame.height)
                    if lbIndex % 2 == 0{
                        x += width - 1
                    } else {
                        x -= width - 1
                        y += height - 1
                    }
                    lbIndex += 1
                    index += 1
                }
                if dayIndex == maxDays || weekDayIndex == Double(days.count/2) {
                    dayIndex = 1.0
                    if weekDayIndex == Double(days.count/2){
                        weekDayIndex = 0.0
                        y += gap
                    }
                    if weekDayIndex + maxDays > Double(days.count/2){
                        let max = Double(days.count/2) - weekDayIndex
                        x = screenSize.width/2 - dayWidth/CGFloat(2/max) - gap/2*CGFloat(max-1)
                    } else {
                        x = screenSize.width/2 - dayWidth/CGFloat(2/maxDays) - gap/2*CGFloat(maxDays-1)
                    }
                    y += gap
                } else {
                    x += width*5 + gap
                    y -= height*6 - 6
                    dayIndex += 1.0
                }
                weekDayIndex += 1.0
            }
            scheduleView.contentSize = CGSize(width: screenSize.width, height: y + gap)
        }
    }
    
    func createDay(){
        var day = [UILabel]()
        var x = CGFloat(0)
        var y = CGFloat(0)
        let width = CGFloat(dayWidth/5)
        let height = CGFloat(dayHeight/6)
        for i in 0...5{
            for j in 0...1{
                let label = UILabel(frame: CGRect(x: x,y: y, width: width + (width*CGFloat(3*j)), height: height))
                
                label.layer.borderWidth = 1.0
                label.font = label.font.withSize(13)
                label.textAlignment = .left
                label.numberOfLines = 3
                //label.backgroundColor = UIColor.green
                //self.view.addSubview(label)
                scheduleView.addSubview(label)
                x = width * CGFloat(j) - CGFloat(j)
                y = height * CGFloat(i) - CGFloat(i)
                let tapGesture = UITapGestureRecognizer(target: self, action: #selector(ViewController.showContent))
                label.addGestureRecognizer(tapGesture)
                day.append(label)
            }
        }
        days.append(day)
    }
    
    @objc func showContent() {
        let alert = UIAlertController(title: "Alert", message: "Message", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Click", style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
}

