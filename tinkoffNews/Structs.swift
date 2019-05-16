//
//  News.swift
//  tinkoffNews
//
//  Created by Gorbovtsova Ksenya on 16/05/2019.
//  Copyright © 2019 Gorbovtsova Ksenya. All rights reserved.
//

import Foundation

struct response: Codable {
    let response: news
}
struct news: Codable {
    let news : [piece]
}
struct piece: Codable {
    let id: String
    let title: String
    let date: String
    let slug: String
}

struct detailResponse: Codable {
    let response: detailInfo
}
struct detailInfo:Codable {
    let id: String
    let title: String
    let text: String
    let textShort: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case text
        case textShort = "textshort"
        
    }
}
