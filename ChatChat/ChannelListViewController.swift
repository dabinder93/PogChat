

import UIKit
import Firebase

enum Section: Int {
  case createNewChannelSection = 0
  case currentChannelsSection
}

class ChannelListViewController: UITableViewController {

  var senderDisplayName: String?
  var newChannelTextField: UITextField?
  
  private var channelRefHandle: FIRDatabaseHandle?
  private var channels: [Channel] = []
  
  private lazy var channelRef: FIRDatabaseReference = FIRDatabase.database().reference().child("channels")

  
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Channel List"
    observeChannels()
  }
  
  deinit {
    if let refHandle = channelRefHandle {
      channelRef.removeObserver(withHandle: refHandle)
    }
  }

  
  @IBAction func createChannel(_ sender: AnyObject) {
    if let name = newChannelTextField?.text {
      let newChannelRef = channelRef.childByAutoId()
      let channelItem = [
        "name": name
      ]
      newChannelRef.setValue(channelItem)
    }    
  }


  private func observeChannels() {

    channelRefHandle = channelRef.observe(.childAdded, with: { (snapshot) -> Void in
      let channelData = snapshot.value as! Dictionary<String, AnyObject>
      let id = snapshot.key
      if let name = channelData["name"] as! String!, name.characters.count > 0 {
        self.channels.append(Channel(id: id, name: name))
        self.tableView.reloadData()
      } else {
        print("Error! Could not decode channel data")
      }
    })
  }
  
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    super.prepare(for: segue, sender: sender)
    
    if let channel = sender as? Channel {
      let chatVc = segue.destination as! ChatViewController
      
      chatVc.senderDisplayName = senderDisplayName
      chatVc.channel = channel
      chatVc.channelRef = channelRef.child(channel.id)
    }
  }

  
  override func numberOfSections(in tableView: UITableView) -> Int {
    return 2
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if let currentSection: Section = Section(rawValue: section) {
      switch currentSection {
      case .createNewChannelSection:
        return 1
      case .currentChannelsSection:
        return channels.count
      }
    } else {
      return 0
    }
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let reuseIdentifier = (indexPath as NSIndexPath).section == Section.createNewChannelSection.rawValue ? "NewChannel" : "ExistingChannel"
    let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)

    if (indexPath as NSIndexPath).section == Section.createNewChannelSection.rawValue {
      if let createNewChannelCell = cell as? CreateChannelCell {
        newChannelTextField = createNewChannelCell.newChannelNameField
      }
    } else if (indexPath as NSIndexPath).section == Section.currentChannelsSection.rawValue {
      cell.textLabel?.text = channels[(indexPath as NSIndexPath).row].name
    }
    
    return cell
  }

  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    if (indexPath as NSIndexPath).section == Section.currentChannelsSection.rawValue {
      let channel = channels[(indexPath as NSIndexPath).row]
      self.performSegue(withIdentifier: "ShowChannel", sender: channel)
    }
  }
  
}
