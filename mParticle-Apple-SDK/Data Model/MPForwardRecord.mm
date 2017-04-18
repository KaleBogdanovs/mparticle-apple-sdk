//
//  MPForwardRecord.mm
//
//  Copyright 2016 mParticle, Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "MPForwardRecord.h"
#include "EventTypeName.h"
#include "MessageTypeName.h"
#import "MPCommerceEvent.h"
#import "MPCommerceEvent+Dictionary.h"
#import "MPEvent.h"
#import "MPEventProjection.h"
#import "MPIConstants.h"
#import "MPILogger.h"
#import "MPKitExecStatus.h"
#import "MPKitFilter.h"
#import "NSString+MPUtils.h"

NSString *const kMPFRModuleId = @"mid";
NSString *const kMPFRProjections = @"proj";
NSString *const kMPFRProjectionId = @"pid";
NSString *const kMPFRProjectionName = @"name";
NSString *const kMPFRPushRegistrationState = @"r";
NSString *const kMPFROptOutState = @"s";

using namespace mParticle;

@implementation MPForwardRecord

- (instancetype)initWithId:(int64_t)forwardRecordId data:(NSData *)data {
    self = [super init];
    if (self) {
        _forwardRecordId = forwardRecordId;
        
        if (!MPIsNull(data)) {
            NSError *error = nil;
            NSDictionary *jsonDictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
            
            if (!error) {
                _dataDictionary = [NSMutableDictionary dictionaryWithDictionary:jsonDictionary];
            } else {
                MPILogError(@"Error deserializing the data into a dictionary representation: %@", [error localizedDescription]);
            }
        }
    }
    
    return self;
}

- (instancetype)initWithMessageType:(MPMessageType)messageType execStatus:(MPKitExecStatus *)execStatus {
    return [self initWithMessageType:messageType execStatus:execStatus kitFilter:nil originalEvent:nil];
}

- (instancetype)initWithMessageType:(MPMessageType)messageType execStatus:(MPKitExecStatus *)execStatus stateFlag:(BOOL)stateFlag {
    self = [self initWithMessageType:messageType execStatus:execStatus kitFilter:nil originalEvent:nil];
    
    if (messageType == MPMessageTypePushRegistration) {
        _dataDictionary[kMPFRPushRegistrationState] = @(stateFlag);
    } else if (messageType == MPMessageTypeOptOut) {
        _dataDictionary[kMPFROptOutState] = @(stateFlag);
    }
    
    return self;
}

- (instancetype)initWithMessageType:(MPMessageType)messageType execStatus:(MPKitExecStatus *)execStatus kitFilter:(MPKitFilter *)kitFilter originalEvent:(MPEventAbstract *)originalEvent {
    self = [super init];
    
    BOOL validMessageType = messageType > MPMessageTypeUnknown && messageType <= MPMessageTypeCommerceEvent;
    NSAssert(validMessageType, @"The 'messageType' variable is not valid.");
    
    BOOL validExecStatus = !MPIsNull(execStatus) && [execStatus isKindOfClass:[MPKitExecStatus class]];
    NSAssert(validExecStatus, @"The 'execStatus' variable is not valid.");
    
    BOOL validKitFilter = MPIsNull(kitFilter) || [kitFilter isKindOfClass:[MPKitFilter class]];
    NSAssert(validKitFilter, @"The 'kitFilter' variable is not valid.");
    
    BOOL validOriginalEvent = MPIsNull(originalEvent) || [originalEvent isKindOfClass:[MPEventAbstract class]];
    NSAssert(validOriginalEvent, @"The 'originalEvent' variable is not valid.");
    
    if (!self || !validMessageType || !validExecStatus || !validKitFilter || !validOriginalEvent) {
        return nil;
    }
    
    _forwardRecordId = 0;
    _dataDictionary = [[NSMutableDictionary alloc] init];
    _dataDictionary[kMPFRModuleId] = execStatus.kitCode;
    _dataDictionary[kMPTimestampKey] = MPCurrentEpochInMilliseconds;
    _dataDictionary[kMPMessageTypeKey] = [NSString stringWithCPPString:MessageTypeName::nameForMessageType(static_cast<MessageType>(messageType))];

    if (!kitFilter) {
        return self;
    }
    
    if (originalEvent && (kitFilter.forwardEvent || kitFilter.forwardCommerceEvent)) {
        if (originalEvent.kind == MPEventKindAppEvent) {
            _dataDictionary[kMPEventNameKey] = ((MPEvent *)originalEvent).name;
        }
        
        if (eventTypeString) {
            _dataDictionary[kMPEventTypeKey] = eventTypeString;
        }
    }
    if ([originalEvent isKindOfClass:[MPEvent class]] && (messageType == MPMessageTypeScreenView || messageType == MPMessageTypeEvent)) {
        _dataDictionary[kMPEventNameKey] = ((MPEvent *)originalEvent).name;
    }
    
    if (kitFilter.appliedProjections.count > 0) {
        NSMutableArray *projections = [[NSMutableArray alloc] initWithCapacity:kitFilter.appliedProjections.count];
        NSMutableDictionary *projectionDictionary;
        
        for (MPEventProjection *eventProjection in kitFilter.appliedProjections) {
            projectionDictionary = [[NSMutableDictionary alloc] initWithCapacity:4];
            projectionDictionary[kMPFRProjectionId] = @(eventProjection.projectionId);
            projectionDictionary[kMPMessageTypeKey] = [NSString stringWithCPPString:MessageTypeName::nameForMessageType(static_cast<MessageType>(eventProjection.messageType))];
            
            projectionDictionary[kMPEventTypeKey] = [NSString stringWithCPPString:EventTypeName::nameForEventType(static_cast<EventType>(eventProjection.eventType))];
            
            if (eventProjection.projectedName) {
                projectionDictionary[kMPFRProjectionName] = eventProjection.projectedName;
            }
            
            [projections addObject:projectionDictionary];
        }
        
        _dataDictionary[kMPFRProjections] = projections;
    }

    return self;
}

- (BOOL)isEqual:(id)object {
    if (MPIsNull(object) || ![object isKindOfClass:[MPForwardRecord class]]) {
        return NO;
    }
    
    MPForwardRecord *objectForwardRecord = (MPForwardRecord *)object;
    
    BOOL isEqual = [_dataDictionary isEqualToDictionary:objectForwardRecord.dataDictionary];
    
    if (isEqual && _forwardRecordId > 0 && objectForwardRecord.forwardRecordId > 0) {
        isEqual = _forwardRecordId == objectForwardRecord.forwardRecordId;
    }
    
    return isEqual;
}

#pragma mark Public methods
- (NSData *)dataRepresentation {
    if (MPIsNull(_dataDictionary) || ![_dataDictionary isKindOfClass:[NSDictionary class]]) {
        MPILogWarning(@"Invalid Data dictionary.");
        return nil;
    }
    
    NSData *data = nil;
    
    @try {
        NSError *error = nil;
        data = [NSJSONSerialization dataWithJSONObject:_dataDictionary options:0 error:&error];
        
        if (error) {
            MPILogError(@"Error serializing the dictionary into a data representation: %@", [error localizedDescription]);
        }
    } @catch (NSException *exception) {
        MPILogError(@"Exception serializing the dictionary into a data representation: %@", [exception reason]);
    }
    
    return data;
}

@end
