//
//  UserSearchViewController.swift
//  Tapglue Elements
//
//  Created by John Nilsen  on 14/03/16.
//  Copyright (c) 2015 Tapglue (https://www.tapglue.com/). All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import UIKit
import Tapglue

public class UserSearchViewController: UIViewController {

    public var delegate: UserSearchViewDelegate?
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    let cellNothingFoundReusableIdentifier = "NothingFoundCell"
    let cellSearchAddressBookReusableIdentifier = "SearchAddressBookCell"
    let cellConnectionReusableIdentifier = "ConnectionCell"
    
    var isSearching = false
    var searchResult = [TGUser]()
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        title = "Search"
        tableView.contentInset = UIEdgeInsets(top: 44, left: 0, bottom: 0, right: 0)
        tableView.registerNibs(nibNames: [cellConnectionReusableIdentifier, cellNothingFoundReusableIdentifier, cellSearchAddressBookReusableIdentifier])
        tableView.estimatedRowHeight = 80
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.backgroundColor = UIColor.clearColor()
        applyConfiguration(TapglueUI.config)
    }

    // MARK: - Navigation

    override public func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "toProfile" {
            let vc = segue.destinationViewController as! ProfileViewController
            let user = sender as! TGUser
            vc.userId = user.userId
        }
    }

}

extension UserSearchViewController: UISearchBarDelegate {
    public func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        isSearching = true
        searchBar.resignFirstResponder()
        Tapglue.searchUsersWithTerm(searchBar.text!) { (users:[AnyObject]!, error:NSError!) -> Void in
            if error == nil {
                self.searchResult = users as! [TGUser]
                dispatch_async(dispatch_get_main_queue()) {() -> Void in
                    self.tableView.reloadData()
                }
            } else {
                dispatch_async(dispatch_get_main_queue()) {() -> Void in
                    let alert = UIAlertController(title: "Something went wrong", message: "please try again later", preferredStyle: .Alert)
                    let action = UIAlertAction(title: "ok", style: .Default, handler: nil)
                    alert.addAction(action)
                    self.presentViewController(alert, animated:true, completion: nil)
                }
            }
        }
    }
    public func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        isSearching = false
        tableView.reloadData()
    }
}

extension UserSearchViewController: UITableViewDataSource {
    public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchResult.count == 0 {
            return 1
        }
        return searchResult.count
    }
    
    public func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.1
    }
    
    public func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
    
    public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        if searchResult.count == 0 {
            if isSearching {
                return tableView.dequeueReusableCellWithIdentifier(cellNothingFoundReusableIdentifier)!
            } else {
                return tableView.dequeueReusableCellWithIdentifier(cellSearchAddressBookReusableIdentifier)!
            }
        }
        let connectionCell = tableView.dequeueReusableCellWithIdentifier(cellConnectionReusableIdentifier, forIndexPath: indexPath) as! ConnectionCell
        let user = searchResult[indexPath.row]
        connectionCell.user = user
        connectionCell.delegate = self
        
        return connectionCell
    }
}

extension UserSearchViewController: UITableViewDelegate {
    public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = tableView.cellForRowAtIndexPath(indexPath)
        if ((cell as? ConnectionCell) != nil) {
            if delegate?.defaultNavigationEnabledInUserSearchViewController(self) ?? true {
                performSegueWithIdentifier("toProfile", sender: searchResult[indexPath.row])
            } else {
                delegate?.userSearchViewController(self, didSelectUser: searchResult[indexPath.row])
            }
        } else if (cell as? SearchAddressBookCell) != nil {
            if delegate?.defaultNavigationEnabledInUserSearchViewController(self) ?? true {
                performSegueWithIdentifier("toAddressBook", sender: nil)
            } else {
                delegate?.didTapAddressBookInUserSearchViewController(self)
            }
        }
        tableView.deselectRowAtIndexPath(indexPath, animated:true)
    }
    
    public func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        cell.backgroundColor = UIColor.clearColor()
    }

}

extension UserSearchViewController: ConnectionCellDelegate {
    func connectionCellErrorOcurred() {
        AlertFactory.defaultAlert(self)
    }
}

public protocol UserSearchViewDelegate {
    
    /**
     Asks delegate if the calling view controller should handle its own navigation
     - Parameter userSearchViewController: user search view controller object asking the delegate
     - Returns: boolean value to indicate if navigation should be handled or not
     */
    func defaultNavigationEnabledInUserSearchViewController(userSearchViewController: UserSearchViewController) -> Bool
    
    /**
     Tells delegate that a user was selected
     - Parameters:
        - userSearchViewController: user search view controller object informing the delegate
        - user: user selected
     */
    func userSearchViewController(userSearchViewController: UserSearchViewController, didSelectUser user: TGUser)
    
    /**
     Tell delegate address book search was selected
     - Parameter userSearchViewController: user search view controller informing the delegate
    */
    func didTapAddressBookInUserSearchViewController(userSearchViewController: UserSearchViewController)
}
