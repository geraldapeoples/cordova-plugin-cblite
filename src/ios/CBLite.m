#import "CBLite.h"
#import <Cordova/CDVPlugin.h>
#import <CouchbaseLite/CouchbaseLite.h>

@implementation CBLite

static NSArray *REPLICATION_TYPES;

static NSMutableDictionary *databases;
static NSMutableDictionary *databaseChangeListenerTokens;
static NSMutableDictionary *replicators;
static NSMutableDictionary *replicatorChangeListenerTokens;

static NSThread *cblThread;
void dispatch_cbl_async(NSThread *thread, dispatch_block_t block);

/*
 * iOS lifecycle events
 */
#pragma mark iOS lifecycle events

// TODO: Implement onReset
- (void)onReset {
    NSLog(@"onReset: called");
    //    dispatch_cbl_async(cblThread, ^{
    //        // cancel any change listeners
    //        [[NSNotificationCenter defaultCenter]
    //         removeObserver:self
    //         name:kCBLDatabaseChangeNotification
    //         object:nil];
    //
    //        //cancel all replicators
    //        for (NSString *r in replicators) {
    //            CBLReplication *repl = replicators[r];
    //            [repl stop];
    //        }
    //
    //        //cancel all callbacks
    //        for (NSString *cbId in callbacks){
    //            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_NO_RESULT];
    //            [pluginResult setKeepCallbackAsBool:NO];
    //            [self.commandDelegate sendPluginResult:pluginResult callbackId:cbId];
    //        }
    //
    //        [callbacks removeAllObjects];
    //        [replicators removeAllObjects];
    //        [databases removeAllObjects];
    //    });
}

/*
 * Cordova
 */
#pragma mark initialization

- (void)pluginInitialize {
    NSLog(@"pluginInitialize: called");
    
    cblThread = [[NSThread alloc] initWithTarget:self selector:@selector(cblThreadMain) object:nil];
    [cblThread start];
    
    dispatch_cbl_async(cblThread, ^{
        if (REPLICATION_TYPES == nil) {REPLICATION_TYPES = @[@"PushAndPull", @"Push", @"Pull"];}
        if (databases == nil) {databases = [NSMutableDictionary dictionary];}
        if (databaseChangeListenerTokens == nil) {databaseChangeListenerTokens = [NSMutableDictionary dictionary];}
        if (replicators == nil) {replicators = [NSMutableDictionary dictionary];}
        if (replicatorChangeListenerTokens == nil) {replicatorChangeListenerTokens = [NSMutableDictionary dictionary];}
    });
}

- (void)cblThreadMain {
    NSLog(@"cblThreadMain: called");
    // You need the NSPort here because a runloop with no sources or ports registered with it
    // will simply exit immediately instead of running forever.
    NSPort *keepAlive = [NSPort port];
    NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
    [keepAlive scheduleInRunLoop:runLoop forMode:NSRunLoopCommonModes];
    [runLoop run];
}

/*
 * Database
 */
#pragma mark Database

- (void)openDatabase:(CDVInvokedUrlCommand *)urlCommand {
    NSLog(@"openDatabase: called");
    NSNumber *startTime = [CBLite longUnixEpoch];
    dispatch_cbl_async(cblThread, ^{
        
        CDVPluginResult *pluginResult;
        
        @try {
            NSString *dbName = urlCommand.arguments[0];
            
            if (databases[dbName]) {
                NSError *error;
                CBLDatabase *db = databases[dbName];
                NSMutableDictionary *response = [NSMutableDictionary dictionary];
                response[@"message"] = @"Database already opened";
                response[@"elapsed"] = [CBLite getElapsedTime:startTime];
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:response];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:urlCommand.callbackId];
                return;
            }
            
            NSError *error;
            CBLDatabase *db = [[CBLDatabase alloc] initWithName:dbName error:&error];
            databases[dbName] = db;
            NSMutableDictionary *response = [NSMutableDictionary dictionary];
            response[@"message"] = @"Database opened";
            response[@"elapsed"] = [CBLite getElapsedTime:startTime];
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:response];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:urlCommand.callbackId];
        }
        @catch (NSException *exception) {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: exception.reason];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:urlCommand.callbackId];
        }
        
    });
}

- (void)closeDatabase:(CDVInvokedUrlCommand *)urlCommand {
    NSLog(@"closeDatabase: called");
    NSNumber *startTime = [CBLite longUnixEpoch];
    dispatch_cbl_async(cblThread, ^{
        
        CDVPluginResult *pluginResult;
        
        @try {
            NSString *dbName = urlCommand.arguments[0];
            if (!databases[dbName]) {
                NSMutableDictionary *response = [NSMutableDictionary dictionary];
                response[@"message"] = @"Database already closed";
                response[@"elapsed"] = [CBLite getElapsedTime:startTime];
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:response];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:urlCommand.callbackId];
                return;
            }
            
            // TODO: Remove database change listeners, replicators and replicator change listeners
            
            NSError *error;
            CBLDatabase *db = databases[dbName];
            [db close:&error];
            
            NSMutableDictionary *response = [NSMutableDictionary dictionary];
            response[@"message"] = @"Database closed";
            response[@"elapsed"] = [CBLite getElapsedTime:startTime];
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:response];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:urlCommand.callbackId];
        }
        @catch (NSException *exception) {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: exception.reason];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:urlCommand.callbackId];
        }
        
    });
}

- (void)deleteDatabase:(CDVInvokedUrlCommand *)urlCommand {
    NSLog(@"deleteDatabase: called");
    NSNumber *startTime = [CBLite longUnixEpoch];
    dispatch_cbl_async(cblThread, ^{
        
        CDVPluginResult *pluginResult;
        
        @try {
            NSString *dbName = urlCommand.arguments[0];
            
            if (!databases[dbName]) {
                NSMutableDictionary *response = [NSMutableDictionary dictionary];
                response[@"message"] = @"Database already deleted";
                response[@"elapsed"] = [CBLite getElapsedTime:startTime];
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:response];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:urlCommand.callbackId];
                return;
            }
            
            // TODO: Remove database change listeners, replicators and replicator change listeners
            
            NSError *error;
            CBLDatabase *db = databases[dbName];
            [db delete:&error];
            [databases removeObjectForKey:dbName];
            
            NSMutableDictionary *response = [NSMutableDictionary dictionary];
            response[@"message"] = @"Database deleted";
            response[@"elapsed"] = [CBLite getElapsedTime:startTime];
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:response];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:urlCommand.callbackId];
        }
        @catch (NSException *exception) {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: exception.reason];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:urlCommand.callbackId];
        }
        
    });
}

