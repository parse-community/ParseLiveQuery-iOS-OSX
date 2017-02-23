//
//  PFEncoder_internal.h
//  ParseLiveQuery
//
//  Created by Joe Szymanski on 11/28/16.
//  Copyright © 2016 Parse. All rights reserved.
//

#ifndef PFEncoder_internal_h
#define PFEncoder_internal_h

#import <Foundation/Foundation.h>
#import <Parse/PFObject.h>

@interface PFEncoder : NSObject

+ (nonnull instancetype)objectEncoder;

- (nullable id)encodeObject:(nullable id)object;
- (nullable id)encodeParseObject:(nullable PFObject *)object;

@end

/**
 Encoding strategy that rejects PFObject.
 */
@interface PFNoObjectEncoder : PFEncoder

@end

/**
 Encoding strategy that encodes PFObject to PFPointer with objectId or with localId.
 */
@interface PFPointerOrLocalIdObjectEncoder : PFEncoder

@end

/**
 Encoding strategy that encodes PFObject to PFPointer with objectId and rejects
 unsaved PFObject.
 */
@interface PFPointerObjectEncoder : PFPointerOrLocalIdObjectEncoder

@end

#endif /* PFEncoder_internal_h */
