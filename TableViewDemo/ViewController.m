//
//  ViewController.m
//  TableViewDemo
//
//  Created by finucane on 5/1/13.

#import "ViewController.h"
#import "MBProgressHUD.h"
#import "insist.h"

#define kCellPadding            5                               // border and padding for table cell elements
#define kServerURL              @"http://search.twitter.com/search.json?q=%23jambox"    // content URL
#define kReuseIdentifier        @"TableViewDemoCell"            // table cell reuse identifier
#define kMessageLabelFont       [UIFont systemFontOfSize:17]    // message label font+color (height depends on content)
#define kMessageLabelTextColor  [UIColor blackColor]
#define kNameLabelFont          [UIFont systemFontOfSize:14]    // name label font+color+height
#define kNameLabelTextColor     [UIColor grayColor]
#define kFromFormatString       @"- %@"
#define kAnimateHud YES
#define kTimeoutSeconds       60
#define kCellSlop 20
#define kPaddingSlop 2
#define kInfiniteOverscrollDistance 100 //how far down the user has to scroll to trigger more tweets
#define kErrorTitle @"Error"
#define kInfoTitle @"Info"
#define kNetworkDownTitle @"Cannot Load Tweets"
#define kNetworkDownMessage @"TableViewDemo cannot load tweets because it is not connected to the internet."

@implementation ViewController
-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
  if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]))
  {
    /*make a tweets object to fetch tweets with*/
    twitter = [[JBTwitter alloc] initWithURL:kServerURL timeout:kTimeoutSeconds];
    insist (twitter);
  }
  return self;
}

-(void)dealloc
{
  [twitter release];
  [super dealloc];
}

- (void)viewDidLoad
{
  /*tell the tableview to get cells from a xib*/
  UINib*nib = [UINib nibWithNibName:@"TableViewDemoCell" bundle:nil];
  insist (nib);
  [self.tableView registerNib:nib forCellReuseIdentifier:kReuseIdentifier];
  
  if ([self respondsToSelector:@selector(setRefreshControl:)])
  {
    /*if the running iOS version supports it, set up the pull to refresh control*/
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
  }
  /*do the initial load*/
  [self refresh:nil];
  [super viewDidLoad];
}

#pragma mark - private methods

/*report errors*/
-(void)report:(JBError*)error
{
  insist (error);
  
  /*if it's a network disconnected error, or a timeout, present a nice message. in the case of timeout
    we might want to retry but for this demo just lie and say not connected to internet or some such lie*/
  
  NSString*title = kErrorTitle;
  NSString*message = error.description;
  if (error.code == JBErrorDisconnected || error.code == JBErrorTimeout)
  {
    title = kNetworkDownTitle;
    message = kNetworkDownMessage;
  }
  
  UIAlertView*alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
  insist (alert);
  [alert show];
}

/*this is the UIRefresher callback but we also call it directly to do the initial load, in that case sender is nil*/
-(void)refresh:(id)sender
{
  insist (twitter);
  
  if (twitter.busy)
    return;
  
  /*load the first page, when it's done reload the table*/
  [twitter loadWithCompletion:^(JBError*error)
   {
     /*on any completion, hide the hud activity indicator*/
     [MBProgressHUD hideHUDForView:self.view animated:kAnimateHud];
     
     if (sender)
       [self.refreshControl endRefreshing];

     if (error)
     {
       [self report:error];
       return;
     }
     [self.tableView reloadData];
   }];
  
  /*we are starting a network operation so show the hud activity indicator (which locks out user events too)*/
  [MBProgressHUD showHUDAddedTo:self.view animated:kAnimateHud];
}