- (void)addDatabaseChangeListener:(CDVInvokedUrlCommand *)urlCommand {
    NSLog(@"addDatabaseChangeListener: called");
    NSNumber *startTime = [CBLite longUnixEpoch];
    
    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_NO_RESULT];
    [result setKeepCallbackAsBool:YES];
    [self.commandDelegate sendPluginResult:result callbackId:urlCommand.callbackId];
    
    dispatch_cbl_async(cblThread, ^{
        
        @try {
            NSString *dbName = urlCommand.arguments[0];
            if (!databases[dbName]) {
                CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Database not found"];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:urlCommand.callbackId];
                return;
            }
            
            if (databaseChangeListenerTokens[dbName]) {
                NSMutableDictionary *response = [NSMutableDictionary dictionary];
                response[@"message"] = @"Database change listener already added";
                response[@"elapsed"] = [CBLite getElapsedTime:startTime];
                CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:response];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:urlCommand.callbackId];
                return;
            }
            
            CBLDatabase *db = databases[dbName];
            databaseChangeListenerTokens[dbName] = [db addChangeListener:^(CBLDatabaseChange *change) {
                NSMutableArray *docArray = [[NSMutableArray alloc] init];
                for (NSString *id in change.documentIDs) {
                    [docArray addObject:id];
                }
                
                NSMutableDictionary *response = [[NSMutableDictionary alloc] init];
                response[@"database"] = dbName;
                response[@"rows"] = docArray;
                CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:response];
                [pluginResult setKeepCallbackAsBool:YES];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:urlCommand.callbackId];
            }];
            
        }
        @catch (NSException *exception) {
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: exception.reason];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:urlCommand.callbackId];
        }
        
    });
}

- (void)removeDatabaseChangeListener:(CDVInvokedUrlCommand *)urlCommand {
    NSLog(@"removeDatabaseChangeListener: called");
    NSNumber *startTime = [CBLite longUnixEpoch];
    dispatch_cbl_async(cblThread, ^{
        
        CDVPluginResult *pluginResult;
        
        @try {
            NSString *dbName = urlCommand.arguments[0];
            
            if (!databases[dbName]) {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Database not found"];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:urlCommand.callbackId];
                return;
            }
            
            if (!databaseChangeListenerTokens[dbName]) {
                NSMutableDictionary *response = [NSMutableDictionary dictionary];
                response[@"message"] = @"Database change listener already removed";
                response[@"elapsed"] = [CBLite getElapsedTime:startTime];
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:response];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:urlCommand.callbackId];
                return;
            }
            
            CBLDatabase *db = databases[dbName];
            [db removeChangeListenerWithToken:databaseChangeListenerTokens[dbName]];
            [databaseChangeListenerTokens removeObjectForKey:dbName];
            
            NSMutableDictionary *response = [NSMutableDictionary dictionary];
            response[@"message"] = @"Database change listener removed";
            response[@"elapsed"] = [CBLite getElapsedTime:startTime];
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:response];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:urlCommand.callbackId];
            
        }
        @catch (NSException *exception) {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:exception.reason];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:urlCommand.callbackId];
        }
        
    });
}

/*
 * Replication
 */
#pragma mark Replication

- (void)initReplicator:(CDVInvokedUrlCommand *)urlCommand {
    NSLog(@"initReplicator: called");
    NSNumber *startTime = [CBLite longUnixEpoch];
    dispatch_cbl_async(cblThread, ^{
        
        CDVPluginResult *pluginResult;
        
        @try {
            
            NSString *dbName = urlCommand.arguments[0];
            NSString *syncURL = urlCommand.arguments[1];
            NSString *user = urlCommand.arguments[2];
            NSString *pass = urlCommand.arguments[3];
            NSString *session = urlCommand.arguments[4];
            NSString *replicationType = urlCommand.arguments[5];
            NSArray *channels = urlCommand.arguments[6];
            BOOL background = [urlCommand.arguments[7] boolValue];
            BOOL continuous = [urlCommand.arguments[8] boolValue];
            
            if (!databases[dbName]) {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Database does not exist"];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:urlCommand.callbackId];
                return;
            }
            
            CBLURLEndpoint *target = [[CBLURLEndpoint alloc] initWithURL:[NSURL URLWithString:syncURL]];
            CBLDatabase *db = databases[dbName];
            
            CBLReplicatorConfiguration *config = [[CBLReplicatorConfiguration alloc] initWithDatabase:db target:target];
            if ([replicationType isEqualToString:@"PushAndPull"]) {
                config.replicatorType = kCBLReplicatorTypePushAndPull;
            } else if ([replicationType isEqualToString:@"Push"]) {
                config.replicatorType = kCBLReplicatorTypePush;
            } else if ([replicationType isEqualToString:@"Pull"]) {
                config.replicatorType = kCBLReplicatorTypePull;
            } else {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Must provide a valid replication type"];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:urlCommand.callbackId];
                return;
            }
            
            if ([channels count] > 0) {
                config.channels = channels;
            }
            config.allowReplicatingInBackground = background;
            config.continuous = continuous;
            
            if (session) {
                config.authenticator = [[CBLSessionAuthenticator alloc] initWithSessionID:session];
            } else {
                config.authenticator = [[CBLBasicAuthenticator alloc] initWithUsername:user password:pass];
            }
            
            CBLReplicator *replicator = [[CBLReplicator alloc] initWithConfig:config];
            NSString *replicatorName = [NSString stringWithFormat:@"%@%@", dbName, replicationType];
            replicators[replicatorName] = replicator;
            
            NSMutableDictionary *response = [NSMutableDictionary dictionary];
            response[@"message"] = @"Replicator initialised";
            response[@"elapsed"] = [CBLite getElapsedTime:startTime];
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:response];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:urlCommand.callbackId];
        }
        
        @catch (NSException *exception) {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: exception.reason];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:urlCommand.callbackId];
        }
        
    });
}

