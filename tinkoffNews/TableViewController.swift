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
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        tableView.reloadData()
    }
    var indexPathChoosenCell = IndexPath()
    var listNews = [piece]()
    var updateCounter = 0
    var loadedNews = [NSManagedObject]()
    var pageOffsetManage = [NSManagedObject]()
    var pageOffset = 0
    var pageSize = 20
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(reloadCounter(notification:)), name: .reloadCounter, object: nil)
        self.navigationController?.navigationBar.prefersLargeTitles = true
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
            let managedContext = appDelegate.persistentContainer.viewContext
            let fetchRequestCounter = NSFetchRequest<NSFetchRequestResult>(entityName: "Load")
            do {
                pageOffsetManage = try! managedContext.fetch(fetchRequestCounter) as! [NSManagedObject]
                if pageOffsetManage.isEmpty == false {
                pageOffset = pageOffsetManage[0].value(forKey: "counter") as! Int
                }else {
                    pageOffset = 0
                }
            } catch {
                print(error)
            }
            
            let fetchRequestNews = NSFetchRequest<NSFetchRequestResult>(entityName: "News")
            do {
                loadedNews = try! managedContext.fetch(fetchRequestNews) as! [NSManagedObject]
                if loadedNews.isEmpty == false {
                    for x in loadedNews {
                        let appendPiece = piece(id: x.value(forKey: "id") as! String, title: x.value(forKey: "title") as! String, date: x.value(forKey: "date") as! String, slug: x.value(forKey: "slug") as! String, clicks: x.value(forKey: "clickCount") as! Int)
                        listNews.append(appendPiece)
                    }
                }else {
                    requestNext20()
                }
                
            } catch {
                print(error)
            }
     //   }
        
       
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
        if indexPath == self.indexPathChoosenCell {
            cell.detailTextLabel?.text = "Просмотры: " + String(self.updateCounter)
        } else {
        let newsInf = self.listNews[indexPath.row]
        cell.textLabel?.text = newsInf.title
        cell.textLabel?.numberOfLines = 0
        cell.detailTextLabel?.text = "Просмотры: " + String(newsInf.clicks)
        }
        return cell
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "detail" {
            
             let indexPath = self.tableView.indexPath(for: (sender as! UITableViewCell))
            self.indexPathChoosenCell = indexPath!
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
               // self.pageOffset += 20
               
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
        cashNews(news: resp.response.news)
      
    }
    private func cashNews(news: [piece]) {
        pageOffset = pageOffset + news.count
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let entityNews = NSEntityDescription.entity(forEntityName: "News", in: context)
        
        for x in news {
            let newNews = NSManagedObject(entity: entityNews!, insertInto: context)
            newNews.setValue(x.title, forKey: "title")
            newNews.setValue(x.slug, forKey: "slug")
            newNews.setValue(x.date, forKey: "date")
            newNews.setValue(x.id, forKey: "id")
            do {
                try context.save()
            } catch {
                print("Failed saving")
            }
        }
        if pageOffsetManage.isEmpty == true {
            let entityCounter = NSEntityDescription.entity(forEntityName: "Load", in: context)
            let counter = NSManagedObject(entity: entityCounter!, insertInto: context)
            counter.setValue(pageOffset, forKey: "counter")
        }else {
        if pageOffsetManage[0].value(forKey: "counter") as! Int != pageOffset{
            pageOffsetManage[0].setValue(pageOffset, forKey: "counter")
        }
        do {
            try context.save()
        } catch {
            print("Failed saving")
        }
        }
    }
    @objc func reloadNews (notification: Notification) {
        self.requestNext20()
    }
    @objc func refresh(){
        NotificationCenter.default.post(name: .reloadNews, object: nil)
        tableView.reloadData()
        refreshControl?.endRefreshing()
    }
    @objc func reloadCounter(notification: Notification) {
        if let data = notification.userInfo as? [String:Int] {
            for x in data {
                self.updateCounter = x.value
            }
        }
    }
}
extension Notification.Name {
    static let reloadNews = Notification.Name("reloadNews")
    static let reloadCounter = Notification.Name("reloadCounter")
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
