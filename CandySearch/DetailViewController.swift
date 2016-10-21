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
                for i in 0..<DetailViewController.stops.count {
                    stopRoutes.append((DetailViewController.stops[i]))
                }
                for i in 0..<DetailViewController.stops2.count {
                    stopRoutes.append((DetailViewController.stops2[i]))
                }
                
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // - Table View Functions
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    // Returns the number of stops
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return stopRoutes.count
    }
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        // Gets particular cell being clicked on in table
        let cellular = tableView.dequeueReusableCellWithIdentifier("Scell", forIndexPath: indexPath)
        
        // Means we are clicking on a stop, not a route
        if detailBus?.route_id == "" {
            let route = stopRoutes[indexPath.row]
            Alamofire.request(.GET, "http://api.umd.io/v0/bus/routes/" + route + "/arrivals/" + detailBus!.stop_id)
                .responseJSON { response in
                    let json = JSON(response.result.value!)
                    // Checks if they are reporting a bus arrival at all
                    if json["predictions"]["direction"].count > 0 {
                        // If there is more than one arrival, only print the first one
                        if json["predictions"]["direction"]["prediction"].count > 1 {
                            // Checking in the Stamp case which is behaving incorrectly
                            if json["predictions"]["direction"]["prediction"].count == 8 {
                                let arrival = json["predictions"]["direction"]["prediction"]["minutes"].string!
                                cellular.textLabel!.text = route + " Ariving in: " + arrival + " minutes"
                            } else {
                                let arrival =  json["predictions"]["direction"]["prediction"][0]["minutes"].string!
                                cellular.textLabel!.text = route + " Ariving in: " + arrival + " minutes"
                            }
                        // If only one arrival predicted, print it
                        } else {
                            let arrival = json["predictions"]["direction"]["prediction"]["minutes"].string!
                            cellular.textLabel!.text = route + " Ariving in: " + arrival + " minutes"
                        }
                        // Checks if there is a message but not arrival time
                    } else if (json["predictions"]["message"].count > 0) {
                        cellular.textLabel!.text = route + " " + json["predictions"]["message"]["text"].string!
                    // Otherwise no arrival time is given for that bus
                    } else {
                        cellular.textLabel!.text = route + " Predictions: None"
                    }
            }
        // Means we have clicked on a bus route
        } else {
            let stop = stopRoutes[indexPath.row]
            print("http://api.umd.io/v0/bus/routes/" + detailBus!.route_id + "/arrivals/" + stop)
            // Gets arrival time for the stops on the route
            Alamofire.request(.GET, "http://api.umd.io/v0/bus/routes/" + detailBus!.route_id + "/arrivals/" + stop)
                .responseJSON { response in
                    let json_route = JSON(response.result.value!)
                    // Prevents stop list from piling up
                    DetailViewController.stops.removeAll()
                    DetailViewController.stops2.removeAll()
                    
                    Alamofire.request(.GET, "http://api.umd.io/v0/bus/stops/" + stop)
                        .responseJSON { response in
                            let json = JSON(response.result.value!)
                            let stop_name = json[0]["title"].string!
                    // Checks if they are reporting a bus arrival at all
                    print(json_route["predictions"]["direction"])
                    if json_route["predictions"]["direction"].count > 0 {
                        // This checks if they are reporting more than one bus arrival
                        if json_route["predictions"]["direction"]["prediction"].count > 1 {
                            // temporary solution to handle Stamp case
                            if json_route["predictions"]["direction"]["prediction"].count == 8 {
                                let arrival = json_route["predictions"]["direction"]["prediction"]["minutes"].string!
                                cellular.textLabel!.text = stop_name + " Ariving in: " + arrival + " minutes"
                            } else {
                                let arrival =  json_route["predictions"]["direction"]["prediction"][0]["minutes"].string!
                                cellular.textLabel!.text = stop_name + " Ariving in: " + arrival + " minutes"
                            }
                        // Otherwise there is only one arrival for the stop
                        } else {
                            let arrival = json_route["predictions"]["direction"]["prediction"]["minutes"].string!
                            cellular.textLabel!.text = stop_name + " Ariving in: " + arrival + " minutes"
                        }
                        // Checks if there is a message but not arrival time
                    } else if (json_route["predictions"]["message"].count > 0) {
                        cellular.textLabel!.text = stop_name + " " + json_route["predictions"]["message"]["text"].string!
                    // Otherwise there is no predicted arrival
                    } else {
                        cellular.textLabel!.text = stop_name + " -- : None"
                    }

                            
                    }
            }
        }
        return cellular
    }
    
}
