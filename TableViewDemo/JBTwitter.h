//
//  JBTwitter.h
//  TableViewDemo
//
//  Created by finucane on 5/1/13.
//

/*
 JBTwitter gets pages of tweets from the internet. getting tweets is asynchronous and happens in a block
 callback, where error is nonnil on error. errors can be anything involving the network, but also
 twitter specific errors, for instance exceeding the api usage cap.
 
 If a JBTwitter object is deallocated in the middle of fetching more data, the underlying network stuff
 is cancelled and no completion blocks are called.
 
 it is a programmer error to call loadWithCompletion or moreWithCompletion while a previous fetch of tweets
 is pending. it is also a programmer error to call moreWithCompletion when there are no more pages to fetch.
*/

#import <Foundation/Foundation.h>
#import "JBError.h"
#import "JBConnection.h"

typedef void (^JBTwitterCompletionBlock)(JBError*error);

@interface JBTwitter : NSObject
{
  @private
  NSMutableArray*tweets; //array of JBTweet objects
  NSString*url;
  NSString*nextUrl;
  JBConnection*connection;
  BOOL gotFirstPage;
  NSTimeInterval timeout;
}

@property (readonly) NSArray*tweets;

-(id)initWithURL:(NSString*)aUrl timeout:(NSTimeInterval)timeout;
-(void)loadWithCompletion:(JBTwitterCompletionBlock)block;
-(void)moreWithCompletion:(JBTwitterCompletionBlock)block;  //get next page
-(BOOL)moreTweets;
-(BOOL)busy;
-(void)removeTweetAtIndex:(NSUInteger)index;

@end


@interface JBTweet : NSObject
{
@private
  NSString*text;
  NSString*from;
}
-(id)initWithText:(NSString*)text from:(NSString*)from;
@property (readonly) NSString*text;
@property (readonly) NSString*from;
@end

