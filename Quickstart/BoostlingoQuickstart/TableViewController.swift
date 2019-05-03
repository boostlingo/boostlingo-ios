//
//  TableViewController.swift
//  boostlingo-ios
//
//  Created by Denis Kornev on 18/04/2019.
//  Copyright © 2019 Boostlingo. All rights reserved.
//

import UIKit

class TableViewController: UITableViewController {
    
    weak var delegate: ViewControllerDelegate?
    var data: [TableViewItem]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        delegate = nil
        data = nil
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TableViewCell", for: indexPath)
        cell.textLabel?.text = data![indexPath.item].text
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.update(data![indexPath.item])
        navigationController?.popViewController(animated: true);
    }
}