- (void)startReplicator:(CDVInvokedUrlCommand *)urlCommand {
    NSLog(@"startReplicator: called");
    NSNumber *startTime = [CBLite longUnixEpoch];
    dispatch_cbl_async(cblThread, ^{
        
        CDVPluginResult *pluginResult;
        
        @try {
            NSString *dbName = urlCommand.arguments[0];
            NSString *replicationType = urlCommand.arguments[1];
            
            if (!databases[dbName]) {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Database does not exist"];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:urlCommand.callbackId];
                return;
            }
            
            NSString *replicatorName = [NSString stringWithFormat:@"%@%@", dbName, replicationType];
            if (!replicators[replicatorName]) {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Replicator does not exist"];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:urlCommand.callbackId];
                return;
            }
            
            CBLReplicator *replicator = replicators[replicatorName];
            [replicator start];
            
            NSMutableDictionary *response = [NSMutableDictionary dictionary];
            response[@"message"] = @"Replicator started";
            response[@"elapsed"] = [CBLite getElapsedTime:startTime];
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:response];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:urlCommand.callbackId];
            
        }
        @catch (NSException *exception) {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: exception.reason];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:urlCommand.callbackId];
        }
        
    });
}

- (void)stopReplicator:(CDVInvokedUrlCommand *)urlCommand {
    NSLog(@"stopReplicator: called");
    NSNumber *startTime = [CBLite longUnixEpoch];
    dispatch_cbl_async(cblThread, ^{
        
        CDVPluginResult *pluginResult;
        
        @try {
            NSString *dbName = urlCommand.arguments[0];
            NSString *replicationType = urlCommand.arguments[1];
            
            NSString *replicatorName = [NSString stringWithFormat:@"%@%@", dbName, replicationType];
            if (!replicators[replicatorName]) {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Replicator not initialised"];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:urlCommand.callbackId];
                return;
            }
            
            CBLReplicator *replicator = replicators[replicatorName];
            [replicator stop];
            [replicators removeObjectForKey:replicatorName];
            
            NSMutableDictionary *response = [NSMutableDictionary dictionary];
            response[@"message"] = @"Replicator stopped";
            response[@"elapsed"] = [CBLite getElapsedTime:startTime];
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:response];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:urlCommand.callbackId];
        }
        @catch (NSException *exception) {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: exception.reason];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:urlCommand.callbackId];
        }
        
    });
}

- (void)addReplicatorChangeListener:(CDVInvokedUrlCommand *)urlCommand {
    NSLog(@"addReplicatorChangeListener: called");
    NSNumber *startTime = [CBLite longUnixEpoch];
    
    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_NO_RESULT];
    [result setKeepCallbackAsBool:YES];
    [self.commandDelegate sendPluginResult:result callbackId:urlCommand.callbackId];
    
    dispatch_cbl_async(cblThread, ^{
        
        @try {
            NSString *dbName = urlCommand.arguments[0];
            NSString *replicationType = urlCommand.arguments[1];
            
            NSString *replicatorName = [NSString stringWithFormat:@"%@%@", dbName, replicationType];
            if (!replicators[replicatorName]) {
                CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Replicator not initialised"];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:urlCommand.callbackId];
                return;
            }
            
            if (replicatorChangeListenerTokens[replicatorName]) {
                NSMutableDictionary *response = [NSMutableDictionary dictionary];
                response[@"message"] = @"Replicator change listener already added";
                response[@"elapsed"] = [CBLite getElapsedTime:startTime];
                CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:response];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:urlCommand.callbackId];
                return;
            }
            
            replicatorChangeListenerTokens[replicatorName] = [replicators[replicatorName] addChangeListener:^(CBLReplicatorChange *change) {
                NSMutableDictionary *response = [[NSMutableDictionary alloc] init];
                response[@"dbName"] = dbName;
                response[@"replicationType"] = replicationType;
                if (change.status.activity == kCBLReplicatorStopped) {
                    response[@"status"] = @"stopped";
                } else if (change.status.activity == kCBLReplicatorOffline) {
                    response[@"status"] = @"offline";
                } else if (change.status.activity == kCBLReplicatorConnecting) {
                    response[@"status"] = @"connecting";
                } else if (change.status.activity == kCBLReplicatorIdle) {
                    response[@"status"] = @"idle";
                } else if (change.status.activity == kCBLReplicatorBusy) {
                    response[@"status"] = @"busy";
                }
                response[@"total"] = [NSString stringWithFormat:@"%llu", change.status.progress.total];
                response[@"completed"] = [NSString stringWithFormat:@"%llu", change.status.progress.completed];
                if (change.status.error) {
                    response[@"error"] = [NSString stringWithFormat:@"%@", change.status.error];
                }
                CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:response];
                [pluginResult setKeepCallbackAsBool:YES];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:urlCommand.callbackId];
            }];
            
        }
        @catch (NSException *exception) {
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: exception.reason];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:urlCommand.callbackId];
        }
        
    });
}

