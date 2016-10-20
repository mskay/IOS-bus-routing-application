import UIKit
import Alamofire
import SwiftyJSON

//Old value was just UIViewController, change back if needed
//class DetailViewController: UIViewController {

class DetailViewController: UITableViewController {
    
    @IBOutlet weak var detailDescriptionLabel: UILabel!
    @IBOutlet weak var routeLabel: UILabel!
    
    @IBOutlet weak var NavigationTitle: UINavigationItem!
    // The routes that go to a particular stop
    var stopRoutes = [String]()
    var routeStops = [RouteItem]()
    // The stops that a particular route goes to
    static var stops = [String]()
    static var stops2 = [String]()
    //var arrival = ""
    
    var detailBus: BusItem? {
        didSet {
            configureView()
        }
    }
    
    func configureView() {
        Alamofire.request(.GET, "http://api.umd.io/v0/bus/routes/"+detailBus!.route_id)
            .responseJSON { response in
                let json = JSON(response.result.value!)
                for i in 0..<json["directions"][0]["stops"].count {
                    DetailViewController.stops.append(json["directions"][0]["stops"][i].string!)
                }
                if json["directions"].count > 1 {
                    for i in 0..<json["directions"][1]["stops"].count {
                        DetailViewController.stops2.append(json["directions"][1]["stops"][i].string!)
                    }
                }
        }
        
        if detailBus != nil {
            // This means they are clicking a stop
            if detailBus?.route_id == "" {
                for i in 0..<detailBus!.routes.count {
                    //print(detailBus!.routes[i])
                    stopRoutes.append((detailBus!.routes[i]))
                }
                // Otherwise they are clicking a route
            } else {
                // Clear the array
                //DetailViewController.stops.removeAll()
                for i in 0..<DetailViewController.stops.count {
                    stopRoutes.append((DetailViewController.stops[i]))
                }
                for i in 0..<DetailViewController.stops2.count {
                    stopRoutes.append((DetailViewController.stops2[i]))
                }
                
            }
            //print(stopRoutes)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // may add again later, deleted now because calling twice
        //configureView()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Table View
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return stopRoutes.count
    }
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cellular = tableView.dequeueReusableCellWithIdentifier("Scell", forIndexPath: indexPath)
        
        // Means we are clicking on a stop, not a route
        if detailBus?.route_id == "" {
            let route = stopRoutes[indexPath.row]
            Alamofire.request(.GET, "http://api.umd.io/v0/bus/routes/" + route + "/arrivals/" + detailBus!.stop_id)
                .responseJSON { response in
                    let json = JSON(response.result.value!)
                    // Checks if they are reporting a bus arrival at all
                    if json["predictions"]["direction"].count > 0 {
                        // Fails for STAMP still!! Says there are 8 different predictions but thats not true
                        // This checks if they are reporting more than one bus arrival
                        if json["predictions"]["direction"]["prediction"].count > 1 {
                            // temporary solution to handle Stamp case
                            if json["predictions"]["direction"]["prediction"].count == 8 {
                                let arrival = json["predictions"]["direction"]["prediction"]["minutes"].string!
                                cellular.textLabel!.text = route + " Ariving in: " + arrival + " minutes"
                            } else {
                                let arrival =  json["predictions"]["direction"]["prediction"][0]["minutes"].string!
                                cellular.textLabel!.text = route + " Ariving in: " + arrival + " minutes"
                            }
                        } else {
                            let arrival = json["predictions"]["direction"]["prediction"]["minutes"].string!
                            cellular.textLabel!.text = route + " Ariving in: " + arrival + " minutes"
                        }
                        // Checks if there is a message but not arrival time
                    } else if (json["predictions"]["message"].count > 0) {
                        cellular.textLabel!.text = route + " " + json["predictions"]["message"]["text"].string!
                    } else {
                        cellular.textLabel!.text = route + " Predictions: None"
                    }
            }
        // Means we're clicking to view a map
        } else if detailBus?.route_id == "map" {
            let route = stopRoutes[indexPath.row]
            print("I'm a map")
            print(route)
        } else {
            let stop = stopRoutes[indexPath.row]
            print("http://api.umd.io/v0/bus/routes/" + detailBus!.route_id + "/arrivals/" + stop)
            Alamofire.request(.GET, "http://api.umd.io/v0/bus/routes/" + detailBus!.route_id + "/arrivals/" + stop)
                .responseJSON { response in
                    //let json = JSON(response.result.value!)
                    // Does this otherwise stop list kept piling up, this makes you have to click the route twice to load data however -- FIX NEEDED --
                    DetailViewController.stops.removeAll()
                    DetailViewController.stops2.removeAll()
                    
                    Alamofire.request(.GET, "http://api.umd.io/v0/bus/stops/" + stop)
                        .responseJSON { response in
                            let json = JSON(response.result.value!)
                            let stop_name = json[0]["title"].string!
                    // Checks if they are reporting a bus arrival at all
                    if json["predictions"]["direction"].count > 0 {
                        // Fails for STAMP still!! Says there are 8 different predictions but thats not true
                        // This checks if they are reporting more than one bus arrival
                        if json["predictions"]["direction"]["prediction"].count > 1 {
                            // temporary solution to handle Stamp case
                            if json["predictions"]["direction"]["prediction"].count == 8 {
                                let arrival = json["predictions"]["direction"]["prediction"]["minutes"].string!
                                cellular.textLabel!.text = stop_name + " Ariving in: " + arrival + " minutes"
                            } else {
                                let arrival =  json["predictions"]["direction"]["prediction"][0]["minutes"].string!
                                cellular.textLabel!.text = stop_name + " Ariving in: " + arrival + " minutes"
                            }
                        } else {
                            let arrival = json["predictions"]["direction"]["prediction"]["minutes"].string!
                            cellular.textLabel!.text = stop_name + " Ariving in: " + arrival + " minutes"
                        }
                        // Checks if there is a message but not arrival time
                    } else if (json["predictions"]["message"].count > 0) {
                        cellular.textLabel!.text = stop_name + " " + json["predictions"]["message"]["text"].string!
                    } else {
                        cellular.textLabel!.text = stop_name + " -- : None"
                    }

                            
                    }// ALamofire request end
            }
        }
        return cellular
    }
    
    /*
    // MARK: - Segues
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "routeDetail" {
            if let indexPath = tableView.indexPathForSelectedRow {
                let bus: BusItem
                bus = busStops[indexPath.row]
                let controller = (segue.destinationViewController as! UINavigationController).topViewController as! DetailViewController
                controller.detailBus = bus
                controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem()
                controller.navigationItem.leftItemsSupplementBackButton = true
            }
        }
    }
 */
    
    
}
