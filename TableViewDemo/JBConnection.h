//
//  JBConnection.h
//  TableViewDemo
//
//  Created by finucane on 5/1/13.
//

/*
 JBConnection is a wrapper around NSURLConnection that deals with the NSURLConnectionDelegate stuff, allows
 a settable timeout, implements cancel, reports errors, and uses a block for completion.
*/

#import <Foundation/Foundation.h>
#import "JBError.h"

/*if there's an error then error is nonnil otherwise the data from the network is in data*/
typedef void (^JBConnectionCompletionBlock)(JBError*error, NSData*data);

@interface JBConnection : NSObject <NSURLConnectionDelegate>
{
  @private
  NSURLConnection*connection;
  NSMutableData*data;
  JBConnectionCompletionBlock completion;
}
-(id)initWithURL:(NSString*)url timeout:(NSTimeInterval)timeout completion:(JBConnectionCompletionBlock)block;
-(void)cancel;
@end
