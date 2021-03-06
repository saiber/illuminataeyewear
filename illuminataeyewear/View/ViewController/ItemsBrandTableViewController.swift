//
//  ItemsBrandTableViewController.swift
//  illuminataeyewear
//
//  Created by Bushko Konstantyn on 1/13/16.
//  Copyright © 2016 illuminataeyewear. All rights reserved.
//

import UIKit
import Foundation
import BTNavigationDropdownMenu

enum SortType: Int {
    case None, New, AZ, ZA, Price
}

class ItemsBrandTableViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate, NSXMLParserDelegate {
    
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    @IBOutlet var tableView: UITableView!
    
    
    var isRunning: Bool = false
    var brand: Brand?
    var brandID = Int64()
    var brandItems = [BrandItem]()
    var imageCache = [String:UIImage]()
    
    let items = ["Newest Arrivals","Product Name: A-Z", "Product Name: Z-A"]
    var sortMenuView: BTNavigationDropdownMenu?
    var sortType = SortType.None
    var postMethod = "list"
    
    let cellIdentifier = "BrandItemViewCell"
    
    let limit: Int64 = 10
    var end: Bool = false
    
    var indicatorCellCoun = 1
    
    var paramString = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        isRunning = true
        if brand != nil {
            super.title = brand?.name
            self.brandID = (self.brand?.ID)!
            getProduct()
        }
        
        tableView.dataSource = self
        tableView.delegate = self
        
        sortMenuView = BTNavigationDropdownMenu(navigationController: self.navigationController, title: items.first!, items: items)
        sortMenuView?.checkMarkImage = UIImage(named: "sort_white_24p")
    
        sortMenuView!.didSelectItemAtIndexHandler = {(indexPath: Int) -> () in
            self.sortType = SortType(rawValue: indexPath + 1)!
            print("Did select item at index: \(indexPath) " + String(self.sortType))
            
            switch self.sortType.rawValue {
                case SortType.New.rawValue:
                    print("Newest Arrivals")
                    self.postMethod = "list"
                    break
                case SortType.AZ.rawValue:
                    print("A-Z")
                    self.postMethod = "az"
                    break
                case SortType.ZA.rawValue:
                    print("Z-A")
                    self.postMethod = "za"
                    break
                default:
                    print("LIST")
                    self.postMethod = "list"
                    break
            }
            self.end = false
            self.brandItems = [BrandItem]()
            self.imageCache = [String:UIImage]()
            self.activityIndicator.startAnimating()
            self.tableView.hidden = true
            self.getProduct()
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        //self.getProduct()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(false)
        isRunning = false
        if sortMenuVisible {
            self.sortMenuView?.hide()
        }
    }
    
    var sortMenuVisible:Bool = false
    @IBAction func SortBy(sender: AnyObject) {
        if self.sortMenuVisible {
            self.sortMenuVisible = false
            self.sortMenuView?.hide()
        } else {
            self.sortMenuVisible = true
            self.sortMenuView?.show()
        }
    }
    
