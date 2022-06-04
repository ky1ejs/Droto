//
//  MimeType.swift
//  Droto
//
//  Created by Kyle Satti on 04/06/2022.
//

import Foundation

enum GoogleMimeType: String, Codable {
    case audio = "application/vnd.google-apps.audio"
    case document = "application/vnd.google-apps.document"
    case thirdPartyShortcut = "application/vnd.google-apps.drive-sdk"
    case drawing = "application/vnd.google-apps.drawing"
    case file = "application/vnd.google-apps.file"
    case folder = "application/vnd.google-apps.folder"
    case form = "application/vnd.google-apps.form"
    case fusionTable = "application/vnd.google-apps.fusiontable"
    case jamboard = "application/vnd.google-apps.jam"
    case map = "application/vnd.google-apps.map"
    case photo = "application/vnd.google-apps.photo"
    case presentation = "application/vnd.google-apps.presentation"
    case appsScript = "application/vnd.google-apps.script"
    case shortcut = "application/vnd.google-apps.shortcut"
    case site = "application/vnd.google-apps.site"
    case spreadsheet = "application/vnd.google-apps.spreadsheet"
    case unknown = "application/vnd.google-apps.unknown"
    case video = "application/vnd.google-apps.video"
    case wordDocument = "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
    case excelSpreadsheet = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    case powerpoint = "application/vnd.openxmlformats-officedocument.presentationml.presentation"
    case googleEarthMap = "application/vnd.google-earth.kmz"
    case zip = "application/zip"
    case json = "application/json"
    case html = "text/html"
    case drawIO = "application/vnd.jgraph.mxfile"
    case png = "image/png"
    case applePages = "application/x-iwork-pages-sffpages"
    case ePubZip = "application/epub+zip"
    case aiff = "audio/x-aiff"
    case jpeg = "image/jpeg"

    case pdf = "application/pdf"
}
