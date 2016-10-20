import UIKit
import Alamofire
import SwiftyJSON

class MasterViewController: UITableViewController {
  
    var busStops = [BusItem]()
    var filteredStops = [BusItem]()
    
    var stops = [String]()
    var routes = [String]()
    var arrival = [String]()
    
    // Tells if user has signed in or not
    var login = false
    
  // MARK: - Properties
  var detailViewController: DetailViewController? = nil
  let searchController = UISearchController(searchResultsController: nil)
  
  // MARK: - View Setup
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Setup the Search Controller
    searchController.searchResultsUpdater = self
    searchController.searchBar.delegate = self
    definesPresentationContext = true
    searchController.dimsBackgroundDuringPresentation = false
    
    // Setup the Scope Bar
    if login == true {
        searchController.searchBar.scopeButtonTitles = ["All", "Route", "Stop", "Favorites"]
    } else {
        searchController.searchBar.scopeButtonTitles = ["All", "Route", "Stop"]
    }
    tableView.tableHeaderView = searchController.searchBar
    
    
    Alamofire.request(.GET, "http://api.umd.io/v0/bus/routes")
        .responseJSON { response in
            let json = JSON(response.result.value!)
            
            for i in 0..<json.count {
                
                let route_id = json[i]["route_id"].string!
                let title = json[i]["title"].string!
                // For the routes
                self.busStops += [BusItem(title: title, stop_id: "", route_id: route_id, category: "Route", routes: [])]
                
                // For the maps
                //self.busStops += [BusItem(title: title + " Map", stop_id: "", route_id: "map", category: "Map", routes: [])]
               
                Alamofire.request(.GET, "http://api.umd.io/v0/bus/routes/"+route_id)
                    .responseJSON { response in
                        let json = JSON(response.result.value!)
                        //let stops = json["stops"]
                        for i in 0..<json["stops"].count {
                            let stop_id = json["stops"][i]["stop_id"].string!
                            let stop_title = json["stops"][i]["title"].string!
                            
                            // For the Stops
                            if self.busStops.contains({$0.title == stop_title}) {
                                let position = self.busStops.indexOf({$0.title == stop_title})
                                self.busStops[position!].routes.append(route_id)
                            } else {
                                self.busStops += [BusItem(title: stop_title, stop_id: stop_id, route_id: "", category: "Stop", routes: [route_id])]
                            }

                            self.tableView.reloadData()
                        }
                }
                
            }
    }
    
    if let splitViewController = splitViewController {
      let controllers = splitViewController.viewControllers
      detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
    }
  }
  
  override func viewWillAppear(animated: Bool) {
    clearsSelectionOnViewWillAppear = splitViewController!.collapsed
    super.viewWillAppear(animated)
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }
  
  // MARK: - Table View
  override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    return 1
  }
  
  override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if searchController.active && searchController.searchBar.text != "" {
      return filteredStops.count
    }
    return busStops.count
  }
  
  override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
    let bus: BusItem
    if searchController.active && searchController.searchBar.text != "" {
      bus = filteredStops[indexPath.row]
    } else {
      bus = busStops[indexPath.row]
    }
    cell.textLabel!.text = bus.title
    cell.detailTextLabel!.text = bus.category
    return cell
  }
  
  func filterContentForSearchText(searchText: String, scope: String = "All") {
    filteredStops = busStops.filter({( bus : BusItem) -> Bool in
      let categoryMatch = (scope == "All") || (bus.category == scope)
      return categoryMatch && bus.title.lowercaseString.containsString(searchText.lowercaseString)
    })
    tableView.reloadData()
  }
  
  // MARK: - Segues
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if segue.identifier == "showDetail" {
      if let indexPath = tableView.indexPathForSelectedRow {
        let bus: BusItem
        if searchController.active && searchController.searchBar.text != "" {
          bus = filteredStops[indexPath.row]
        } else {
          bus = busStops[indexPath.row]
        }
        let controller = (segue.destinationViewController as! UINavigationController).topViewController as! DetailViewController
        controller.detailBus = bus
        controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem()
        controller.navigationItem.leftItemsSupplementBackButton = true
      }
    }
  }
  
}

extension MasterViewController: UISearchBarDelegate {
  // MARK: - UISearchBar Delegate
  func searchBar(searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
    filterContentForSearchText(searchBar.text!, scope: searchBar.scopeButtonTitles![selectedScope])
  }
}

extension MasterViewController: UISearchResultsUpdating {
  // MARK: - UISearchResultsUpdating Delegate
  func updateSearchResultsForSearchController(searchController: UISearchController) {
    let searchBar = searchController.searchBar
    let scope = searchBar.scopeButtonTitles![searchBar.selectedScopeButtonIndex]
    filterContentForSearchText(searchController.searchBar.text!, scope: scope)
  }
}