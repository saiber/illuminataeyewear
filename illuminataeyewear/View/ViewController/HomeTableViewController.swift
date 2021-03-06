//
//  HomeTableViewController.swift
//  illuminataeyewear
//
//  Created by Bushko Konstantyn on 1/25/16.
//  Copyright © 2016 illuminataeyewear. All rights reserved.
//

import UIKit
import Foundation
import Kanna

class HomeTableViewController: /*UITableViewController*/ BaseTableViewController {
    
    var newsPostItems = [NewsPost]()
    var simpleNewsPostItems = [SimpleNewsPost]()
    var featureProducts = [BrandItem]()
    
    var imageCache = [String:UIImage]()
    
    var featureSectionCount = 0
    
    let cellIdentifier = "NewsPostViewCell"
    
    private var isRunning = false
    
    override func viewDidLoad() {
        super.viewDidLoad();
        self.tableView.sectionIndexColor = UIColor(red: 200.0/255.0, green: 103.0/255.0, blue: 255.0/255.0, alpha: 1.0)
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl?.backgroundColor = UIColor.whiteColor()
        self.refreshControl?.tintColor = UIColor.grayColor()
        self.refreshControl?.addTarget(self, action: #selector(HomeTableViewController.updateNews(_:)), forControlEvents: .ValueChanged)
        self.navigationItem.setLeftBarButtonItem(UIBarButtonItem(image: UIImage(named: "mail_outline_black_24p"), style: .Plain, target: self, action: #selector(HomeTableViewController.notification(_:))), animated: true)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        isRunning = true
        self.updateNews(nil)
        
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        if let remoteNotification = appDelegate.options?[UIApplicationLaunchOptionsRemoteNotificationKey] as? NSDictionary {
            appDelegate.application(UIApplication.sharedApplication(), didReceiveRemoteNotification: remoteNotification as [NSObject : AnyObject])
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        isRunning = false
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func applicationDidBecomeActive(notification: NSNotification?) {
        super.applicationDidBecomeActive(notification)
        if Reachability.isConnectedToNetwork() == true {
            updateNews(nil)
        }
    }
    
    func updateNews(sender: AnyObject?) {
        NewsPost().getNewsPost({(newsPostItems) in
            self.refreshControl?.endRefreshing()
            if newsPostItems.count > 0  {
                self.newsPostItems = newsPostItems
                self.simpleNewsPostItems.removeAll()
            } else {
                return
            }
            for news in self.newsPostItems {
                if let doc = Kanna.HTML(html: news.text.htmlDecoded(), encoding: NSUTF8StringEncoding) {
                    let simpleNewsPost = SimpleNewsPost()
                    simpleNewsPost.text = doc.text!
                    for img in doc.xpath("//img | //src") {
                        let imgLink = img["src"]!
                        if imgLink.containsString("http://www.") || imgLink.containsString("wwww.")  || imgLink.containsString("http://") || imgLink.containsString("https://"){
                            simpleNewsPost.imageLink = imgLink
                        } else {
                            simpleNewsPost.imageLink = Constant.URL_BASE  + imgLink
                        }
                    }
                    
                    for iframe in doc.xpath("//iframe | //src") {
                        simpleNewsPost.iframe = iframe["src"]!
                    }
                    
                    simpleNewsPost.title = news.title
                    self.simpleNewsPostItems.append(simpleNewsPost)
                }
            }
            self.RefreshTable()
            BrandItem.GetFeatureProduct(20, completeHandler: {(brandItems) in
                for item in brandItems {
                    item.fullInitProduct({(brandItem) in
                        self.featureProducts.append(brandItem)
                        if self.featureProducts.count == brandItems.count {
                            self.featureSectionCount = self.featureProducts.count
                            self.RefreshTable()
                        }
                    })
                }
            })
            
            LiveCartController.sharedInstance().getBanners(true, completeHandler: {(banner) in
                self.RefreshTable()
            })
        })
    }
    
    func notification(sender: AnyObject) {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let notificationViewController = storyBoard.instantiateViewControllerWithIdentifier("NotificationNavigationController") as! UINavigationController
        self.presentViewController(notificationViewController, animated: true, completion: nil)
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 3
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else if section == 1 {
            return  simpleNewsPostItems.count
        } else if section == 2 {
            return featureSectionCount
        }
        return 0
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCellWithIdentifier("ImageCarouselCall", forIndexPath: indexPath) as! ImageCarouselCall
            cell.Update()
            return cell
        } else if indexPath.section == 1 {
            let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! NewsPostViewCell
            let newsPost = simpleNewsPostItems[indexPath.row]
            cell.title.text = newsPost.title.htmlDecoded()
            cell.shortDescription.text = newsPost.text
            (cell.readMore as! RoundRectButton).id = indexPath.row
            
            
            if !(newsPost.imageLink as NSString).isEqualToString("") {
                if let img = imageCache[newsPost.imageLink] {
                    cell.photo.image = img
                } else {
                    cell.photo.image = nil
                    if !(newsPost.imageLink as NSString).isEqualToString("") {
                        let url:NSURL =  NSURL(string: newsPost.imageLink)!
                        let session = NSURLSession.sharedSession()
                        let request = NSMutableURLRequest(URL: url)
                        request.HTTPMethod = "GET"
                        request.cachePolicy = NSURLRequestCachePolicy.ReloadIgnoringCacheData
                        
                        let task = session.dataTaskWithRequest(request) { (let data, let response, let error) in
                            guard let _:NSData = data, let _:NSURLResponse = response  where error == nil else {
                                return
                            }
                            let image = UIImage(data: data!)
                            self.imageCache[newsPost.imageLink] = image
                            dispatch_async(dispatch_get_main_queue(), {
                                let cell = tableView.dequeueReusableCellWithIdentifier(self.cellIdentifier, forIndexPath: indexPath) as! NewsPostViewCell
                                cell.photo.image = image
                                (cell.readMore as! RoundRectButton).enabled = true
                                if self.isRunning {
                                    tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.None)
                                }
                            })
                        }
                        task.resume()
                    }
                }
                cell.iFrame.hidden = true
                cell.photo.hidden = false
            } else if !(newsPost.iframe as NSString).isEqualToString(""){
                cell.photo.hidden = true
                cell.iFrame.hidden = false
                let html = "<iframe src=\"" + newsPost.iframe + "\" width=\"100%\" height=\"150\" frameborder=\"0\" allowfullscreen></iframe>"
                cell.iFrame.loadHTMLString(html, baseURL: nil)
                cell.iFrame.scrollView.scrollEnabled = false
                cell.iFrame.scrollView.bounces = false
            }
            return cell
        } else if indexPath.section == 2 {
            let cell = tableView.dequeueReusableCellWithIdentifier("FeatureProductViewCell", forIndexPath: indexPath) as! FeatureProductViewCell
            cell.photo.image = featureProducts[indexPath.row].getImage()
            cell.name.text = featureProducts[indexPath.row].getName()
            cell.name.numberOfLines = 0
            cell.name.sizeToFit()
            return cell
        } else {
            return UITableViewCell()
        }
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 2 {
            return "Featured Products"
        }
        return nil
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 200
        } else if indexPath.section == 1 {
            return 366
        } else if indexPath.section == 2{
            return 100
        } else {
            return 0
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 2 {
            let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let navigationController = storyBoard.instantiateViewControllerWithIdentifier("ProductInfoNavigationController") as! UINavigationController
            self.presentViewController(navigationController, animated: true, completion: nil)
            let productInfoViewController = navigationController.viewControllers.first as! ProductInfoViewController
            productInfoViewController.brandItem = self.featureProducts[indexPath.row]
        }
    }
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if(segue.identifier == "NewsDetails") {
            let newsDetailViewController = segue.destinationViewController as! NewsDetailsViewController
            if let indexPath : Int = (sender as! RoundRectButton).id {
                if !(simpleNewsPostItems[indexPath].imageLink as NSString).isEqualToString("") {

                    if self.imageCache[simpleNewsPostItems[indexPath].imageLink] != nil  {
                        newsDetailViewController.image = self.imageCache[simpleNewsPostItems[indexPath].imageLink]!
                    }
                    var moreText = newsPostItems[indexPath].moreText;
                    moreText = moreText.htmlDecoded()
                    var text = newsPostItems[indexPath].text;
                    text = text.htmlDecoded()
                    text = text.stringByReplacingOccurrencesOfString("<img\\s+[^>]*src=\"([^\"]*)\"[^>]*>", withString: "", options: .RegularExpressionSearch, range: nil)
                    newsDetailViewController.textHtml = text + "<p>" + moreText + "</p>"
                } else if !(simpleNewsPostItems[indexPath].iframe as NSString).isEqualToString("") {
                    newsDetailViewController.frameHtml = "<iframe src=\"" + simpleNewsPostItems[indexPath].iframe + "\" width=\"100%\" height=\"150\" frameborder=\"0\" allowfullscreen></iframe>"
                    var moreText = newsPostItems[indexPath].moreText;
                    moreText = moreText.htmlDecoded()
                    var text = newsPostItems[indexPath].text;
                    text = text.htmlDecoded()
                    text = moreText.stringByReplacingOccurrencesOfString("<iframe\\s+[^>]*src=\"([^\"]*)\"[^>]*>", withString: "", options: .RegularExpressionSearch, range: nil)
                    newsDetailViewController.textHtml = text + "<p>" + moreText + "</p>"
                }
            }
        }
    }
    
    func RefreshTable() {
        dispatch_async(dispatch_get_main_queue(), {
            self.tableView.reloadData()
            return
        })
    }
}
