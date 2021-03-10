var CBLite = function () {};

/*
 * --------------------------------------------------------------------------------
 * Database
 * --------------------------------------------------------------------------------
 */

/**
 * @param options:[dbName:string]
 * @returns OK { "message": "Database already opened",
 *               "elapsed": elapsedTime:long }
 *          OK { "message": "Database opened",
 *               "elapsed": elapsedTime:long }
 *          ERROR "Error opening database " + e.getLocalizedMessage()
 * 
 * Initializes a Couchbase Lite database with a given name and database
 * configuration. If the database does not yet exist, it will be created.
 */
CBLite.openDatabase = function openDatabase(successCallback, failCallback, options) {
    cordova.exec(successCallback, failCallback, "CBLite", "openDatabase", options);
};

/**
 * @param options:[dbName:string]
 * @returns OK { "message": "Database already closed",
 *               "elapsed": elapsedTime:long }
 *          OK { "message": "Database closed",
 *               "elapsed": elapsedTime:long }
 *          ERROR "Error closing database " + e.getLocalizedMessage()
 */
CBLite.closeDatabase = function closeDatabase(successCallback, failCallback, options) {
    cordova.exec(successCallback, failCallback, "CBLite", "closeDatabase", options);
};

/**
 * @param options:[dbName:string]
 * @returns OK { "message": "Database already deleted",
 *               "elapsed": elapsedTime:long }
 *          OK { "message": "Database deleted",
 *               "elapsed": elapsedTime:long }
 *          ERROR "Error deleting database " + e.getLocalizedMessage()
 */
CBLite.deleteDatabase = function deleteDatabase(successCallback, failCallback, options) {
    cordova.exec(successCallback, failCallback, "CBLite", "deleteDatabase", options);
};

/**
 * @param options:[dbName:string]
 * @returns 
 *          OK { "message": "Database change listener already added",
 *               "elapsed": elapsedTime:long }
 *          OK { "rows": Array[documentId:string] }
 *          ERROR "Database not found"
 *          ERROR "Error adding database change listener" + e.getLocalizedMessage()
 */
CBLite.addDatabaseChangeListener = function addDatabaseChangeListener(successCallback, failCallback, options) {
    cordova.exec(successCallback, failCallback, "CBLite", "addDatabaseChangeListener", options);
};

/**
 * @param options:[dbName:string]
 * @returns OK "Database change listener already removed"
 *          OK "Database change listener removed"
 *          ERROR "Database not found"
 *          ERROR "Error removing database change listener" + e.getLocalizedMessage()
 */
CBLite.removeDatabaseChangeListener = function removeDatabaseChangeListener(successCallback, failCallback, options) {
    cordova.exec(successCallback, failCallback, "CBLite", "removeDatabaseChangeListener", options);
};

/*
 * --------------------------------------------------------------------------------
 * Document
 * --------------------------------------------------------------------------------
 */

/**
 * Creates/updates a document requires a doc id to present, input data will 
 * always be written as winning revision
 * 
 * @param options:[dbName:string,
 *                 documentId:string,
 *                 document:jsonObject]
 * @returns OK "Document saved"
 *          ERROR "Database does not exist"
 *          ERROR "Must provide document id and document"
 *          ERROR "Error saving document " + e.getLocalizedMessage()
 */
CBLite.saveDocument = function saveDocument(successCallback, failCallback, options) {
    cordova.exec(successCallback, failCallback, "CBLite", "saveDocument", options);
};

/**
 * @param options:[dbName:string,
 *                 docId:string]
 * @returns OK jsonObject
 *          ERROR "db not found"
 *          ERROR "document not found"
 *          ERROR exception
 */
CBLite.getDocument = function getDocument(successCallback, failCallback, options) {
    cordova.exec(successCallback, failCallback, "CBLite", "getDocument", options);
};

/**
 * @param options:[dbName:string,
 *                 docId:string]
 * @returns OK "OK"
 *          ERROR "db not found"
 *          ERROR "document not found"
 *          ERROR exception
 */
CBLite.deleteDocument = function deleteDocument(successCallback, failCallback, options) {
    cordova.exec(successCallback, failCallback, "CBLite", "deleteDocument", options);
};

/**
 * @param options:[dbName:string,
 *                 documentId:string]
 * @returns OK "OK"
 *          ERROR "db not found"
 *          ERROR "document not found"
 *          ERROR exception
 */
CBLite.purgeDocument = function purgeDocument(successCallback, failCallback, options) {
    cordova.exec(successCallback, failCallback, "CBLite", "purgeDocument", options);
};

/**
 * @param options:[dbName:string,
 *                 documentIds:string[]]
 * @returns OK "OK"
 *          ERROR "db not found"
 *          ERROR "document not found"
 *          ERROR exception
 */
