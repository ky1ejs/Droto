//
//  ThumbnailCell.swift
//  Droto
//
//  Created by Kyle Satti on 04/06/2022.
//

import Foundation
import UIKit
import Kingfisher

class ThumbnailCell: UITableViewCell {
    private let thumbnailImage: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()
    private let titleLable: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()
    private let downloadButton: UIButton = {
        let button = UIButton()
        button.setTitle("Download", for: .normal)
        button.setTitleColor(.red, for: .normal)
        return button
    }()
    
    var file: File? {
        didSet {
            titleLable.text = file?.name
            thumbnailImage.kf.setImage(with: file?.thumbnailLink)
        }
    }
    
    var state: SyncState = .notDownloaded {
        didSet {
            downloadButton.setTitle(state.title, for: .normal)
            downloadButton.isEnabled = !state.isLoading
        }
    }
    
    var downloadButtonAction: ((File) -> ())?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        
        contentView.addSubview(thumbnailImage)
        contentView.addSubview(titleLable)
        contentView.addSubview(downloadButton)
        
        contentView.subviews.forEach { view in view.translatesAutoresizingMaskIntoConstraints = false }
        
        downloadButton.addTarget(self, action: #selector(downloadButtonTapped), for: .touchUpInside)
        
        let thumbnailHeight = thumbnailImage.heightAnchor.constraint(equalToConstant: 60)
        thumbnailHeight.priority = UILayoutPriority(990)
        
        NSLayoutConstraint.activate([
            thumbnailImage.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 14),
            thumbnailImage.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 14),
            thumbnailImage.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -14),
            thumbnailHeight,
            thumbnailImage.widthAnchor.constraint(equalTo: thumbnailImage.heightAnchor),
            
            titleLable.leadingAnchor.constraint(equalTo: thumbnailImage.trailingAnchor, constant: 12),
            titleLable.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            downloadButton.leadingAnchor.constraint(equalTo: titleLable.trailingAnchor, constant: 12),
            downloadButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            downloadButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -14),
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func downloadButtonTapped() {
        if let file = file {
            downloadButtonAction?(file)
        }
    }
}

private extension SyncState {
    var title: String {
        switch self {
        case .notDownloaded: return "Download"
        case .downloading: return "Downloading"
        case .deleting: return "Deleting"
        case .downloaded: return "Delete"
        }
    }
    
    var isLoading: Bool {
        switch self {
        case .notDownloaded, .downloaded:
            return false
        case .deleting, .downloading:
            return true
        }
    }
}
