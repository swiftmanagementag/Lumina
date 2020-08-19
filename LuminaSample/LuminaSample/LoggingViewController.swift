//
//  LoggingViewController.swift
//  LuminaSample
//
//  Created by David Okun on 12/30/17.
//  Copyright © 2017 David Okun. All rights reserved.
//

import Lumina
import UIKit

protocol LoggingLevelDelegate: AnyObject {
    func didSelect(loggingLevel: Logger.Level, controller: LoggingViewController)
}

class LoggingViewController: UITableViewController {
    weak var delegate: LoggingLevelDelegate?

    // MARK: - Table view data source

    override func numberOfSections(in _: UITableView) -> Int {
        return 1
    }

    override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return Logger.Level.allCases.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
        guard let textLabel = cell.textLabel else {
            return cell
        }
        textLabel.text = Logger.Level.allCases[indexPath.row].uppercasedStringRepresentation
        return cell
    }

    override func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedLoggingLevel = Logger.Level.allCases[indexPath.row]
        delegate?.didSelect(loggingLevel: selectedLoggingLevel, controller: self)
    }
}
