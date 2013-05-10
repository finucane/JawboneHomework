//
//  insist.h
//  TableViewDemo
//
//  Created by finucane on 5/1/13.
//

/*
 all built-in assertion macros suck. they are either hard to use because they make you type out descriptions
 or it's never clear when they're turned on or off. this macro is simple to use and it includes
 the expression that fails in the exception, which is nice to have, along with filename and line number.
*/

#ifndef TableViewDemo_insist_h
#define TableViewDemo_insist_h

#define insist(e) if(!(e)) [NSException raise: @"assertion failed." format: @"%@:%d (%s)", [[NSString stringWithCString:__FILE__ encoding:NSUTF8StringEncoding] lastPathComponent], __LINE__, #e]

#endif
