//
//  ViewController.h
//  TableViewDemo
//
//  Created by finucane on 5/1/13.

#import <UIKit/UIKit.h>
#import "JBTwitter.h"
#import "MBProgressHUD.h"

@interface ViewController : UITableViewController
{
  @private
  JBTwitter*twitter;
}
@end


@interface TableViewDemoCell : UITableViewCell
@property (nonatomic, retain) IBOutlet UILabel*textLabel;
@property (nonatomic, retain) IBOutlet UILabel*fromLabel;
@end