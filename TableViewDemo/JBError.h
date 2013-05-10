//
//  JBError.h
//  TableViewDemo
//
//  Created by finucane on 5/1/13.
//

#import <Foundation/Foundation.h>

typedef enum JBErrorCode
{
  JBErrorTimeout,      //network congestion or worse
  JBErrorConnection,   //any obscure network error
  JBErrorDisconnected, //internet unreachable
  JBErrorHTTP,         //bad HTTP response code
  JBErrorJSON,         //malformed JSON
  JBErrorTwitter,      //twitter giving us an error
}JBErrorCode;

@interface JBError : NSError
+(JBError*)errorWithCode:(JBErrorCode)code description:(NSString*)description;
+(JBError*)errorWithCode:(JBErrorCode)code error:(NSError*)error;
@end