    func initWithBrandID(brandID: Int64) {
        self.navigationItem.rightBarButtonItem = nil
        Brand.GetBrandByID(brandID, completeHandler: {(brand) in
            self.brand = brand
            self.getProduct()
            self.title = self.brand?.name
        })
    }
    
    
    // MARK: Table view data source
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return brandItems.count;
        } else {
            return self.indicatorCellCoun
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! BrandItemViewCell
            let brandItem = brandItems[indexPath.row]
            cell.name.text = brandItem.getName()
            cell.number.text = String(indexPath.row)
            cell.price.text = OrderController.sharedInstance().getCurrentOrderCurrency() + " " + brandItem.getPrice().definePrices
            cell.brandItem = brandItem
            (cell.BuyNowButton as ExButton).id = indexPath.row
            
            if(brandItem.getPrice().definePrices == "") {
                let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
                dispatch_async(dispatch_get_global_queue(priority, 0)) {
                    // do some task
                    PriceItem.getPriceBySKU((brandItem.getSKU()), completeHandler: {(priceItem) in
                        self.brandItems[indexPath.row].setPrice(priceItem)
                        dispatch_async(dispatch_get_main_queue()) {
                            // update some UI
                            if self.isRunning {
                                tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.None)
                            }
                        }
                    })
                }
            }
            
            if let img = imageCache[brandItem.defaultImageName] {
                cell.photo.image = img
            } else {
                let url:NSURL =  NSURL(string: Constant.URL_IMAGE + brandItem.defaultImageName)!
                let session = NSURLSession.sharedSession()
                let request = NSMutableURLRequest(URL: url)
                request.HTTPMethod = "GET"
                request.cachePolicy = NSURLRequestCachePolicy.ReloadIgnoringCacheData
                
                let task = session.dataTaskWithRequest(request) { (let data, let response, let error) in
                    guard let _:NSData = data, let _:NSURLResponse = response  where error == nil else {
                        return
                    }
                    let image = UIImage(data: data!)
                    self.imageCache[brandItem.defaultImageName] = image
                    dispatch_async(dispatch_get_main_queue(), {
                        let cell = tableView.dequeueReusableCellWithIdentifier(self.cellIdentifier, forIndexPath: indexPath) as! BrandItemViewCell
                        cell.photo.image = image
                        tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.None)
                    })
                }
                task.resume()
            }
            
            if indexPath.row == (self.brandItems.count - 1) {
                getProduct()
            }
            return cell
        } else if indexPath.section == 1 {
            let cell = tableView.dequeueReusableCellWithIdentifier("ActivityIndicatorCell", forIndexPath: indexPath) as! ActivityIndicatorCell
            cell.indicator.startAnimating()
            return cell
        }
        return UITableViewCell()
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 265//145
        } else if indexPath.section == 1{
            return 60
        } else {
            return 0
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 0 {
            //let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! BrandItemViewCell
            //addProductToCart(cell.BuyNowButton)
            self.addToCart(indexPath.row)
        }
    }
    
    @IBAction func addProductToCart(sender: AnyObject) {
        let index = (sender as! ExButton).id
        /*dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            BrandItem.getBrandItemByParentNode(self.brandItems[index].ID, completeHandler: {(brandItems) in
                if brandItems.count == 0 {
                    dispatch_async(dispatch_get_main_queue()) {
                        let brandItemViewController = self.storyboard?.instantiateViewControllerWithIdentifier("BrandItemViewController") as? BrandItemViewController
                        brandItemViewController?.brandItem = self.brandItems[index]
                        self.navigationController?.pushViewController(brandItemViewController!, animated: true)
                    }
                } else {
                    for item in brandItems {
                        item.parentBrandItem = self.brandItems[index]
                        //self.brandItems.append(item)
                    }
                    dispatch_async(dispatch_get_main_queue(), {
                        let index = (sender as! ExButton).id
                        let itemPageViewController = self.storyboard?.instantiateViewControllerWithIdentifier("ItemPageViewController") as? ItemPageViewController
                        self.navigationController?.pushViewController(itemPageViewController!, animated: true)
                        itemPageViewController!.brandItems = brandItems
                        itemPageViewController!.parentBrandItem = self.brandItems[index]
                        return
                    })
                }
            })
        }*/
        self.addToCart(index)
    }

    
    @IBAction func SerchProduct(sender: AnyObject) {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let navigationViewController = storyBoard.instantiateViewControllerWithIdentifier("SerchNavigationViewController") as! UINavigationController
        self.presentViewController(navigationViewController, animated: true, completion: nil)
        let searchViewController = navigationViewController.viewControllers.first as! SerchViewController
        searchViewController.categoryID = (self.brand?.ID)!
    }
    
    private func addToCart(index: Int) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            BrandItem.getBrandItemByParentNode(self.brandItems[index].ID, completeHandler: {(brandItems) in
                if brandItems.count == 0 {
                    dispatch_async(dispatch_get_main_queue()) {
                        let brandItemViewController = self.storyboard?.instantiateViewControllerWithIdentifier("BrandItemViewController") as? BrandItemViewController
                        brandItemViewController?.brandItem = self.brandItems[index]
                        self.navigationController?.pushViewController(brandItemViewController!, animated: true)
                    }
                } else {
                    for item in brandItems {
                        item.parentBrandItem = self.brandItems[index]
                        //self.brandItems.append(item)
                    }
                    dispatch_async(dispatch_get_main_queue(), {
                        //let index = (sender as! ExButton).id
                        let itemPageViewController = self.storyboard?.instantiateViewControllerWithIdentifier("ItemPageViewController") as? ItemPageViewController
                        self.navigationController?.pushViewController(itemPageViewController!, animated: true)
                        itemPageViewController!.brandItems = brandItems
                        itemPageViewController!.parentBrandItem = self.brandItems[index]
                        return
                    })
                }
            })
        }
    }

    func getProduct() {
        if self.end {
            return
        }
        let start: Int64 = (Int64)(self.brandItems.count)
        let categoryID: String = String((brand?.ID)!)
        self.paramString = "xml=<product><" + self.postMethod + " start=" + String(start) + " limit=" + String(self.limit) + "><categoryID>" + categoryID + "</categoryID><isEnabled>1</isEnabled></" + self.postMethod + "></product>"
        
        BrandItem.getItems(self.paramString, completeHandler: {(brandItems) in
            if (Int64)(brandItems.count) < self.limit {
                self.end = true
                self.indicatorCellCoun = 0
                //print("End list")
            }
            self.brandItems += brandItems
            self.activityIndicator.stopAnimating()
            self.tableView.hidden = false
            self.RefreshTable()
        })
    }
    
    func RefreshTable() {
        dispatch_async(dispatch_get_main_queue(), {
            self.tableView.reloadData()
            return
        })
    }
}







































