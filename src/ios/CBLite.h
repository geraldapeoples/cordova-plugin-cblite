#import <Cordova/CDVPlugin.h>

@interface CBLite : CDVPlugin

// Database
- (void)openDatabase:(CDVInvokedUrlCommand*)urlCommand;
- (void)closeDatabase:(CDVInvokedUrlCommand*)urlCommand;
- (void)deleteDatabase:(CDVInvokedUrlCommand*)urlCommand;
- (void)addDatabaseChangeListener:(CDVInvokedUrlCommand*)urlCommand;
- (void)removeDatabaseChangeListener:(CDVInvokedUrlCommand*)urlCommand;

// Document
- (void)saveDocument:(CDVInvokedUrlCommand*)urlCommand;
- (void)getDocument:(CDVInvokedUrlCommand*)urlCommand;
- (void)deleteDocument:(CDVInvokedUrlCommand*)urlCommand;
- (void)purgeDocument:(CDVInvokedUrlCommand*)urlCommand;
- (void)getBlob:(CDVInvokedUrlCommand*)urlCommand;
- (void)setBlob:(CDVInvokedUrlCommand*)urlCommand;

// Replication
- (void)initReplicator:(CDVInvokedUrlCommand*)urlCommand;
- (void)startReplicator:(CDVInvokedUrlCommand*)urlCommand;
- (void)stopReplicator:(CDVInvokedUrlCommand*)urlCommand;
- (void)addReplicatorChangeListener:(CDVInvokedUrlCommand*)urlCommand;
- (void)removeReplicatorChangeListener:(CDVInvokedUrlCommand*)urlCommand;
- (void)getReplicatorStatus:(CDVInvokedUrlCommand*)urlCommand;

// Query
- (void)query:(CDVInvokedUrlCommand*)urlCommand;

// Misc
- (void)info:(CDVInvokedUrlCommand*)urlCommand;

@end
