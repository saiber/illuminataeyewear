//
//  LiveCartController.swift
//  illuminataeyewear
//
//  Created by Bushko Konstantyn on 2/6/16.
//  Copyright © 2016 illuminataeyewear. All rights reserved.
//

import Foundation

class LiveCartController {
    private static var DEFAULT_COUNTRY_ID: String = "CA"
    private static var DEFAULT_COUNTRY_NAME: String = "Canada"
    
    private static var _instance: LiveCartController?
    private init() {}
    
    private var countryList = [Country]()
    private var shippingServiceList = [ShippingService]()
    private var deliveryZone = [DeliveryZone]()
    private var deliveryZoneCountry = [DeliveryZoneCountry]()
    private var banners = [Banner]()
    
    class func sharedInstance() -> LiveCartController {
        if _instance == nil {
            _instance = LiveCartController()
            _instance?.initController()
        }
        return _instance!
    }
    
    private func initController () {
        
        // Initialize live cart controller
        Banner().GetBanners({(banners, message, error) in
            if error == nil {
                self.banners = banners
            }
        })
        
        Country.GetCountryList({(countryList) in
            self.countryList = countryList
        })
        ShippingService().GetShippingServices({(shippingServiceList, message, error) in
            self.shippingServiceList = shippingServiceList
        })
        DeliveryZone().GetDeliveryZone({(deliveryZoneList) in
            self.deliveryZone = deliveryZoneList
        })
        DeliveryZoneCountry().GetDeliveryZoneCountry({(deliveryZoneCountryList) in
            self.deliveryZoneCountry = deliveryZoneCountryList
        })
    }
    
    func getBanners(update: Bool, completeHandler:(Array<Banner>) -> Void) {
        if update {
            completeHandler(self.banners)
        } else {
            Banner().GetBanners({(banners, message, error) in
                if error == nil {
                    self.banners = banners
                    completeHandler(self.banners)
                }
            })
        }
    }
    
    func getCountries() -> Array<Country> {
        return self.countryList
    }
    
    func getCountryCodeByName(country_name: String) -> Country {
        for country in self.countryList {
            if (country.getCountry() as NSString).isEqualToString(country_name) {
                return country
            }
        }
        let country = Country()
        country.setCountryID(LiveCartController.DEFAULT_COUNTRY_ID)
        country.setCountry(LiveCartController.DEFAULT_COUNTRY_NAME)
        return country
    }
    
    func getCountryNameByCode(countryID: String) -> String {
        for country in self.countryList {
            if (country.getCountryID() as NSString).isEqualToString(countryID) {
                return country.getCountry()
            }
        }
        return ""
    }
    
    func getShippingService() -> Array<ShippingService> {
        return self.shippingServiceList
    }
    
    /*func getShipmentServiceByDeliveryZoneID(ID: Int64) -> Array<ShippingService> {
        var serviceList = [ShippingService]()
        if self.shippingServiceList.count == 0 {
            return serviceList
        }
        for service in self.shippingServiceList {
            if service.deliveryZoneID == ID {
                serviceList.append(service)
            }
        }
        return serviceList
    }*/
    
    func getShipmentServiceByDeliveryZoneID(ID: Int64, completeHandler: (Array<ShippingService>) -> Void) {
        var serviceList = [ShippingService]()
        if self.shippingServiceList.count == 0 {
            ShippingService().GetShippingServices({(shippingServiceList, message, error) in
                if error == nil {
                    self.shippingServiceList = shippingServiceList
                    for service in self.shippingServiceList {
                        if service.deliveryZoneID == ID {
                            serviceList.append(service)
                        }
                    }
                }
                completeHandler(serviceList)
            })
        } else {
            for service in self.shippingServiceList {
                if service.deliveryZoneID == ID {
                    serviceList.append(service)
                }
            }
            completeHandler(serviceList)
        }
    }
    
    func getShippingServiceByID(ID: Int64, completeHandler:(ShippingService?) -> Void) {
        if self.shippingServiceList.count > 0 {
            for service in self.shippingServiceList {
                if service.ID == ID {
                    completeHandler(service)
                    return
                }
            }
            ShippingService().GetShippingServiceByID(ID, completeHandler: {(shippingServices, message, error) in
                if error == nil {
                    if shippingServices.count > 0 {
                        self.shippingServiceList.append(shippingServices[0])
                        completeHandler(shippingServices[0])
                        return
                    }
                }
            })
        }
    }
    
