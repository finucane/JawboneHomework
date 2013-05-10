//
//  JBTwitter.m
//  TableViewDemo
//
//  Created by finucane on 5/1/13.
//


#import "JBTwitter.h"
#import "insist.h"

#define kTwitterMessageKey    @"text"            // JSON dict key for message
#define kTwitterNameKey       @"from_user_name"  // JSON dict key for user name
#define kTwitterErrorKey      @"error"
#define kTwitterNextPageKey   @"next_page"
#define kTwitterResultsKey    @"results"

@implementation JBTwitter

@synthesize tweets = tweets;

-(id)initWithURL:(NSString*)aUrl timeout:(NSTimeInterval)aTimeout
{
  insist (aUrl && aUrl.length);
  if ((self = [super init]))
  {
    url = [aUrl retain];
    tweets = [[NSMutableArray alloc] init];
    timeout = aTimeout;
    nextUrl = nil;
    gotFirstPage = NO; //to know if we should clear the tweets array or not on completion
  }
  return self;
}

-(void)dealloc
{
  //can be nil
  [connection cancel];
  [connection release];
  [nextUrl release];
  [url release];
  [tweets release];
  [super dealloc];
}

/*return YES if there are more pages to fetch*/
-(BOOL)moreTweets
{
  return nextUrl != nil;
}

-(void)removeTweetAtIndex:(NSUInteger)index
{
  insist (tweets && index < tweets.count);
  [tweets removeObjectAtIndex:index];
}

/*fetch the first page*/
-(void)loadWithCompletion:(JBTwitterCompletionBlock)block
{
  gotFirstPage = NO;
  
  /*fetch tweets*/
  [self loadWithURL:url completion:block];
}

/*fetch the next page*/
-(void)moreWithCompletion:(JBTwitterCompletionBlock)completion
{
  insist (nextUrl);
  [self loadWithURL:nextUrl completion:completion];
}

#pragma mark - private methods

/*this parses the data from the network response and adds tweets to our tweets array*/
-(void)gotData:(NSData*)data withError:(JBError*)error completion:(JBTwitterCompletionBlock)completion
{
  /*don't do any error handling on network errors (for instance retrying on a timeout), just report it*/
  if (error)
  {
    completion (error);
    return;
  }
  
  insist (data);
  
  /*get a dictionary from the JSON data*/
  NSError*jError = nil;
  NSDictionary*dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jError];
  
  /*handle JSON parse error*/
  if (!dict)
  {
    insist (jError);
    completion ([JBError errorWithCode:JBErrorJSON error:jError]);
    return;
  }
  
  /*handle twitter not giving us the structure we expect*/
  if (!([dict isKindOfClass:[NSDictionary class]]))
  {
    completion ([JBError errorWithCode:JBErrorJSON description:@"Expected dictionary."]);
    return;
  }
  
  /*handle twitter error*/
  NSString*s = [dict objectForKey:kTwitterErrorKey];
  if (s)
  {
    completion ([JBError errorWithCode:JBErrorTwitter description:s]);
    return;
  }
  
  /*grab the next page, if any, the field isn't a full url, just the non-base part, so build it from the first page url*/
  [nextUrl release];
  nextUrl = nil;
  
  NSString*nextPage = [dict objectForKey:kTwitterNextPageKey];
  if (nextPage)
  {
    NSRange r = [url rangeOfString:@"?"];
    insist (r.location != NSNotFound);
    nextUrl = [[NSString stringWithFormat:@"%@%@", [url substringToIndex:r.location], nextPage] retain];
  }

  /*if we are reloading, get rid of any old data*/
  if (gotFirstPage == NO)
    [tweets removeAllObjects];
  
  /*no matter what further errors me might encounter, we have got the first page*/
  gotFirstPage = YES;
  
  /*go through the results and add the tweets to our array. on any error the state of
   the tweets array is undefined, the caller can reload all the data or whatever.
   */
  
 
  NSArray*results = [dict objectForKey:kTwitterResultsKey];
  
  /*handle twitter not giving us the structure we expect*/
  if (!results && ([results isKindOfClass:[NSArray class]]))
  {
    completion ([JBError errorWithCode:JBErrorJSON description:@"Expected results to be an array."]);
    return;
  }
  
  /*twitter does give us [] to mean no results but allow nil too*/
  if (!results)
  {
    completion (nil);
    return;
  }
  
  /*go through the results array and add tweets to our list*/
  for (NSDictionary*item in results)
  {
    if (![item isKindOfClass:[NSDictionary class]])
    {
      completion ([JBError errorWithCode:JBErrorJSON description:@"Expected results array to contain dictionaries."]);
      return;
    }
    NSString*text = [item objectForKey:kTwitterMessageKey];
    if (!text)
    {
      completion ([JBError errorWithCode:JBErrorJSON description:@"Missing twitter text entry."]);
      return;
    }
    NSString*from = [item objectForKey:kTwitterNameKey];
    if (!from)
    {
      completion ([JBError errorWithCode:JBErrorJSON description:@"Missing twitter from name entry."]);
      return;
    }
    
    /*make a new tweet and add it to the list*/
    [tweets addObject:[[[JBTweet alloc] initWithText:text from:from] autorelease]];
  }
  completion (nil);
}

-(void)loadWithURL:(NSString*)aURL completion:(JBTwitterCompletionBlock)completion
{
  insist (!connection);
  connection = nil;

  /*fire off the http request. the closure keeps the completion parameter for when it's needed.*/
  connection = [[JBConnection alloc] initWithURL:aURL timeout:timeout completion:^(JBError*error, NSData*data)
                {
                  [self gotData:data withError:error completion:completion];
                  [connection release];
                  connection = nil;
                }];
  insist (connection);
}

-(BOOL)busy
{
  return connection != nil;
}

@end

@implementation JBTweet
@synthesize text=text, from=from;

-(id)initWithText:(NSString*)aText from:(NSString*)aFrom
{
  insist (aText && aFrom);
  if (self = [super init])
  {
    text = [aText retain];
    from = [aFrom retain];
  }
  return self;
}

-(void)dealloc
{
  [text release];
  [from release];
  [super dealloc];
}

@end
