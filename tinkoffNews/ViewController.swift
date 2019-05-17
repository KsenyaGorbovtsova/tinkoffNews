//
//  ViewController.swift
//  tinkoffNews
//
//  Created by Gorbovtsova Ksenya on 16/05/2019.
//  Copyright © 2019 Gorbovtsova Ksenya. All rights reserved.
//

import UIKit
import CoreData

class ViewController: UIViewController {
    var slug = ""
    var pieceOfNews: detailInfo?{
        didSet {
             NotificationCenter.default.post(name: .reloadView, object: nil)
            stopSpinner(spinner: spinner)
        }
    }
    let spinner = UIActivityIndicatorView(style: .gray)
    @IBOutlet weak var mainTiltle: UILabel!
    @IBOutlet weak var textShort: UILabel!
    @IBOutlet weak var longText: UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(reloadView(notification:)), name: .reloadView, object: nil)
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let managedContext = appDelegate.persistentContainer.viewContext
        let detailFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Detail")
        detailFetch.fetchLimit = 1
        detailFetch.predicate = NSPredicate(format: "slug = %@", slug)
        let details = try! managedContext.fetch(detailFetch) as! [NSManagedObject]
        if details.isEmpty == true {
            requestDetails()
        } else {
            pieceOfNews = detailInfo(slug: details[0].value(forKey: "slug") as! String, title: details[0].value(forKey: "title") as! String, text: details[0].value(forKey: "text") as! String, textShort: details[0].value(forKey: "textShort") as! String)
           
        }
        
        self.navigationController?.navigationBar.prefersLargeTitles = false
        self.mainTiltle.numberOfLines = 0
        self.textShort.numberOfLines = 0
        self.spinner.color = UIColor.init(displayP3Red: 1.00, green:0.92, blue:0.23, alpha:1.0)
        self.spinner.center = view.center
        self.spinner.hidesWhenStopped = false
        self.spinner.startAnimating()
        view.addSubview(self.spinner)
       
    }
    private func cashDetails(info: detailInfo) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let entityDetail = NSEntityDescription.entity(forEntityName: "Detail", in: context)
        let newInfo = NSManagedObject(entity: entityDetail!, insertInto: context)
        newInfo.setValue(info.slug, forKey: "slug")
        newInfo.setValue(info.text, forKey: "text")
        newInfo.setValue(info.textShort, forKey: "textShort")
        newInfo.setValue(info.title, forKey: "title")
        do {
            try context.save()
        } catch {
            print("Failed saving")
        }
    }
    
    private func requestDetails () {
        if isInternetAvailable()
        {
        let url = URL(string: "https://cfg.tinkoff.ru/news/public/api/platform/v1/getArticle?urlSlug=\(self.slug)")
        if let endPoint = url {
            var request = URLRequest(url: endPoint)
            request.httpMethod = "GET"
            let dataTask = URLSession.shared.dataTask(with: request) {data, response, error in
                self.stopSpinner(spinner: self.spinner)
                guard error == nil else {
                    return
                }
                guard let data = data else {
                    return
                }
                self.parseResponse(data: data)
                
            }
            dataTask.resume()
        } else {
            //не верный урл
        }
        }
        else {
             DisplayWarnining(warning: "проверьте подключение к интернету", title: "Упс!", dismissing: true, sender: self)
        }
    }
    private func parseResponse(data: Data) {
        let decoder = JSONDecoder()
        let resp = try! decoder.decode(detailResponse.self, from: data)
        self.pieceOfNews = resp.response
        cashDetails(info: resp.response)
    }
    @objc func reloadView(notification: Notification){
        DispatchQueue.main.async {
            let data = Data((self.pieceOfNews?.text.utf8)!)
            if let attributedString = try? NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding: String.Encoding.utf8.rawValue], documentAttributes: nil) {
                self.longText.attributedText = attributedString
            }
            self.mainTiltle.text = self.pieceOfNews?.title
            self.textShort.text = self.pieceOfNews?.textShort
        }
        
    }
    func stopSpinner(spinner: UIActivityIndicatorView) {
        DispatchQueue.main.async {
            spinner.stopAnimating()
            spinner.removeFromSuperview()
        }
    }

   
}

extension Notification.Name {
    static let reloadView = Notification.Name("reloadView")
    
}