- (void)removeReplicatorChangeListener:(CDVInvokedUrlCommand *)urlCommand {
    NSLog(@"removeReplicatorChangeListener: called");
    NSNumber *startTime = [CBLite longUnixEpoch];
    dispatch_cbl_async(cblThread, ^{
        
        CDVPluginResult *pluginResult;
        
        @try {
            NSString *dbName = urlCommand.arguments[0];
            NSString *replicationType = urlCommand.arguments[1];
            
            NSString *replicatorName = [NSString stringWithFormat:@"%@%@", dbName, replicationType];
            if (!replicators[replicatorName]) {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Replicator not initialised"];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:urlCommand.callbackId];
                return;
            }
            
            if (!replicatorChangeListenerTokens[replicatorName]) {
                NSMutableDictionary *response = [NSMutableDictionary dictionary];
                response[@"message"] = @"Replicator change listener already removed";
                response[@"elapsed"] = [CBLite getElapsedTime:startTime];
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:response];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:urlCommand.callbackId];
                return;
            }
            
            [replicators[replicatorName] removeChangeListenerWithToken:replicatorChangeListenerTokens[replicatorName]];
            [replicatorChangeListenerTokens removeObjectForKey:replicatorName];
            
            NSMutableDictionary *response = [NSMutableDictionary dictionary];
            response[@"message"] = @"Replicator change listener removed";
            response[@"elapsed"] = [CBLite getElapsedTime:startTime];
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:response];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:urlCommand.callbackId];
        }
        @catch (NSException *exception) {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:exception.reason];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:urlCommand.callbackId];
        }
        
    });
}

- (void)getReplicatorStatus:(CDVInvokedUrlCommand *)urlCommand {
    NSLog(@"getReplicatorStatus: called");
    NSNumber *startTime = [CBLite longUnixEpoch];
    dispatch_cbl_async(cblThread, ^{
        
        CDVPluginResult *pluginResult;
        
        @try {
            NSString *dbName = urlCommand.arguments[0];
            NSString *replicationType = urlCommand.arguments[1];
            
            NSString *replicatorName = [NSString stringWithFormat:@"%@%@", dbName, replicationType];
            if (!replicators[replicatorName]) {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Replicator not initialised"];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:urlCommand.callbackId];
                return;
            }
            
            [replicators[replicatorName] removeChangeListenerWithToken:replicatorChangeListenerTokens[replicatorName]];
            
            NSMutableDictionary *response = [NSMutableDictionary dictionary];
            CBLReplicatorStatus *status = (CBLReplicatorStatus *)[replicators[replicatorName] status];
            
            if (status.activity == kCBLReplicatorStopped) {
                response[@"status"] = @"stopped";
            } else if (status.activity == kCBLReplicatorOffline) {
                response[@"status"] = @"offline";
            } else if (status.activity == kCBLReplicatorConnecting) {
                response[@"status"] = @"connecting";
            } else if (status.activity == kCBLReplicatorIdle) {
                response[@"status"] = @"idle";
            } else if (status.activity == kCBLReplicatorBusy) {
                response[@"status"] = @"busy";
            }
            response[@"message"] = @"Replicator status";
            response[@"elapsed"] = [CBLite getElapsedTime:startTime];
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:response];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:urlCommand.callbackId];
        }
        @catch (NSException *exception) {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: exception.reason];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:urlCommand.callbackId];
        }
        
    });
}

/*
 * Document
 */
#pragma mark Document

- (void)saveDocument:(CDVInvokedUrlCommand *)urlCommand {
    NSLog(@"saveDocument: called");
    NSNumber *startTime = [CBLite longUnixEpoch];
    dispatch_cbl_async(cblThread, ^{
        
        CDVPluginResult *pluginResult;
        
        @try {
            NSString *dbName = urlCommand.arguments[0];
            NSString *documentId = urlCommand.arguments[1];
            NSDictionary *document = urlCommand.arguments[2];
            
            if (!databases[dbName]) {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Database does not exist"];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:urlCommand.callbackId];
                return;
            }
            
            if(!documentId || !document) {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Must provide document id and document"];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:urlCommand.callbackId];
                return;
            }
            
            NSError *error;
            CBLMutableDocument *mDoc = [[CBLMutableDocument alloc] initWithID:documentId data:document];
            if (mDoc[@"id"]) {
                [mDoc removeValueForKey:@"id"];
            }
            [databases[dbName] saveDocument:mDoc error:&error];
            
            NSMutableDictionary *response = [NSMutableDictionary dictionary];
            response[@"message"] = @"Document saved";
            response[@"elapsed"] = [CBLite getElapsedTime:startTime];
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:response];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:urlCommand.callbackId];
        }
        @catch (NSException *exception) {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: exception.reason];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:urlCommand.callbackId];
        }
        
    });
}

- (void)getDocument:(CDVInvokedUrlCommand *)urlCommand {
    NSLog(@"getDocument: called");
    NSNumber *startTime = [CBLite longUnixEpoch];
    dispatch_cbl_async(cblThread, ^{
        
        CDVPluginResult *pluginResult;
        
        @try {
            NSString *dbName = urlCommand.arguments[0];
            NSString *documentId = urlCommand.arguments[1];
            
            if (!databases[dbName]) {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Database does not exist"];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:urlCommand.callbackId];
                return;
            }
            
            CBLDocument *document = [[databases[dbName] documentWithID:documentId] toMutable];
            
            if (document != nil) {
                [document setValue:documentId forKey:@"id"];
                NSDictionary *docDictionary = [document toDictionary];
                NSMutableDictionary *response = [NSMutableDictionary dictionary];
                response[@"message"] = @"Document found";
                response[@"document"] = docDictionary;
                response[@"elapsed"] = [CBLite getElapsedTime:startTime];
                CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:response];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:urlCommand.callbackId];
            } else {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"document not found"];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:urlCommand.callbackId];
            }
            
        }
        @catch (NSException *exception) {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:exception.reason];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:urlCommand.callbackId];
        }
        
    });
}

- (void)deleteDocument:(CDVInvokedUrlCommand *)urlCommand {
    NSLog(@"deleteDocument: called");
    NSNumber *startTime = [CBLite longUnixEpoch];
    dispatch_cbl_async(cblThread, ^{
        
        CDVPluginResult *pluginResult;
        
        @try {
            NSString *dbName = urlCommand.arguments[0];
            NSString *documentId = urlCommand.arguments[1];
            
            if (!databases[dbName]) {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Database does not exist"];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:urlCommand.callbackId];
                return;
            }
            
            CBLDatabase *db = databases[dbName];
            CBLMutableDocument *document = [[db documentWithID:documentId] toMutable];
            if(!document) {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Document not found"];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:urlCommand.callbackId];
                return;
            }
            
            NSError *error;
            [db deleteDocument:document error:&error];
            
            NSMutableDictionary *response = [NSMutableDictionary dictionary];
            response[@"message"] = @"Document deleted";
            response[@"elapsed"] = [CBLite getElapsedTime:startTime];
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:response];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:urlCommand.callbackId];
        }
        @catch (NSException *exception) {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:exception.reason];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:urlCommand.callbackId];
        }
        
    });
}