/*fetch more tweets, if any*/
-(void)more
{
  insist (twitter);
  
  /*don't try fetching more if there aren't any more pages*/
  if (!twitter.moreTweets)
    return;
  
  if (twitter.busy)
    return;
  
  [twitter moreWithCompletion:^(JBError*error)
   {
     /*on any completion, hide the hud activity indicator*/
     [MBProgressHUD hideHUDForView:self.view animated:kAnimateHud];
     if (error)
     {
       [self report:error];
       return;
     }
     [self.tableView reloadData];
   }];
  
  /*we are starting a network operation so show the hud activity indicator (which locks out user events too)*/
  [MBProgressHUD showHUDAddedTo:self.view animated:kAnimateHud];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  insist (tableView == self.tableView);
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  insist (section == 0);
  insist (twitter && twitter.tweets);
  insist (tableView == self.tableView);
  return [twitter.tweets count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  insist (tableView == self.tableView);
  insist (twitter && twitter.tweets);
  insist (indexPath.row < twitter.tweets.count);
  
  NSUInteger row = indexPath.row;
  
  /*get tweet for row*/
  JBTweet*tweet = [twitter.tweets objectAtIndex:row];
  
  TableViewDemoCell*cell = [tableView dequeueReusableCellWithIdentifier:kReuseIdentifier];
  
  insist (cell);
  cell.contentView.backgroundColor = row % 2 ? [UIColor whiteColor] : [UIColor lightGrayColor];
  cell.backgroundColor = cell.contentView.backgroundColor;
  
  cell.textLabel.numberOfLines = 0;
  cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
  cell.textLabel.text = tweet.text;
  cell.fromLabel.text = [NSString stringWithFormat:kFromFormatString, tweet.from];

  return cell;
}

/*make sure the background behind delete buttons is not white*/
-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
  cell.backgroundColor = cell.contentView.backgroundColor;
}
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
  return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
  if (editingStyle == UITableViewCellEditingStyleDelete)
  {
    /*remove row from the twitter list*/
    [twitter removeTweetAtIndex:indexPath.row];
    
    // Delete the row from the data source
    //[tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    
    /*call reloadData to re-establish the alternating background colors*/
    [self.tableView reloadData];
  }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
  insist (tableView == self.tableView);
  insist (twitter && twitter.tweets);
  insist (indexPath.row < twitter.tweets.count);
  
  /*get tweet for row*/
  JBTweet*tweet = [twitter.tweets objectAtIndex:indexPath.row];
  
  CGSize textSize = [tweet.text sizeWithFont:kMessageLabelFont
                           constrainedToSize:CGSizeMake (tableView.frame.size.width - 10, MAXFLOAT)
                               lineBreakMode:NSLineBreakByWordWrapping];
  
  CGSize fromSize = [tweet.from sizeWithFont:kNameLabelFont
                                    forWidth:self.view.frame.size.width - kCellPadding * kPaddingSlop
                               lineBreakMode:NSLineBreakByWordWrapping];
  
  CGFloat height = textSize.height + kPaddingSlop * kCellPadding + fromSize.height + kPaddingSlop * kCellPadding + kCellSlop;
  
  TableViewDemoCell*cell = (TableViewDemoCell*)[self tableView:tableView cellForRowAtIndexPath:indexPath];

  CGRect bounds = cell.bounds;
  bounds.size.height = height;
  cell.bounds = bounds;

  return height;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  insist (tableView == self.tableView);
  insist (twitter && twitter.tweets);
  insist (indexPath && indexPath.row < twitter.tweets.count);
  
  /*get the selected tweet and throw its text into an alert*/
  JBTweet*tweet = [twitter.tweets objectAtIndex:indexPath.row];
  UIAlertView*alert = [[UIAlertView alloc] initWithTitle:kInfoTitle message:tweet.text delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
  insist (alert);
  [alert show];
}

#pragma mark - UIScrollView delegate methods

/*if we have scrolled past the end of the content, trigger loading more tweets*/
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
  /*scrollViewDidScroll can be called as a side effect of doing a pull to refresh, inside the refreshDidEnd. make sure that doesn't trigger loading more tweets.*/
  if (twitter.busy)
    return;
  
  CGFloat actualPosition = scrollView.contentOffset.y;
  CGFloat contentHeight = scrollView.contentSize.height;
  
  if (actualPosition >= contentHeight - scrollView.frame.size.height + kInfiniteOverscrollDistance)
    [self more];
}

@end


@implementation TableViewDemoCell

@synthesize textLabel, fromLabel;
-(void)dealloc
{
  textLabel = nil;
  fromLabel = nil;
  [super dealloc];
}

@end


