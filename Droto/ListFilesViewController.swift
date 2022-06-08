//
//  ListFilesViewController.swift
//  Droto
//
//  Created by Kyle Satti on 04/06/2022.
//

import UIKit
import Photos

@MainActor
class ListFilesViewController: UITableViewController {
    private let driveClient: GoogleDriveClient
    private let syncManager: SyncManager
    private var files = [File]()
    private var folder: Folder
    
    init(driveClient: GoogleDriveClient, syncManager: SyncManager, folder: Folder = .root) {
        self.driveClient = driveClient
        self.syncManager = syncManager
        self.folder = folder
        super.init(style: .plain)
        
        switch folder {
        case .root:
            navigationItem.title = "Droto"
        case .file(let file):
            navigationItem.title = file.name
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                barButtonSystemItem: .save, target: self, action: #selector(saveAll))
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(type: ThumbnailCell.self)
        tableView.rowHeight = UITableView.automaticDimension
        
        Task {
            switch await driveClient.getContentsOfFolder(folder: folder) {
            case let .success(response):
                self.files = response.files
                self.tableView.reloadData()
                
            case .failure:
                assertionFailure()
            }
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return files.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let file = files[indexPath.row]
        
        if let _ = file.thumbnailLink {
            let cell = tableView.dequeue(type: ThumbnailCell.self)
            cell.file = file
            cell.state = syncManager.state(for: file)
            
            cell.downloadButtonAction = { [weak self] file in
                guard let `self` = self else { return }
                
                Task {
                    switch self.syncManager.state(for: file) {
                    case .downloaded:
                        cell.state = .deleting
                        let _ = await self.syncManager.delete(file)
                    case .downloading, .deleting:
                        assertionFailure()
                    case .notDownloaded:
                        cell.state = .downloading
                        let _ = await self.syncManager.sync(file: file)
                    }
                    
                    cell.state = self.syncManager.state(for: file)
                }
            }
            
            return cell
        }
        
        let cellIdent = "cell"
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdent) ?? UITableViewCell(style: .default, reuseIdentifier: cellIdent)
        cell.textLabel?.text = file.name
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        navigationController?
            .pushViewController(ListFilesViewController(
                driveClient: driveClient,
                syncManager: syncManager,
                folder: .file(files[indexPath.row])
            ),animated: true)
    }
    
    @objc private func saveAll() {
        
    }
}