- (void)purgeDocument:(CDVInvokedUrlCommand *)urlCommand {
    NSLog(@"purgeDocument: called");
    NSNumber *startTime = [CBLite longUnixEpoch];
    dispatch_cbl_async(cblThread, ^{
        
        CDVPluginResult *pluginResult;
        
        @try {
            NSString *dbName = urlCommand.arguments[0];
            NSString *documentId = urlCommand.arguments[1];
            
            if (!databases[dbName]) {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Database does not exist"];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:urlCommand.callbackId];
                return;
            }
            
            CBLDatabase *db = databases[dbName];
            CBLMutableDocument *document = [[db documentWithID:documentId] toMutable];
            if(!document) {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Document not found"];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:urlCommand.callbackId];
                return;
            }
            
            NSError *error;
            [db purgeDocument:document error:&error];
            
            NSMutableDictionary *response = [NSMutableDictionary dictionary];
            response[@"message"] = @"Document purged";
            response[@"elapsed"] = [CBLite getElapsedTime:startTime];
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:response];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:urlCommand.callbackId];
        }
        @catch (NSException *exception) {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:exception.reason];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:urlCommand.callbackId];
        }
        
    });
}

- (void)purgeDocuments:(CDVInvokedUrlCommand *)urlCommand {
    NSLog(@"purgeDocuments: called");
    NSNumber *startTime = [CBLite longUnixEpoch];
    dispatch_cbl_async(cblThread, ^{
        
        CDVPluginResult *pluginResult;
        
        @try {
            NSString *dbName = urlCommand.arguments[0];
            NSArray *docIds = urlCommand.arguments[1];
            
            if (!databases[dbName]) {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Database does not exist"];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:urlCommand.callbackId];
                return;
            }
            
            CBLDatabase *db = databases[dbName];
            for (NSUInteger i = 0; i < [docIds count]; i++) {
                NSString *documentId = [docIds objectAtIndex: i];
                CBLMutableDocument *document = [[db documentWithID:documentId] toMutable];
                if(document) {
                    NSError *error;
                    [db purgeDocument:document error:&error];
                }
            }
            
            NSMutableDictionary *response = [NSMutableDictionary dictionary];
            response[@"message"] = @"Documents purged";
            response[@"elapsed"] = [CBLite getElapsedTime:startTime];
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:response];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:urlCommand.callbackId];
        }
        @catch (NSException *exception) {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:exception.reason];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:urlCommand.callbackId];
        }
        
    });
}

// TODO: Implement getBlob
- (void)getBlob:(CDVInvokedUrlCommand *)urlCommand {
    NSLog(@"getBlob: called");
    //    dispatch_cbl_async(cblThread, ^{
    //        @autoreleasepool{
    //            NSString *dbName = [urlCommand.arguments objectAtIndex:0];
    //            NSString *documentId = [urlCommand.arguments objectAtIndex:1];
    //            NSString *fileName = [urlCommand.arguments objectAtIndex:2];
    //            NSString *name = [urlCommand.arguments objectAtIndex:3];
    //            NSString *mime = [urlCommand.arguments objectAtIndex:4];
    //            NSString *dirName = [urlCommand.arguments objectAtIndex:5];
    //            NSError *error;
    //            CBLDatabase *db = databases[dbName];
    //            CBLDocument *document = [db documentWithID: documentId];
    //            CBLUnsavedRevision *newRev = [document.currentRevision createRevision];
    //
    //            NSString *docsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    //            NSString *mediaPath = [NSString stringWithFormat:@"%@/%@", docsPath, dirName];
    //            NSString *filePath = [mediaPath stringByAppendingPathComponent:fileName];
    //
    //            NSData *data = [[NSFileManager defaultManager] contentsAtPath:filePath];
    //
    //            @try{
    //                [newRev setAttachmentNamed: name
    //                           withContentType: mime
    //                                   content: data];
    //                [newRev save: &error];
    //                CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"success"];
    //                [self.commandDelegate sendPluginResult:pluginResult callbackId:urlCommand.callbackId];
    //            }
    //            @catch(NSException *e){
    //                CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"putAttachment failure"];
    //                [self.commandDelegate sendPluginResult:pluginResult callbackId:urlCommand.callbackId];
    //            }
    //        }
    //    });
}

// TODO: Implement setBlob
- (void)setBlob:(CDVInvokedUrlCommand *)urlCommand {
    NSLog(@"setBlob: called");
    //    dispatch_cbl_async(cblThread, ^{
    //        @autoreleasepool{
    //            NSString *dbName = [urlCommand.arguments objectAtIndex:0];
    //            NSString *documentId = [urlCommand.arguments objectAtIndex:1];
    //            NSString *fileName = [urlCommand.arguments objectAtIndex:2];
    //            NSString *name = [urlCommand.arguments objectAtIndex:3];
    //            NSString *mime = [urlCommand.arguments objectAtIndex:4];
    //            NSString *dirName = [urlCommand.arguments objectAtIndex:5];
    //            NSError *error;
    //            CBLDatabase *db = databases[dbName];
    //            CBLDocument *document = [db documentWithID: documentId];
    //            CBLUnsavedRevision *newRev = [document.currentRevision createRevision];
    //
    //            NSString *docsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    //            NSString *mediaPath = [NSString stringWithFormat:@"%@/%@", docsPath, dirName];
    //            NSString *filePath = [mediaPath stringByAppendingPathComponent:fileName];
    //
    //            NSData *data = [[NSFileManager defaultManager] contentsAtPath:filePath];
    //
    //            @try{
    //                [newRev setAttachmentNamed: name
    //                           withContentType: mime
    //                                   content: data];
    //                [newRev save: &error];
    //                CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"success"];
    //                [self.commandDelegate sendPluginResult:pluginResult callbackId:urlCommand.callbackId];
    //            }
    //            @catch(NSException *e){
    //                CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"putAttachment failure"];
    //                [self.commandDelegate sendPluginResult:pluginResult callbackId:urlCommand.callbackId];
    //            }
    //        }
    //    });
}

