//
//  MPPersistenceController.h
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

#import <Foundation/Foundation.h>
#import "MParticleUserNotification.h"
#import "sqlite3.h"

@class MPBreadcrumb;
@class MPCookie;
@class MPConsumerInfo;
@class MPForwardRecord;
@class MPIntegrationAttributes;
@class MPMessage;
@class MPProductBag;
@class MPSegment;
@class MPSession;
@class MPUpload;

#if TARGET_OS_IOS == 1
    @class MParticleUserNotification;
#endif

typedef NS_ENUM(NSUInteger, MPPersistenceOperation) {
    MPPersistenceOperationDelete = 0,
    MPPersistenceOperationFlag
};

@interface MPPersistenceController : NSObject {
@protected
    sqlite3 *mParticleDB;
    dispatch_queue_t dbQueue;
}

@property (nonatomic, readonly, getter = isDatabaseOpen) BOOL databaseOpen;

+ (nonnull instancetype)sharedInstance;
- (nullable MPSession *)archiveSession:(nonnull MPSession *)session;
- (BOOL)closeDatabase;
- (NSUInteger)countMesssagesForUploadInSession:(nonnull MPSession *)session;
- (void)deleteConsumerInfo;
- (void)deleteCookie:(nonnull MPCookie *)cookie;
- (void)deleteForwardRecordsIds:(nonnull NSArray<NSNumber *> *)forwardRecordsIds;
- (void)deleteAllIntegrationAttributes;
- (void)deleteIntegrationAttributesForKitCode:(nonnull NSNumber *)kitCode;
- (void)deleteMessages:(nonnull NSArray<MPMessage *> *)messages;
- (void)deleteNetworkPerformanceMessages;
- (void)deletePreviousSession;
- (void)deleteProductBag:(nonnull MPProductBag *)productBag;
- (void)deleteRecordsOlderThan:(NSTimeInterval)timestamp;
- (void)deleteSegments;
- (void)deleteSession:(nonnull MPSession *)session;
- (void)deleteUpload:(nonnull MPUpload *)upload;
- (void)deleteUploadId:(int64_t)uploadId;
- (nullable NSArray<MPBreadcrumb *> *)fetchBreadcrumbs;
- (nullable MPConsumerInfo *)fetchConsumerInfo;
- (nullable NSArray<MPCookie *> *)fetchCookies;
- (nullable NSArray<MPForwardRecord *> *)fetchForwardRecords;
- (nullable NSArray<MPIntegrationAttributes *> *)fetchIntegrationAttributes;
- (nullable NSArray<MPMessage *> *)fetchMessagesInSession:(nonnull MPSession *)session;
- (nullable NSArray<MPMessage *> *)fetchMessagesForUploadingInSession:(nonnull MPSession *)session;
- (nullable MPSession *)fetchNullSession;
- (nullable NSArray<MPSession *> *)fetchPossibleSessionsFromCrash;
- (void)fetchPreviousSession:(void (^ _Nonnull)(MPSession * _Nullable previousSession))completionHandler;
- (nullable MPSession *)fetchPreviousSessionSync;
- (nullable NSArray<MPProductBag *> *)fetchProductBags;
- (nullable NSArray<MPSegment *> *)fetchSegments;
- (nullable MPMessage *)fetchSessionEndMessageInSession:(nonnull MPSession *)session;
- (void)fetchSessions:(void (^ _Nonnull)(NSMutableArray<MPSession *> * _Nullable sessions))completionHandler;
- (void)fetchUploadedMessagesInSession:(nonnull MPSession *)session excludeNetworkPerformanceMessages:(BOOL)excludeNetworkPerformance completionHandler:(void (^ _Nonnull)(NSArray<MPMessage *> * _Nullable messages))completionHandler;
- (void)fetchUploadsExceptInSession:(nonnull MPSession *)session completionHandler:(void (^ _Nonnull)(NSArray<MPUpload *> * _Nullable uploads))completionHandler;
- (nullable NSArray<MPUpload *> *)fetchUploadsInSession:(nonnull MPSession *)session;
- (void)purgeMemory;
- (BOOL)openDatabase;
- (void)saveBreadcrumb:(nonnull MPMessage *)message session:(nonnull MPSession *)session;
- (void)saveConsumerInfo:(nonnull MPConsumerInfo *)consumerInfo;
- (void)saveForwardRecord:(nonnull MPForwardRecord *)forwardRecord;
- (void)saveIntegrationAttributes:(nonnull MPIntegrationAttributes *)integrationAttributes;
- (void)saveMessage:(nonnull MPMessage *)message;
- (void)saveProductBag:(nonnull MPProductBag *)productBag;
- (void)saveSegment:(nonnull MPSegment *)segment;
- (void)saveSession:(nonnull MPSession *)session;
- (void)saveUpload:(nonnull MPUpload *)upload messageIds:(nonnull NSArray<NSNumber *> *)messageIds operation:(MPPersistenceOperation)operation;
- (void)updateConsumerInfo:(nonnull MPConsumerInfo *)consumerInfo;
- (void)updateSession:(nonnull MPSession *)session;

@end
