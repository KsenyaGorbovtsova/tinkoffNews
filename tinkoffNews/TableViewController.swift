//
//  File.swift
//  tinkoffNews
//
//  Created by Gorbovtsova Ksenya on 16/05/2019.
//  Copyright © 2019 Gorbovtsova Ksenya. All rights reserved.
//

import UIKit
import CoreData
import Foundation

class TableViewController: UITableViewController {
    
    var listNews = [piece]()
    var pageOffset = 0
    var pageSize = 20
    override func viewDidLoad() {
        super.viewDidLoad()
        requestNext20()
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.title = "TinkoffNews"
        let refreshControl = UIRefreshControl()
        refreshControl.tintColor = UIColor.init(displayP3Red: 1.00, green:0.92, blue:0.23, alpha:1.0)
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        self.refreshControl = refreshControl
        NotificationCenter.default.addObserver(self, selector: #selector(reloadNews(notification:)), name:.reloadNews, object: nil)
        
    }
   
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return listNews.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "pieceOfNews", for: indexPath)
        let newsInf = self.listNews[indexPath.row]
        cell.textLabel?.text = newsInf.title
        cell.textLabel?.numberOfLines = 0
        
      //  cell.detailTextLabel?.text = Date.getFormattedDate(string: newsInf.date, formatter: "yyyy-mm-ddThh:mm:ssZ", newFormat: "MM-dd-yyyy")
        cell.detailTextLabel?.text = newsInf.date
        return cell
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "detail" {
             let indexPath = self.tableView.indexPath(for: (sender as! UITableViewCell))
            let newsSlug = self.listNews[indexPath!.row].slug
           
            let detailView = segue.destination as! ViewController
            detailView.slug = newsSlug
        }
    }
    private func requestNext20 () {
        if isInternetAvailable()
        {
        let url = URL(string: "https://cfg.tinkoff.ru/news/public/api/platform/v1/getArticles?pageSize=\(pageSize)&pageOffset=\(pageOffset)")
        if let endPoint = url {
            var request = URLRequest(url: endPoint)
            request.httpMethod = "GET"
            let dataTask = URLSession.shared.dataTask(with: request)  {data, response, error in
                guard error == nil else {
                    return
                }
                guard let data = data else {
                    return
                }
                self.parseResponse(data: data)
                self.pageOffset += 20
               
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
            dataTask.resume()
        } else {
            //не верный урл
            }
        } else {
            DisplayWarnining(warning: "проверьте подключение к интернету", title: "Упс!", dismissing: false, sender: self)
        }
    }
    
    private func parseResponse(data: Data) {
        let decoder = JSONDecoder()
        let resp = try! decoder.decode(response.self, from: data)
        self.listNews = self.listNews + resp.response.news
        self.listNews.sort{($0.date)>($1.date)}
      
    }
   
    @objc func reloadNews (notification: Notification) {
        self.requestNext20()
    }
    @objc func refresh(){
        NotificationCenter.default.post(name: .reloadNews, object: nil)
        tableView.reloadData()
        refreshControl?.endRefreshing()
    }
}
extension Notification.Name {
    static let reloadNews = Notification.Name("reloadNews")
}

extension Date {
    static func getFormattedDate(string: String , formatter:String, newFormat: String) -> String{
        let dateFormatterGet = DateFormatter()
        dateFormatterGet.dateFormat = formatter//"yyyy-MM-dd'T'HH:mm:ssZ"
        
        let dateFormatterPrint = DateFormatter()
        dateFormatterPrint.dateFormat = newFormat//"MMM dd,yyyy"
        
        let date: Date? = dateFormatterGet.date(from: string)//"2018-02-01T19:10:04+00:00")
        ///  print("Date",dateFormatterPrint.string(from: date!)) // Feb 01,2018
        return dateFormatterPrint.string(from: date!);
    }
    
    
}