/*
 * Query
 */
#pragma mark Query

- (void)query:(CDVInvokedUrlCommand *)urlCommand {
    NSLog(@"query: called");
    NSNumber *startTime = [CBLite longUnixEpoch];
    /*
     *  database.query({
     *       select: [],                     // Leave empty to query for all
     *       from: "otherDatabaseName",      // Omit or set null to use current db
     *       where: [{ property: "firstName", comparison: "equalTo", value: "Osei" }],
     *       order: [{ property: "firstName", direction: "desc" }],
     *       limit: 2
     *   });
     */
    dispatch_cbl_async(cblThread, ^{
        
        CDVPluginResult *pluginResult;
        
        @try {
            NSString *dbName = urlCommand.arguments[0];
            NSDictionary *searchQuery = urlCommand.arguments[1];
            
            if (!databases[dbName]) {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Database does not exist"];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:urlCommand.callbackId];
                return;
            }
            
            NSArray *select;              //(NSArray<CBLQuerySelectResult*>*)select
            CBLQueryDataSource *from;     //(CBLQueryDataSource*)from
            NSArray *join;                //(nullable NSArray<CBLQueryJoin*>*)join
            CBLQueryExpression *where;    //(nullable CBLQueryExpression*)where
            NSArray *groupBy;             //(nullable NSArray<CBLQueryExpression*>*)groupBy
            CBLQueryExpression *having;   //(nullable CBLQueryExpression*)having
            NSArray *orderBy;             //(nullable NSArray<CBLQueryOrdering*>*)orderings
            CBLQueryLimit *limit;         //(nullable CBLQueryLimit*)limit:offset]
            
            /*
             * Process "select" items
             */
            if (!searchQuery[@"select"] || [(NSArray *) searchQuery[@"select"] count] == 0) {
                NSMutableArray *selectArray = [NSMutableArray array];
                [selectArray addObject:[CBLQuerySelectResult all]];
                [selectArray addObject:[CBLQuerySelectResult expression:[CBLQueryMeta id]]];
                select = selectArray;
            } else {
                NSMutableArray *selectArray = [NSMutableArray array];
                for (NSString *item in searchQuery[@"select"]) {
                    if ([item isEqualToString:@"COUCHBASE_ID"]) {
                        [selectArray addObject:[CBLQuerySelectResult expression:[CBLQueryMeta id]]];
                    } else if ([item isEqualToString:@"COUCHBASE_ALL"]) {
                        [selectArray addObject:[CBLQuerySelectResult all]];
                    } else {
                        [selectArray addObject:[CBLQueryExpression property:item]];
                    }
                }
                select = selectArray;
            }
            
            /*
             * Process "from" if is exists or use dbName
             */
            if (searchQuery[@"from"]) {
                from = [CBLQueryDataSource database:databases[searchQuery[@"from"]]];
            } else {
                from = [CBLQueryDataSource database:databases[dbName]];
            }
            
            /*
             * Process "where"
             */
            if (searchQuery[@"where"]) {
                NSArray *searchQueryArray = searchQuery[@"where"];
                for (int i = 0; i < [searchQueryArray count]; i++) {
                    NSDictionary *item = searchQueryArray[i];
                    NSString *logicalOperator = item[@"comparison"];
                    if ([logicalOperator isEqualToString:@"and"]) {
                        if (!where) break;
                        i++;
                        item = searchQueryArray[i];
                        CBLQueryExpression *whereExpr = [self setComparision:item];
                        if (whereExpr != NULL){
                            where = [where andExpression:whereExpr];
                        }
                    } else if ([logicalOperator isEqualToString:@"or"]) {
                        if (!where) break;
                        i++;
                        item = searchQueryArray[i];
                        CBLQueryExpression *whereExpr = [self setComparision:item];
                        if (whereExpr != NULL){
                            where = [where orExpression:whereExpr];
                        }
                    } else {
                        CBLQueryExpression *whereExpr = [self setComparision:item];
                        if (whereExpr != NULL){
                            where = whereExpr;
                        }
                    }
                }
            }
            
            /*
             * Process "groupBy"
             */
            if (searchQuery[@"groupBy"]) {
                NSMutableArray *groupByMutableArray = [NSMutableArray array];
                for (NSString *item in searchQuery[@"groupBy"]) {
                    [groupByMutableArray addObject:[CBLQueryExpression property:item]];
                }
                groupBy = groupByMutableArray;
            }
            
            /*
             * Process "orderBy"
             */
            if (searchQuery[@"orderBy"]) {
                NSMutableArray *orderByMutableArray = [NSMutableArray array];
                for (NSDictionary *item in searchQuery[@"orderBy"]) {
                    NSString *property = item[@"property"];
                    NSString *direction = item[@"direction"];
                    if ([property isEqualToString:@"COUCHBASE_ID"]) {
                        if ([direction isEqualToString:@"desc"]) {
                            [orderByMutableArray addObject:[[CBLQueryOrdering expression:[CBLQueryMeta id]] descending]];
                        } else {
                            [orderByMutableArray addObject:[[CBLQueryOrdering expression:[CBLQueryMeta id]] ascending]];
                        }
                    } else {
                        if ([direction isEqualToString:@"desc"]) {
                            [orderByMutableArray addObject:[[CBLQueryOrdering property:property] descending]];
                        } else {
                            [orderByMutableArray addObject:[[CBLQueryOrdering property:property] ascending]];
                        }
                    }
                }
                orderBy = orderByMutableArray;
            }
            
            /*
             * Process limit and offset
             */
            if (searchQuery[@"limit"]  && searchQuery[@"limit"] != [NSNull null]) {
                NSInteger limitValue = [[searchQuery valueForKey:@"limit"] integerValue];
                if(searchQuery[@"offset"] && searchQuery[@"offset"] != [NSNull null]) {
                    NSInteger offSetValue = [[searchQuery valueForKey:@"offset"] integerValue];
                    limit = [CBLQueryLimit limit:[CBLQueryExpression integer:limitValue] offset:[CBLQueryExpression integer:offSetValue]];
                } else {
                    limit = [CBLQueryLimit limit:[CBLQueryExpression integer:limitValue]];
                }
            }
            
            /*
             * Build the query
             */
            CBLQuery *query = [CBLQueryBuilder select:select from:from join:join where:where groupBy:groupBy having:having orderBy:orderBy limit:limit];
            
            /*
             * Execute the query
             */
            NSError *error;
            CBLQueryResultSet *rs = [query execute:&error];
            
            NSMutableArray *resultArray = [NSMutableArray array];
            for (CBLQueryResult *result in rs) {
                @autoreleasepool {
                    NSDictionary *rowNSDictionary = [result toDictionary];
                    [resultArray addObject:rowNSDictionary];
                }
            }
            
            NSMutableDictionary *response = [NSMutableDictionary dictionary];
            response[@"message"] = @"Documents queried";
            response[@"rows"] = resultArray;
            response[@"elapsed"] = [CBLite getElapsedTime:startTime];
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:response];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:urlCommand.callbackId];
        }
        
        @catch (NSException *exception) {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:exception.reason];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:urlCommand.callbackId];
        }
        
    });
}