CBLite.purgeDocuments = function purgeDocuments(successCallback, failCallback, options) {
    cordova.exec(successCallback, failCallback, "CBLite", "purgeDocuments", options);
};

/**
 * @param options:[dbName:string,
 *                 docId:string,
 *                 name:string]
 * @returns result:string
 */
CBLite.getBlob = function getBlob(successCallback, failCallback, options) {
    cordova.exec(successCallback, failCallback, "CBLite", "getBlob", options);
};

/**
 * @param options:[dbName:string,
 *                 docId:string,
 *                 fileName:string,
 *                 name:string,
 *                 mime:string,
 *                 dirName:string]
 * @returns result:string
 */
CBLite.setBlob = function setBlob(successCallback, failCallback, options) {
    cordova.exec(successCallback, failCallback, "CBLite", "setBlob", options);
};

/*
 * --------------------------------------------------------------------------------
 * Replication
 * --------------------------------------------------------------------------------
 */

/**
 * Continuous Two way replication
 * @param options:[dbName:string,
 *                 syncUrl:string,
 *                 user:string,
 *                 pass:string
 *                 session:string,
 *                 replicationType: 'PushAndPull' | 'Push' | 'Pull',
 *                 channels:Array[string],
 *                 background:boolean
 *                 continuous:boolean]
 * @returns OK "OK"
 *          ERROR "db not found"
 *          ERROR exception
 */
CBLite.initReplicator = function initReplicator(successCallback, failCallback, options) {
    cordova.exec(successCallback, failCallback, "CBLite", "initReplicator", options);
};

/**
 * Continuous Two way replication
 * @param options:[dbName:string,
 *                 replicationType: 'PushAndPull' | 'Push' | 'Pull'
 * @returns OK "OK"
 *          ERROR "db not found"
 *          ERROR exception
 */
CBLite.startReplicator = function startReplicator(successCallback, failCallback, options) {
    cordova.exec(successCallback, failCallback, "CBLite", "startReplicator", options);
};

/**
 * @param options:[dbName:string,
 *                 replicationType: 'PushAndPull' | 'Push' | 'Pull']
 * @returns OK "OK"
 *          ERROR "db not found"
 *          ERROR exception
 */
CBLite.stopReplicator = function stopReplicator(successCallback, failCallback, options) {
    cordova.exec(successCallback, failCallback, "CBLite", "stopReplicator", options);
};

/**
 * @param options:[dbName:string,
 *                 replicationType: 'PushAndPull' | 'Push' | 'Pull']
 * @returns OK {"db": dbName::string,
 *                   "type": replicationType:string,
 *                   "status": <"stopped"|offline"|"connecting"|"idle"|"busy">
 *                   "total": total:string,
 *                   "completed": completed:string,
 *                   "error"? : error:any}
 *          ERROR "db not found"
 *          ERROR exception
 */
CBLite.addReplicatorChangeListener = function addReplicatorChangeListener(successCallback, failCallback, options) {
    cordova.exec(successCallback, failCallback, "CBLite", "addReplicatorChangeListener", options);
};

/**
 * @param options:[dbName:string,
 *                 replicationType: 'PushAndPull' | 'Push' | 'Pull']
 * @returns OK "replicator change listener removed"
 *          ERROR "db not found"
 *          ERROR exception
 */
CBLite.removeReplicatorChangeListener = function removeReplicatorChangeListener(successCallback, failCallback, options) {
    cordova.exec(successCallback, failCallback, "CBLite", "removeReplicatorChangeListener", options);
};

/**
 * @param options:[dbName:string,
 *                 replicationType: 'PushAndPull' | 'Push' | 'Pull']
 * @returns OK {"status": <"stopped"|offline"|"connecting"|"idle"|"busy">}
 *          ERROR "db not found"
 *          ERROR exception
 */
CBLite.getReplicatorStatus = function getReplicatorStatus(successCallback, failCallback, options) {
    cordova.exec(successCallback, failCallback, "CBLite", "getReplicatorStatus", options);
};

/*
 * --------------------------------------------------------------------------------
 * Query
 * --------------------------------------------------------------------------------
 */

/**
 * @param options:[dbName:string,
 *                 searchQuery:string[]]
 * @returns OK {"rows": any[]}
 *          ERROR "db not found"
 *          ERROR exception
 */
CBLite.query = function query(successCallback, failCallback, options) {
    cordova.exec(successCallback, failCallback, "CBLite", "query", options);
};

/*
 * --------------------------------------------------------------------------------
 * Misc
 * --------------------------------------------------------------------------------
 */

/**
 * @param options:[dbName:string]
 * @returns docCount:Number
 */
CBLite.info = function info(successCallback, failCallback, options) {
    cordova.exec(successCallback, failCallback, "CBLite", "info", options);
};

module.exports = CBLite;