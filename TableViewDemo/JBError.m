//
//  JBError.m
//  TableViewDemo
//
//  Created by finucane on 5/1/13.
//

#import "JBError.h"
#import "insist.h"

/*more or less boilerplate stuff to implement a custom NSError*/
@implementation JBError

NSString*const kJBErrorDomain = @"JBErrorDomain";

+(JBError*)errorWithCode:(JBErrorCode)code description:(NSString*)description
{
  return [JBError errorWithDomain:kJBErrorDomain code:code userInfo:@{NSLocalizedDescriptionKey:description}];
}
+(JBError*)errorWithCode:(JBErrorCode)code error:(NSError*)error
{
  return [JBError errorWithDomain:kJBErrorDomain code:code userInfo:error.userInfo];
}
-(NSString*)stringForCode:(JBErrorCode)code
{
  switch (code)
  {
    case JBErrorConnection: return @"Connection";
    case JBErrorDisconnected: return @"Network Down";
    case JBErrorTimeout: return @"Timeout";
    case JBErrorHTTP: return @"HTTP";
    case JBErrorTwitter: return @"Twitter";
    default:insist (0);
  }
  return @"";
}
-(NSString*)localizedDescription
{
  return [NSString stringWithFormat:@"JBError \"%@\" %@", [self stringForCode:self.code], self.userInfo];
}
@end