/*
 * Misc
 */
#pragma mark Misc

- (void)info:(CDVInvokedUrlCommand *)urlCommand {
    NSLog(@"info: called");
    NSNumber *startTime = [CBLite longUnixEpoch];
    dispatch_cbl_async(cblThread, ^{
        
        CDVPluginResult *pluginResult;
        
        @try {
            
            NSString *dbName = urlCommand.arguments[0];
            
            if (!databases[dbName]) {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Database does not exist"];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:urlCommand.callbackId];
                return;
            }
            
            NSString *databasePath = [databases[dbName] path];
            
            NSMutableDictionary *replicatorInfo = [[NSMutableDictionary alloc] init];
            for (NSString *replicatorName in replicators) {
                CBLReplicator *repl = replicators[replicatorName];
                NSError *error;
                NSString *response = [NSJSONSerialization JSONObjectWithData:[[CBLite getStringFromStatus:repl.status withReplicatorName:replicatorName andDatabase:dbName] dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
                replicatorInfo[[NSString stringWithFormat:@"Replicator-%@", replicatorName]] = response;
            }
            
            for (NSString *replicatorName in replicatorChangeListenerTokens) {
                replicatorInfo[[NSString stringWithFormat:@"Listener-%@", replicatorName]] = [replicatorChangeListenerTokens[replicatorName] stringValue];
            }
            
            NSMutableDictionary *response = [NSMutableDictionary dictionary];
            response[@"message"] = @"Info";
            response[@"databasePath"] = databasePath;
            response[@"replicatorInfo"] = replicatorInfo;
            response[@"elapsed"] = [CBLite getElapsedTime:startTime];
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:response];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:urlCommand.callbackId];
        }
        
        @catch (NSException *exception) {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:exception.reason];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:urlCommand.callbackId];
        }
        
    });
}

/*
 * Utils
 */
#pragma mark Utils

+ (NSString *)getStringFromStatus:(CBLReplicatorStatus *)status withReplicatorName:(NSString *)r andDatabase:(NSString *)dbName {
    NSString *response = @"";
    if (status.activity == kCBLReplicatorStopped) {
        NSLog(@"Replication stopped");
        response = [CBLite jsonSyncStatus:@"STOPPED" withDb:dbName withType:r progressTotal:status.progress.total progressCompleted:status.progress.completed];
    } else if (status.activity == kCBLReplicatorOffline) {
        NSLog(@"Replication Offline");
        response = [CBLite jsonSyncStatus:@"OFFLINE" withDb:dbName withType:r progressTotal:status.progress.total progressCompleted:status.progress.completed];
    } else if (status.activity == kCBLReplicatorConnecting) {
        NSLog(@"Replication Connecting");
        response = [CBLite jsonSyncStatus:@"CONNECTING" withDb:dbName withType:r progressTotal:status.progress.total progressCompleted:status.progress.completed];
    } else if (status.activity == kCBLReplicatorIdle) {
        NSLog(@"Replication kCBLReplicatorIdle");
        response = [CBLite jsonSyncStatus:@"IDLE" withDb:dbName withType:r progressTotal:status.progress.total progressCompleted:status.progress.completed];
    } else if (status.activity == kCBLReplicatorBusy) {
        NSLog(@"%@", [NSString stringWithFormat:@"Replication Busy Replication %@ %llu di %llu", dbName, status.progress.completed, status.progress.total]);
        response = [CBLite jsonSyncStatus:@"BUSY" withDb:dbName withType:r progressTotal:status.progress.total progressCompleted:status.progress.completed];
    }
    return response;
}

+ (NSString *)jsonSyncStatus:(NSString *)status withDb:(NSString *)db withType:(NSString *)type progressTotal:(uint64_t)total progressCompleted:(uint64_t)completed {
    
    return [NSString stringWithFormat:@"{\"db\":\"%@\",\"type\": \"%@\", \"total\": \"%llu\", \"completed\": \"%llu\" ,\"message\":\"%@\" }", db, type, total, completed, status];
    
}