    func getDeliveryZone() -> Array<DeliveryZone> {
        return self.deliveryZone
    }
    
    func getDeliveryZoneCountry() -> Array<DeliveryZoneCountry> {
        return self.deliveryZoneCountry
    }
    
    func getDeliveryZoneCountryByCode(countryCode: String) -> Array<DeliveryZoneCountry> {
        if self.deliveryZoneCountry.count == 0 {
            return [DeliveryZoneCountry]()
        }
        var _deliveryZoneCountry = [DeliveryZoneCountry]()
        for countryZone in self.deliveryZoneCountry {
            if (countryZone.countryCode as NSString).isEqualToString(countryCode) {
                _deliveryZoneCountry.append(countryZone)
            }
        }
        return _deliveryZoneCountry
    }
    
    func getDeliveryZoneByName(name: String) -> Array<DeliveryZone> {
        if self.deliveryZone.count == 0 {
            return [DeliveryZone]()
        }
        var _deliveryZone = [DeliveryZone]()
        for zone in self.deliveryZone {
            if (zone.name as NSString).isEqualToString(name) {
                _deliveryZone.append(zone)
            }
        }
        return _deliveryZone
    }
    
    func getDeliveryZoneByID(ID: Int64) -> DeliveryZone? {
        if self.deliveryZone.count == 0 {
            return nil
        }
        for zone in self.deliveryZone {
            if zone.ID == ID {
                return zone
            }
        }
        return nil
    }
    
    // MARK
    
    func startSession() {
        if UserController.sharedInstance().isAnonimous() {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let tabBarController = storyboard.instantiateViewControllerWithIdentifier("MainTabBarController") as! UITabBarController
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            if appDelegate.window?.rootViewController != nil {
                appDelegate.window?.rootViewController?.dismissViewControllerAnimated(true, completion: nil)
            }
            appDelegate.window?.rootViewController = tabBarController
            if !DBApnToken.IsSuccessSubmited() {
                let token = DBApnToken.GetToken()
                if token != nil {
                    UserApnToken.SaveUserApnToken(nil, token: token!, completeHandler: {() in })
                }
            }
            dispatch_async(dispatch_get_main_queue()) {
                LiveCartController.TabBarUpdateWishBadgeValue(tabBarController)
            }
        } else {
            OrderController.sharedInstance().UpdateUserOrder(UserController.sharedInstance().getUser()!.ID, completeHandler: {(successInit) in
                dispatch_async(dispatch_get_main_queue()) {
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    let tabBarController = storyboard.instantiateViewControllerWithIdentifier("MainTabBarController") as! UITabBarController
                    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
                    if appDelegate.window?.rootViewController != nil {
                        appDelegate.window?.rootViewController?.dismissViewControllerAnimated(true, completion: nil)
                    }
                    appDelegate.window?.rootViewController = tabBarController
                    LiveCartController.TabBarUpdateBadgeValue(tabBarController)
                    LiveCartController.TabBarUpdateWishBadgeValue(tabBarController)
                }
            })
        }
        
    }
    
    static func TabBarUpdateBadgeValue(tabBarController: UITabBarController) {
        dispatch_async(dispatch_get_main_queue()) {            
            var count = 0
            if OrderController.sharedInstance().getCurrentOrder() != nil {
                for item in OrderController.sharedInstance().getCurrentOrder()!.productItems {
                    count += item.count
                }
            }
            if count > 0 {
                tabBarController.tabBar.items![2].badgeValue = String(count)
            } else {
                tabBarController.tabBar.items![2].badgeValue = nil
            }
        }
    }
    
    static func TabBarUpdateWishBadgeValue(tabBarController: UITabBarController) {
        dispatch_async(dispatch_get_main_queue()) {
            let count = DBWishProductTable.SelectWish().count
            if count > 0 {
                tabBarController.tabBar.items![3].badgeValue = String(count)
            } else {
                tabBarController.tabBar.items![3].badgeValue = nil
            }
        }
    }
    
}







