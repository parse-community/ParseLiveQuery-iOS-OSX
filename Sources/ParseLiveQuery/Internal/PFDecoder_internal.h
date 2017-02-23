//
//  PFDecoder_internal.h
//  ParseLiveQuery
//
//  Created by Florent Vilmart on 16-10-13.
//  Copyright © 2016 Parse. All rights reserved.
//

#ifndef PFDecoder_internal_h
#define PFDecoder_internal_h

#import <Foundation/Foundation.h>

@interface PFDecoder: NSObject
/**
 Globally available shared instance of PFDecoder.
 */
+ (nonnull PFDecoder *)objectDecoder;

/**
 Takes a complex object that was deserialized and converts encoded
 dictionaries into the proper Parse types. This is the inverse of
 encodeObject:allowUnsaved:allowObjects:seenObjects:.
 */
- (nullable id)decodeObject:(nullable id)object;
@end

#endif /* PFDecoder_internal_h */