- (CBLQueryExpression *)setComparision:(NSDictionary *)item {
    NSString *property = item[@"property"];
    NSString *comparison = item[@"comparison"];
    CBLQueryExpression *nativeQuery;
    if ([comparison isEqualToString:@"equalTo"]) {
        if ([property isEqualToString:@"COUCHBASE_ID"]) {
            NSString *value = item[@"value"];
            nativeQuery = [[CBLQueryMeta id] equalTo:[CBLQueryExpression value:value]];
        } else {
            NSString *value = item[@"value"];
            nativeQuery = [[CBLQueryExpression property:property] equalTo:[CBLQueryExpression value:value]];
        }
    } else if ([comparison isEqualToString:@"add"]) {
        NSString *value = item[@"value"];
        nativeQuery = [[CBLQueryExpression property:property] add:[CBLQueryExpression value:value]];
    } else if ([comparison isEqualToString:@"between"]) {
        NSArray *valueArray = item[@"value"];
        if ([valueArray count] == 2) {
            nativeQuery = [[CBLQueryExpression property:property] between:valueArray[0] and:valueArray[1]];
        }
    } else if ([comparison isEqualToString:@"collate"]) {
        //        nativeQuery = [[CBLQueryExpression property:property] collate:<#(CBLQueryCollation*)collation#>];
    } else if ([comparison isEqualToString:@"divide"]) {
        NSString *value = item[@"value"];
        nativeQuery = [[CBLQueryExpression property:property] divide:[CBLQueryExpression value:value]];
    } else if ([comparison isEqualToString:@"greaterThan"]) {
        NSString *value = item[@"value"];
        nativeQuery = [[CBLQueryExpression property:property] greaterThan:[CBLQueryExpression value:value]];
    } else if ([comparison isEqualToString:@"greaterThanOrEqualTo"]) {
        NSString *value = item[@"value"];
        nativeQuery = [[CBLQueryExpression property:property] greaterThanOrEqualTo:[CBLQueryExpression value:value]];
    } else if ([comparison isEqualToString:@"in"]) {
        NSArray *expressionArray;
        if ([item[@"value"] isKindOfClass:[NSArray class]]) {
            NSArray *valueObject = item[@"value"];
            NSMutableArray *expressionMutableArray = [NSMutableArray array];
            if (valueObject.count > 0){
                for (NSString *item in valueObject) {
                    [expressionMutableArray addObject:[CBLQueryExpression value:item]];
                }
                expressionArray = expressionMutableArray;
            }
        } else {
            NSObject *valueObject = item[@"value"];
            NSMutableArray *expressionMutableArray = [NSMutableArray array];
            expressionArray = expressionMutableArray;
            [expressionMutableArray addObject:[CBLQueryExpression value:valueObject]];
        }
        if (expressionArray != NULL){
            if ([property isEqualToString:@"COUCHBASE_ID"]) {
                nativeQuery = [[CBLQueryMeta id] in:expressionArray];
            } else {
                nativeQuery = [[CBLQueryExpression property:property] in:expressionArray];
            }
        }
    } else if ([comparison isEqualToString:@"is"]) {
        NSString *value = item[@"value"];
        nativeQuery = [[CBLQueryExpression property:property] is:[CBLQueryExpression value:value]];
    } else if ([comparison isEqualToString:@"isNot"]) {
        NSString *value = item[@"value"];
        nativeQuery = [[CBLQueryExpression property:property] isNot:[CBLQueryExpression value:value]];
    } else if ([comparison isEqualToString:@"isNullOrMissing"]) {
        nativeQuery = [[CBLQueryExpression property:property] isNullOrMissing];
    } else if ([comparison isEqualToString:@"lessThan"]) {
        NSString *value = item[@"value"];
        nativeQuery = [[CBLQueryExpression property:property] lessThan:[CBLQueryExpression value:value]];
    } else if ([comparison isEqualToString:@"lessThanOrEqualTo"]) {
        NSString *value = item[@"value"];
        nativeQuery = [[CBLQueryExpression property:property] lessThanOrEqualTo:[CBLQueryExpression value:value]];
    } else if ([comparison isEqualToString:@"like"]) {
        NSString *value = item[@"value"];
        if ([property isEqualToString:@"COUCHBASE_ID"]) {
            nativeQuery = [[CBLQueryMeta id] like:[CBLQueryExpression value:value]];
        } else {
            nativeQuery = [[CBLQueryExpression property:property] like:[CBLQueryExpression value:value]];
        }
    } else if ([comparison isEqualToString:@"likeLower"]) {
        NSString *value = item[@"value"];
        nativeQuery = [[CBLQueryFunction lower:[CBLQueryExpression property:property]] like:[CBLQueryExpression value:value]];
    } else if ([comparison isEqualToString:@"modulo"]) {
        NSString *value = item[@"value"];
        nativeQuery = [[CBLQueryExpression property:property] modulo:[CBLQueryExpression value:value]];
    } else if ([comparison isEqualToString:@"multiply"]) {
        NSString *value = item[@"value"];
        nativeQuery = [[CBLQueryExpression property:property] multiply:[CBLQueryExpression value:value]];
    } else if ([comparison isEqualToString:@"notEqualTo"]) {
        NSString *value = item[@"value"];
        nativeQuery = [[CBLQueryExpression property:property] notEqualTo:[CBLQueryExpression value:value]];
    } else if ([comparison isEqualToString:@"notNullOrMissing"]) {
        nativeQuery = [[CBLQueryExpression property:property] notNullOrMissing];
    } else if ([comparison isEqualToString:@"regex"]) {
        NSString *value = item[@"value"];
        nativeQuery = [[CBLQueryExpression property:property] regex:[CBLQueryExpression value:value]];
    }
    return nativeQuery;
    
}

+ (NSNumber*) longUnixEpoch {
    return [NSNumber numberWithLongLong:[[NSDate date] timeIntervalSince1970] * 1000];
}

+ (NSNumber*) getElapsedTime:(NSNumber*)startTime  {
    NSNumber *currentTime = [NSNumber numberWithLongLong:[[NSDate date] timeIntervalSince1970] * 1000];
    return [NSNumber numberWithLongLong: [currentTime doubleValue] - [startTime doubleValue]];
}

void dispatch_cbl_async(NSThread *thread, dispatch_block_t block) {
    if ([NSThread currentThread] == thread) {block();}
    else {
        block = [block copy];
        [(id) block performSelector:@selector(invoke) onThread:thread withObject:nil waitUntilDone:NO];
    }
}

@end
