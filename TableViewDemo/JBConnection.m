//
//  JBConnection.m
//  TableViewDemo
//
//  Created by finucane on 5/1/13.
//

#import "JBConnection.h"
#import "insist.h"

@implementation JBConnection

#pragma mark - public methods

-(id)initWithURL:(NSString*)url timeout:(NSTimeInterval)timeout completion:(JBConnectionCompletionBlock)block
{
  insist (url && block);
  
  if ((self = [super init]))
  {
    /*this is to accumulate the received data into*/
    data = [[NSMutableData alloc] init];
    insist (data);
    
    /*save the completion block*/
    completion = [block copy];
    
    /*make an NSURLConnection which will start loading immediately*/
    NSURLRequest*request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]
                                            cachePolicy:NSURLRequestUseProtocolCachePolicy
                                        timeoutInterval:timeout];
    insist (request);
    connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    insist (connection);
  }
  return self;
}

/*cancel the connection. do not call the completion block*/
-(void)cancel
{
  insist (connection);
  [connection cancel];
}

-(void)dealloc
{
  [connection release];
  [data release];
  [completion release];
  [super dealloc];
}

#pragma mark - NSURLConnectionDelegate methods

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
  return nil;
  
}
- (void)connection:(NSURLConnection *)aConnection didReceiveResponse:(NSURLResponse *)aResponse
{
  insist (aConnection == connection);
  
  
  /*if there's an http response error, call the completion block*/
  NSHTTPURLResponse*response = (NSHTTPURLResponse*)aResponse;
  
  if (response.statusCode >= 400)
  {
    JBError*error = [JBError errorWithCode:JBErrorHTTP
                          description:[NSString stringWithFormat:@"status code %d, URL:%@", response.statusCode, response.URL.absoluteString]];
    insist (error);
    
    [connection cancel];
    completion (error, nil);
    return;
  }
  
  /*otherwise clear any data we might have accumulated*/
  [data setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)someData
{
  [data appendData:someData];
  
}
- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse
{
  /*allow redirects*/
  return request;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
  insist (completion);
  completion (nil, data);
}

/*translate timeouts and network down errors here, the rest pass up.*/
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)anError
{
  insist (self && anError);
    
  JBErrorCode code = JBErrorConnection;
  
  if (anError.domain == NSURLErrorDomain && anError.code == NSURLErrorTimedOut)
    code = JBErrorTimeout;
  else if (anError.domain == NSURLErrorDomain && anError.code == NSURLErrorNotConnectedToInternet)
    code = JBErrorDisconnected;
  
  JBError*error = [JBError errorWithCode:code error:anError];
  completion (error, nil);
}

@end
