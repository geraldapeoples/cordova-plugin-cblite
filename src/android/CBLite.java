package com.tickaudit.cordova.plugin;

import android.content.Context;
import android.os.SystemClock;
import android.util.Log;

import com.couchbase.lite.ArrayExpression;
import com.couchbase.lite.BasicAuthenticator;
import com.couchbase.lite.CouchbaseLite;
import com.couchbase.lite.CouchbaseLiteException;
import com.couchbase.lite.DataSource;
import com.couchbase.lite.Database;
import com.couchbase.lite.DatabaseConfiguration;
import com.couchbase.lite.Document;
import com.couchbase.lite.Endpoint;
import com.couchbase.lite.Expression;
import com.couchbase.lite.Function;
import com.couchbase.lite.IndexBuilder;
import com.couchbase.lite.Join;
import com.couchbase.lite.ListenerToken;
import com.couchbase.lite.MaintenanceType;
import com.couchbase.lite.Meta;
import com.couchbase.lite.MutableDocument;
import com.couchbase.lite.Ordering;
import com.couchbase.lite.Query;
import com.couchbase.lite.QueryBuilder;
import com.couchbase.lite.Replicator;
import com.couchbase.lite.ReplicatorConfiguration;
import com.couchbase.lite.Result;
import com.couchbase.lite.ResultSet;
import com.couchbase.lite.SelectResult;
import com.couchbase.lite.SessionAuthenticator;
import com.couchbase.lite.URLEndpoint;
import com.couchbase.lite.ValueIndexItem;
import com.google.gson.Gson;

import org.apache.cordova.CordovaInterface;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaWebView;
import org.apache.cordova.PluginResult;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.net.URI;
import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Date;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;

/**
 * This class echoes a string called from JavaScript.
 */
public class CBLite extends CordovaPlugin {

    private Context context;
    private static final String TAG = "CBLite";

    private static ArrayList<String> REPLICATION_TYPES = null;
    private static HashMap<String, Database> databases = null;
    private static HashMap<String, ListenerToken> databaseChangeListenerTokens = null;
    private static HashMap<String, Replicator> replicators = null;
    private static HashMap<String, ListenerToken> replicatorChangeListenerTokens = null;

    /*
     * Android lifecycle events
     */

    @Override
    public void onStart() {
        Log.d(TAG, "onStart() called");
    }

    @Override
    public void onResume(boolean multitasking) {
        Log.d(TAG, "onResume() called");
    }

    @Override
    public void onPause(boolean multitasking) {
        Log.d(TAG, "onPause() called");
    }

    @Override
    public void onStop() {
        Log.d(TAG, "onStop() called");
    }

    @Override
    public void onDestroy() {
        Log.d(TAG, "onDestroy() called");
    }

    /*
     * Cordova
     */

    @Override
    public void initialize(CordovaInterface cordova, CordovaWebView webView) {
        super.initialize(cordova, webView);
        try {
            context = this.cordova.getActivity();
            REPLICATION_TYPES = new ArrayList<String>(Arrays.asList("PushAndPull", "Push", "Pull"));
            databases = new HashMap<>();
            databaseChangeListenerTokens = new HashMap<>();
            replicators = new HashMap<>();
            replicatorChangeListenerTokens = new HashMap<>();
        } catch (final Exception e) {
            e.printStackTrace();
        }
    }

    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) {
        Log.d(TAG, "execute() called");

        /*
         * Database
         */
        if (action.equals("openDatabase")) {
            openDatabase(args, callbackContext);
            return true;
        } else if (action.equals("closeDatabase")) {
            closeDatabase(args, callbackContext);
            return true;
        } else if (action.equals("deleteDatabase")) {
            deleteDatabase(args, callbackContext);
            return true;
        } else if (action.equals("addDatabaseChangeListener")) {
            addDatabaseChangeListener(args, callbackContext);
            return true;
        } else if (action.equals("removeDatabaseChangeListener")) {
            removeDatabaseChangeListener(args, callbackContext);
            return true;
        }

        /*
         * Document
         */
        if (action.equals("saveDocument")) {
            saveDocument(args, callbackContext);
            return true;
        } else if (action.equals("getDocument")) {
            getDocument(args, callbackContext);
            return true;
        } else if (action.equals("deleteDocument")) {
            deleteDocument(args, callbackContext);
            return true;
        } else if (action.equals("purgeDocument")) {
            purgeDocument(args, callbackContext);
            return true;
        } else if (action.equals("purgeDocuments")) {
            purgeDocuments(args, callbackContext);
            return true;
        } else if (action.equals("getBlob")) {
            getBlob(args, callbackContext);
        } else if (action.equals("setBlob")) {
            setBlob(args, callbackContext);
            return true;
        }

        /*
         * Replication
         */
        if (action.equals("initReplicator")) {
            initReplicator(args, callbackContext);
            return true;
        } else if (action.equals("startReplicator")) {
            startReplicator(args, callbackContext);
            return true;
        } else if (action.equals("stopReplicator")) {
            stopReplicator(args, callbackContext);
            return true;
        } else if (action.equals("addReplicatorChangeListener")) {
            addReplicatorChangeListener(args, callbackContext);
            return true;
        } else if (action.equals("removeReplicatorChangeListener")) {
            removeReplicatorChangeListener(args, callbackContext);
            return true;
        } else if (action.equals("getReplicatorStatus")) {
            getReplicatorStatus(args, callbackContext);
            return true;
        }

        /*
         * Query
         */
        if (action.equals("query")) {
            query(args, callbackContext);
            return true;
        }

        /*
         * Misc
         */
        if (action.equals("info")) {
            info(args, callbackContext);
            return true;
        }

        return false;
    }

    /*
     * Database
     */

    private void openDatabase(final JSONArray args, final CallbackContext callbackContext) {
        Log.d(TAG, "openDatabase() called");
        long startTime = SystemClock.elapsedRealtime();
        cordova.getThreadPool().execute(() -> {

            PluginResult pluginResult;

            try {
                String dbName = args.getString(0);
                Log.d(TAG, "openDatabase() dbName=" + dbName);

                if (databases.containsKey(dbName)) {
                    Log.d(TAG, "openDatabase() databases.containsKey(dbName)");
                    createDatabaseIndexes(databases.get(dbName));
                    JSONObject response = new JSONObject();
                    response.put("message", "Database already opened");
                    response.put("elapsed", getElapsedTime(startTime));
                    pluginResult = new PluginResult(PluginResult.Status.OK, response);
                    callbackContext.sendPluginResult(pluginResult);
                    return;
                }

                CouchbaseLite.init(context);
                DatabaseConfiguration config = new DatabaseConfiguration();
                Database database = new Database(dbName, config);
                databases.put(dbName, database);
                Log.d(TAG, "openDatabase() Database created");
                createDatabaseIndexes(databases.get(dbName));
                JSONObject response = new JSONObject();
                response.put("message", "Database opened");
                response.put("elapsed", getElapsedTime(startTime));
                pluginResult = new PluginResult(PluginResult.Status.OK, response);
                callbackContext.sendPluginResult(pluginResult);
            } catch (final Exception e) {
                pluginResult = new PluginResult(PluginResult.Status.ERROR, e.getLocalizedMessage());
                callbackContext.sendPluginResult(pluginResult);
            }

        });
    }

    // TODO : Closing a database will Closing a database will stop all replicators, live queries and all listeners attached to it
    // Need to check if these replicators and listeners are removed altogether to understand full implications
    // This method is not actually used by TickAudit mobile app at the moment
    private void closeDatabase(final JSONArray args, final CallbackContext callbackContext) {
        Log.d(TAG, "closeDatabase() called");
        long startTime = SystemClock.elapsedRealtime();
        cordova.getThreadPool().execute(() -> {

            PluginResult pluginResult;

            try {
                String dbName = args.getString(0);

                if (!databases.containsKey(dbName)) {
                    JSONObject response = new JSONObject();
                    response.put("message", "Database already closed");
                    response.put("elapsed", getElapsedTime(startTime));
                    pluginResult = new PluginResult(PluginResult.Status.OK, response);
                    callbackContext.sendPluginResult(pluginResult);
                    return;
                }

                // TODO: Remove database change listeners, replicators and replicator change listeners

                databases.get(dbName).close();
                JSONObject response = new JSONObject();
                response.put("message", "Database closed");
                response.put("elapsed", getElapsedTime(startTime));
                pluginResult = new PluginResult(PluginResult.Status.OK, response);
                callbackContext.sendPluginResult(pluginResult);
            } catch (final Exception e) {
                pluginResult = new PluginResult(PluginResult.Status.ERROR, e.getLocalizedMessage());
                callbackContext.sendPluginResult(pluginResult);
            }

        });
    }

    // TODO : Deleting a database will stop all replicators, live queries and all listeners attached to it. Although attempting to close a closed database is not an error, attempting to delete a closed database is.
    // Need to check if these replicators and listeners are removed altogether to understand full implications
    // Need to understand if a closed database can be opened and then deleted
    // This method is not actually used by TickAudit mobile app at the moment
    private void deleteDatabase(final JSONArray args, final CallbackContext callbackContext) {
        Log.d(TAG, "deleteDatabase() called");
        long startTime = SystemClock.elapsedRealtime();
        cordova.getThreadPool().execute(() -> {

            PluginResult pluginResult;

            try {
                String dbName = args.getString(0);

                if (!databases.containsKey(dbName)) {
                    JSONObject response = new JSONObject();
                    response.put("message", "Database already deleted");
                    response.put("elapsed", getElapsedTime(startTime));
                    pluginResult = new PluginResult(PluginResult.Status.OK, response);
                    callbackContext.sendPluginResult(pluginResult);
                    return;
                }

                // TODO: Remove database change listeners, replicators and replicator change listeners

                Database db = databases.get(dbName);
                db.delete();
                databases.remove(dbName);
                JSONObject response = new JSONObject();
                response.put("message", "Database deleted");
                response.put("elapsed", getElapsedTime(startTime));
                pluginResult = new PluginResult(PluginResult.Status.OK, response);
                callbackContext.sendPluginResult(pluginResult);
            } catch (final Exception e) {
                pluginResult = new PluginResult(PluginResult.Status.ERROR, e.getLocalizedMessage());
                callbackContext.sendPluginResult(pluginResult);
            }

        });
    }

    private void addDatabaseChangeListener(final JSONArray args, final CallbackContext callbackContext) {
        Log.d(TAG, "addDatabaseChangeListener() called");
        long startTime = SystemClock.elapsedRealtime();

        PluginResult result = new PluginResult(PluginResult.Status.NO_RESULT);
        result.setKeepCallback(true);
        callbackContext.sendPluginResult(result);

        cordova.getThreadPool().execute(() -> {

            try {
                final String dbName = args.getString(0);

                if (!databases.containsKey(dbName)) {
                    PluginResult pluginResult = new PluginResult(PluginResult.Status.ERROR, "Database not found");
                    callbackContext.sendPluginResult(pluginResult);
                    return;
                }

                if (databaseChangeListenerTokens.containsKey(dbName)) {
                    JSONObject response = new JSONObject();
                    response.put("message", "Database change listener already added");
                    response.put("elapsed", getElapsedTime(startTime));
                    PluginResult pluginResult = new PluginResult(PluginResult.Status.OK, response);
                    callbackContext.sendPluginResult(pluginResult);
                    return;
                }

                final Database db = databases.get(dbName);
                ListenerToken databaseListenerToken = db.addChangeListener(change -> {

                    JSONArray docArray = new JSONArray();
                    for (String id : change.getDocumentIDs()) {
                        docArray.put(id);
                    }

                    HashMap<String, Object> response = new HashMap<String, Object>();
                    response.put("dbName", dbName);
                    response.put("rows", docArray);
                    PluginResult pluginResult = new PluginResult(PluginResult.Status.OK, new JSONObject(response));
                    pluginResult.setKeepCallback(true);
                    callbackContext.sendPluginResult(pluginResult);
                });
                databaseChangeListenerTokens.put(dbName, databaseListenerToken);

            } catch (final Exception e) {
                PluginResult pluginResult = new PluginResult(PluginResult.Status.ERROR, e.getLocalizedMessage());
                callbackContext.sendPluginResult(pluginResult);
            }

        });
    }

    private void removeDatabaseChangeListener(final JSONArray args, final CallbackContext callbackContext) {
        Log.d(TAG, "removeDatabaseChangeListener() called");
        long startTime = SystemClock.elapsedRealtime();
        cordova.getThreadPool().execute(() -> {

            PluginResult pluginResult;

            try {
                final String dbName = args.getString(0);

                if (!databases.containsKey(dbName)) {
                    pluginResult = new PluginResult(PluginResult.Status.ERROR, "Database not found");
                    callbackContext.sendPluginResult(pluginResult);
                    return;
                }

                if (!databaseChangeListenerTokens.containsKey(dbName)) {
                    JSONObject response = new JSONObject();
                    response.put("message", "Database change listener already removed");
                    response.put("elapsed", getElapsedTime(startTime));
                    pluginResult = new PluginResult(PluginResult.Status.OK, response);
                    callbackContext.sendPluginResult(pluginResult);
                    return;
                }

                ListenerToken listenerToken = databaseChangeListenerTokens.get(dbName);

                final Database db = databases.get(dbName);
                db.removeChangeListener(listenerToken);
                databaseChangeListenerTokens.remove(dbName);

                JSONObject response = new JSONObject();
                response.put("message", "Database change listener removed");
                response.put("elapsed", getElapsedTime(startTime));
                pluginResult = new PluginResult(PluginResult.Status.OK, response);
                callbackContext.sendPluginResult(pluginResult);

            } catch (final Exception e) {
                pluginResult = new PluginResult(PluginResult.Status.ERROR, e.getLocalizedMessage());
                callbackContext.sendPluginResult(pluginResult);
            }
        });
    }

    /*
     * Replication
     */

    private void initReplicator(final JSONArray args, final CallbackContext callbackContext) {
        Log.d(TAG, "initReplicator() called");
        long startTime = SystemClock.elapsedRealtime();
        cordova.getThreadPool().execute(() -> {

            PluginResult pluginResult;

            try {

                String dbName = args.getString(0);
                String syncURL = args.getString(1);
                String user = args.getString(2);
                String pass = args.getString(3);
                String session = args.getString(4);
                String replicationType = args.getString(5);
                JSONArray channels = args.getJSONArray(6);
                Boolean background = args.getBoolean(7); // background does not apply to Android
                Boolean continous = args.getBoolean(8);

                if (!databases.containsKey(dbName)) {
                    pluginResult = new PluginResult(PluginResult.Status.ERROR, "Database does not exist");
                    callbackContext.sendPluginResult(pluginResult);
                    return;
                }

                Endpoint target = new URLEndpoint(new URI(syncURL));
                Database db = databases.get(dbName);

                ReplicatorConfiguration config = new ReplicatorConfiguration(db, target);
                switch (replicationType) {
                    case "PushAndPull":
                        config.setReplicatorType(ReplicatorConfiguration.ReplicatorType.PUSH_AND_PULL);
                        break;
                    case "Push":
                        config.setReplicatorType(ReplicatorConfiguration.ReplicatorType.PUSH);
                        break;
                    case "Pull":
                        config.setReplicatorType(ReplicatorConfiguration.ReplicatorType.PULL);
                        break;
                    default:
                        pluginResult = new PluginResult(PluginResult.Status.ERROR, "Must provide a valid replication type");
                        callbackContext.sendPluginResult(pluginResult);
                        return;
                }

                if (channels.length() > 0) {
                    List<String> channelsList = new ArrayList<>();
                    for (int i = 0; i < channels.length(); i++) {
                        channelsList.add(channels.getString(i));
                    }
                    config.setChannels(channelsList);
                }
                config.setContinuous(continous);

                if (session != null) {
                    config.setAuthenticator(new SessionAuthenticator(session));
                } else {
                    config.setAuthenticator(new BasicAuthenticator(user, pass));
                }

                /*
                 * Replicator start returns void, use a replication change listener to get the
                 * status of replication - see addReplicatorChangeListener below.
                 */
                Replicator replicator = new Replicator(config);
                String replicatorName = dbName + replicationType;
                replicators.put(replicatorName, replicator);

                JSONObject response = new JSONObject();
                response.put("message", "Replicator initialised");
                response.put("elapsed", getElapsedTime(startTime));
                pluginResult = new PluginResult(PluginResult.Status.OK, response);
                callbackContext.sendPluginResult(pluginResult);
            } catch (Exception e) {
                pluginResult = new PluginResult(PluginResult.Status.ERROR, e.getLocalizedMessage());
                callbackContext.sendPluginResult(pluginResult);
            }

        });
    }

    private void startReplicator(final JSONArray args, final CallbackContext callbackContext) {
        Log.d(TAG, "initReplicator() called");
        long startTime = SystemClock.elapsedRealtime();
        cordova.getThreadPool().execute(() -> {

            PluginResult pluginResult;

            try {

                final String dbName = args.getString(0);
                String replicationType = args.getString(1);

                if (!databases.containsKey(dbName)) {
                    pluginResult = new PluginResult(PluginResult.Status.ERROR, "Database does not exist");
                    callbackContext.sendPluginResult(pluginResult);
                    return;
                }

                String replicatorName = dbName + replicationType;
                if (!replicators.containsKey(replicatorName)) {
                    pluginResult = new PluginResult(PluginResult.Status.ERROR, "Replicator does not exist");
                    callbackContext.sendPluginResult(pluginResult);
                    return;
                }

                /*
                 * Replicator start returns void, use a replication change listener to get the
                 * status of replication - see addReplicatorChangeListener below.
                 */
                Replicator replicator = replicators.get(replicatorName);
                replicator.start(false);

                JSONObject response = new JSONObject();
                response.put("message", "Replicator started");
                response.put("elapsed", getElapsedTime(startTime));
                pluginResult = new PluginResult(PluginResult.Status.OK, response);
                callbackContext.sendPluginResult(pluginResult);
            } catch (Exception e) {
                pluginResult = new PluginResult(PluginResult.Status.ERROR, e.getLocalizedMessage());
                callbackContext.sendPluginResult(pluginResult);
            }

        });
    }

    private void stopReplicator(final JSONArray args, final CallbackContext callbackContext) {
        Log.d(TAG, "stopReplicator() called");
        long startTime = SystemClock.elapsedRealtime();
        cordova.getThreadPool().execute(() -> {

            PluginResult pluginResult;

            try {
                final String dbName = args.getString(0);
                String replicationType = args.getString(1);

                String replicatorName = dbName + replicationType;
                if (!replicators.containsKey(replicatorName)) {
                    pluginResult = new PluginResult(PluginResult.Status.ERROR, "Replicator not initialised");
                    callbackContext.sendPluginResult(pluginResult);
                    return;
                }

                Replicator replicator = replicators.get(replicatorName);
                replicator.stop();
                replicators.remove(dbName + replicationType);

                JSONObject response = new JSONObject();
                response.put("message", "Replicator stopped");
                response.put("elapsed", getElapsedTime(startTime));
                pluginResult = new PluginResult(PluginResult.Status.OK, response);
                callbackContext.sendPluginResult(pluginResult);
            } catch (final Exception e) {
                pluginResult = new PluginResult(PluginResult.Status.ERROR, e.getLocalizedMessage());
                callbackContext.sendPluginResult(pluginResult);
            }

        });
    }

    private void addReplicatorChangeListener(final JSONArray args, final CallbackContext callbackContext) {
        Log.d(TAG, "addReplicatorChangeListener() called");
        long startTime = SystemClock.elapsedRealtime();

        PluginResult result = new PluginResult(PluginResult.Status.NO_RESULT);
        result.setKeepCallback(true);
        callbackContext.sendPluginResult(result);

        cordova.getThreadPool().execute(() -> {

            try {
                final String dbName = args.getString(0);
                final String replicationType = args.getString(1);

                String replicatorName = dbName + replicationType;
                if (!replicators.containsKey(replicatorName)) {
                    PluginResult pluginResult = new PluginResult(PluginResult.Status.ERROR, "Replicator not initialised");
                    callbackContext.sendPluginResult(pluginResult);
                    return;
                }

                if (replicatorChangeListenerTokens.containsKey(dbName + "-" + replicationType)) {
                    JSONObject response = new JSONObject();
                    response.put("message", "Replicator change listener already added");
                    response.put("elapsed", getElapsedTime(startTime));
                    PluginResult pluginResult = new PluginResult(PluginResult.Status.OK, response);
                    callbackContext.sendPluginResult(pluginResult);
                    return;
                }

                Replicator replicator = replicators.get(replicatorName);
                ListenerToken replicatorListenerToken = replicator.addChangeListener(change -> {
                    HashMap<String, Object> response = new HashMap<>();
                    response.put("dbName", dbName);
                    response.put("replicationType", replicationType);
                    response.put("status", change.getStatus().getActivityLevel().toString().toLowerCase());
                    response.put("total", Long.toString(change.getStatus().getProgress().getTotal()));
                    response.put("completed", Long.toString(change.getStatus().getProgress().getCompleted()));
                    CouchbaseLiteException error = change.getStatus().getError();
                    if (error != null) {
                        response.put("error", change.getStatus().getError());
                    }
                    PluginResult pluginResult = new PluginResult(PluginResult.Status.OK, new JSONObject(response));
                    pluginResult.setKeepCallback(true);
                    callbackContext.sendPluginResult(pluginResult);
                });
                replicatorChangeListenerTokens.put(dbName + "-" + replicationType, replicatorListenerToken);

            } catch (final Exception e) {
                PluginResult pluginResult = new PluginResult(PluginResult.Status.ERROR, e.getLocalizedMessage());
                callbackContext.sendPluginResult(pluginResult);
            }
        });
    }

    private void removeReplicatorChangeListener(final JSONArray args, final CallbackContext callbackContext) {
        Log.d(TAG, "removeReplicatorChangeListener() called");
        long startTime = SystemClock.elapsedRealtime();
        cordova.getThreadPool().execute(() -> {

            try {
                final String dbName = args.getString(0);
                final String replicationType = args.getString(1);

                String replicatorName = dbName + replicationType;
                if (!replicators.containsKey(replicatorName)) {
                    PluginResult pluginResult = new PluginResult(PluginResult.Status.ERROR, "Replicator not initialised");
                    callbackContext.sendPluginResult(pluginResult);
                    return;
                }

                if (!replicatorChangeListenerTokens.containsKey(replicatorName)) {
                    JSONObject response = new JSONObject();
                    response.put("message", "Replicator change listener already removed");
                    response.put("elapsed", getElapsedTime(startTime));
                    PluginResult pluginResult = new PluginResult(PluginResult.Status.OK, response);
                    callbackContext.sendPluginResult(pluginResult);
                    return;
                }

                Replicator replicator = replicators.get(replicatorName);
                ListenerToken replicatorChangeListenerToken = replicatorChangeListenerTokens.get(dbName + "-" + replicationType);

                replicator.removeChangeListener(replicatorChangeListenerToken);
                replicatorChangeListenerTokens.remove(dbName + "-" + replicationType);

                JSONObject response = new JSONObject();
                response.put("message", "Replicator change listener removed");
                response.put("elapsed", getElapsedTime(startTime));
                PluginResult pluginResult = new PluginResult(PluginResult.Status.OK, response);
                callbackContext.sendPluginResult(pluginResult);

            } catch (final Exception e) {
                PluginResult pluginResult = new PluginResult(PluginResult.Status.ERROR, e.getLocalizedMessage());
                callbackContext.sendPluginResult(pluginResult);
            }
        });
    }

    private void getReplicatorStatus(final JSONArray args, final CallbackContext callbackContext) {
        Log.d(TAG, "getReplicatorStatus() called");
        long startTime = SystemClock.elapsedRealtime();
        cordova.getThreadPool().execute(() -> {

            PluginResult pluginResult;

            try {
                final String dbName = args.getString(0);
                final String replicationType = args.getString(1);

                String replicatorName = dbName + replicationType;
                if (!replicators.containsKey(replicatorName)) {
                    pluginResult = new PluginResult(PluginResult.Status.ERROR, "Replicator not initialised");
                    callbackContext.sendPluginResult(pluginResult);
                    return;
                }

                Replicator replicator = replicators.get(replicatorName);
                JSONObject response = new JSONObject();
                response.put("status", replicator.getStatus().getActivityLevel().toString().toLowerCase());
                response.put("message", "Replicator status");
                response.put("elapsed", getElapsedTime(startTime));
                pluginResult = new PluginResult(PluginResult.Status.OK, response);
                callbackContext.sendPluginResult(pluginResult);
            } catch (final Exception e) {
                pluginResult = new PluginResult(PluginResult.Status.ERROR, e.getLocalizedMessage());
                callbackContext.sendPluginResult(pluginResult);
            }

        });
    }

    /*
     * Document
     */

    private void saveDocument(final JSONArray args, final CallbackContext callbackContext) {
        Log.d(TAG, "saveDocument() called");
        long startTime = SystemClock.elapsedRealtime();
        cordova.getThreadPool().execute(() -> {

            PluginResult pluginResult;

            try {
                String dbName = args.getString(0);
                String documentId = args.getString(1);
                JSONObject document = args.getJSONObject(2);

                if (!databases.containsKey(dbName)) {
                    pluginResult = new PluginResult(PluginResult.Status.ERROR, "Database does not exist");
                    callbackContext.sendPluginResult(pluginResult);
                    return;
                }

                if (args.isNull(1) || args.isNull(2)) {
                    pluginResult = new PluginResult(PluginResult.Status.ERROR, "Must provide document id and document");
                    callbackContext.sendPluginResult(pluginResult);
                    return;
                }

                Database db = databases.get(dbName);

                Map<String, Object> map = new HashMap<String, Object>();
                Gson gson = new Gson();
                map = (Map<String, Object>) gson.fromJson(document.toString(), map.getClass());
                MutableDocument mDoc = new MutableDocument(documentId, map);
                if (mDoc.contains("id")) {
                    mDoc.remove("id");
                }
                db.save(mDoc);

                JSONObject response = new JSONObject();
                response.put("message", "Document saved");
                response.put("elapsed", getElapsedTime(startTime));
                pluginResult = new PluginResult(PluginResult.Status.OK, response);
                callbackContext.sendPluginResult(pluginResult);

            } catch (final Exception e) {
                pluginResult = new PluginResult(PluginResult.Status.ERROR, e.getLocalizedMessage());
                callbackContext.sendPluginResult(pluginResult);
            }

        });
    }

    private void getDocument(final JSONArray args, final CallbackContext callbackContext) {
        Log.d(TAG, "getDocument() called");
        long startTime = SystemClock.elapsedRealtime();
        cordova.getThreadPool().execute(() -> {

            PluginResult pluginResult;

            try {
                String dbName = args.getString(0);
                String documentId = args.getString(1);

                if (!databases.containsKey(dbName)) {
                    pluginResult = new PluginResult(PluginResult.Status.ERROR, "Database does not exist");
                    callbackContext.sendPluginResult(pluginResult);
                    return;
                }

                Database db = databases.get(dbName);
                Document document = db.getDocument(documentId);
                if (document == null) {
                    pluginResult = new PluginResult(PluginResult.Status.ERROR, "Document not found");
                    callbackContext.sendPluginResult(pluginResult);
                    return;
                }

                Map mapDoc = document.toMap();
                mapDoc.put("id", documentId);
                JSONObject jsonDoc = new JSONObject(mapDoc);

                JSONObject response = new JSONObject();
                response.put("message", "Document found");
                response.put("document", jsonDoc);
                response.put("elapsed", getElapsedTime(startTime));
                pluginResult = new PluginResult(PluginResult.Status.OK, response);
                callbackContext.sendPluginResult(pluginResult);

            } catch (final Exception e) {
                pluginResult = new PluginResult(PluginResult.Status.ERROR, e.getLocalizedMessage());
                callbackContext.sendPluginResult(pluginResult);
            }

        });
    }

    private void deleteDocument(final JSONArray args, final CallbackContext callbackContext) {
        Log.d(TAG, "deleteDocument() called");
        long startTime = SystemClock.elapsedRealtime();
        cordova.getThreadPool().execute(() -> {

            PluginResult pluginResult;

            try {
                String dbName = args.getString(0);
                String documentId = args.getString(1);

                if (!databases.containsKey(dbName)) {
                    pluginResult = new PluginResult(PluginResult.Status.ERROR, "Database does not exist");
                    callbackContext.sendPluginResult(pluginResult);
                    return;
                }

                Database db = databases.get(dbName);
                Document document = db.getDocument(documentId);
                if (document == null) {
                    pluginResult = new PluginResult(PluginResult.Status.ERROR, "Document not found");
                    callbackContext.sendPluginResult(pluginResult);
                    return;
                }

                db.delete(document);

                JSONObject response = new JSONObject();
                response.put("message", "Document deleted");
                response.put("elapsed", getElapsedTime(startTime));
                pluginResult = new PluginResult(PluginResult.Status.OK, response);
                callbackContext.sendPluginResult(pluginResult);

            } catch (final Exception e) {
                pluginResult = new PluginResult(PluginResult.Status.ERROR, e.getLocalizedMessage());
                callbackContext.sendPluginResult(pluginResult);
            }

        });
    }

    private void purgeDocument(final JSONArray args, final CallbackContext callbackContext) {
        Log.d(TAG, "purgeDocument() called");
        long startTime = SystemClock.elapsedRealtime();
        cordova.getThreadPool().execute(() -> {

            PluginResult pluginResult;

            try {
                String dbName = args.getString(0);
                String documentId = args.getString(1);

                if (!databases.containsKey(dbName)) {
                    pluginResult = new PluginResult(PluginResult.Status.ERROR, "Database does not exist");
                    callbackContext.sendPluginResult(pluginResult);
                    return;
                }

                Database db = databases.get(dbName);
                Document document = db.getDocument(documentId);

                if (document == null) {
                    pluginResult = new PluginResult(PluginResult.Status.ERROR, "Document not found");
                    callbackContext.sendPluginResult(pluginResult);
                    return;
                }

                db.purge(document);

                JSONObject response = new JSONObject();
                response.put("message", "Document purged");
                response.put("elapsed", getElapsedTime(startTime));
                pluginResult = new PluginResult(PluginResult.Status.OK, response);
                callbackContext.sendPluginResult(pluginResult);
            } catch (final Exception e) {
                pluginResult = new PluginResult(PluginResult.Status.ERROR, e.getLocalizedMessage());
            }
            callbackContext.sendPluginResult(pluginResult);

        });
    }

    private void purgeDocuments(final JSONArray args, final CallbackContext callbackContext) {
        Log.d(TAG, "purgeDocuments() called");
        long startTime = SystemClock.elapsedRealtime();
        cordova.getThreadPool().execute(() -> {

            PluginResult pluginResult;

            try {
                String dbName = args.getString(0);
                JSONArray documentIds = args.getJSONArray(1);

                if (!databases.containsKey(dbName)) {
                    pluginResult = new PluginResult(PluginResult.Status.ERROR, "Database does not exist");
                    callbackContext.sendPluginResult(pluginResult);
                    return;
                }

                Database db = databases.get(dbName);
                for (int i = 0; i < documentIds.length(); i++) {
                    String documentId = documentIds.getString(i);
                    Document document = db.getDocument(documentId);
                    if (document != null) {
                        db.purge(document);
                    }
                }

                JSONObject response = new JSONObject();
                response.put("message", "Documents purged");
                response.put("elapsed", getElapsedTime(startTime));
                pluginResult = new PluginResult(PluginResult.Status.OK, response);
                callbackContext.sendPluginResult(pluginResult);
            } catch (final Exception e) {
                pluginResult = new PluginResult(PluginResult.Status.ERROR, e.getLocalizedMessage());
                callbackContext.sendPluginResult(pluginResult);
            }

        });
    }

    // TODO: Implement getBlob
    private void getBlob(final JSONArray args, final CallbackContext callbackContext) {
        Log.d(TAG, "getBlob() called");
        //        cordova.getThreadPool().execute(new Runnable() {
        //            public void run() {
        //                try {
        //                    String dbName = args.getString(0);
        //                    String filePath = cordova.getActivity().getApplicationContext().getFilesDir() + "/" + args.getString(5) + "/" + args.getString(2);
        //                    FileInputStream stream = new FileInputStream(filePath);
        //                    Document document = databases.get(dbName).getDocument(args.getString(1));
        //                    UnsavedRevision newRev = document.getCurrentRevision().createRevision();
        //                    newRev.setAttachment(args.getString(3), args.getString(4), stream);
        //                    newRev.save();
        //                    callbackContext.success("sucess");
        //                } catch (final Exception e) {
        //                    callbackContext.error("putAttachment failure");
        //                }
        //            }
        //        });
    }

    // TODO: Implement setBlob
    private void setBlob(final JSONArray args, final CallbackContext callbackContext) {
        Log.d(TAG, "setBlob() called");
        //        cordova.getThreadPool().execute(new Runnable() {
        //            public void run() {
        //                try {
        //                    String dbName = args.getString(0);
        //                    Document document = databases.get(dbName).getDocument(args.getString(1));
        //                    Revision rev = document.getCurrentRevision();
        //                    List<Attachment> allAttachments = rev.getAttachments();
        //                    callbackContext.success(allAttachments.size());
        //                } catch (final Exception e) {
        //                    RaygunClient.send(e);
        //                    callbackContext.success(e.getMessage());
        //                }
        //            }
        //        });
    }

    /*
     * Query
     */

    public void query(final JSONArray args, final CallbackContext callbackContext) {
        Log.d(TAG, "query() called");
        long startTime = SystemClock.elapsedRealtime();
        /*
         *  database.query({
         *       select: [],                     // Leave empty to query for all
         *       from: "otherDatabaseName",      // Omit or set null to use current db
         *       where: [{ property: "firstName", comparison: "equalTo", value: "Osei" }],
         *       order: [{ property: "firstName", direction: "desc" }],
         *       limit: 2
         *   });
         */
        cordova.getThreadPool().execute(() -> {

            PluginResult pluginResult;

            try {
                String dbName = args.getString(0);
                JSONObject searchQuery = args.getJSONObject(1);

                if (!databases.containsKey(dbName)) {
                    pluginResult = new PluginResult(PluginResult.Status.ERROR, "Database does not exist");
                    callbackContext.sendPluginResult(pluginResult);
                    return;
                }

                SelectResult[] select = null;
                DataSource from = null;
                Join[] join = null;
                Expression where = null;
                Expression[] groupBy = null;
                Expression having = null;
                Ordering[] orderBy = null;
                Integer limit = null;
                Integer offset = null;

                /*
                 * Process "select" items
                 */
                if (!searchQuery.has("select") || searchQuery.getJSONArray("select").length() == 0) {
                    select = new SelectResult[2];
                    select[0] = SelectResult.all();
                    select[1] = SelectResult.expression(Meta.id);
                } else {
                    int selectLength = searchQuery.getJSONArray("select").length();
                    select = new SelectResult[selectLength];
                    JSONArray selectArray = searchQuery.getJSONArray("select");
                    for (int i = 0; i < selectLength; i++) {
                        String item = selectArray.getString(i);
                        if (item.equals("COUCHBASE_ID")) {
                            select[i] = SelectResult.expression(Meta.id);
                        } else if (item.equals("COUCHBASE_ALL")) {
                            select[i] = SelectResult.all();
                        } else {
                            select[i] = SelectResult.property(item);
                        }
                    }
                }

                /*
                 * Process "from" if is exists or use dbName
                 */
                if (searchQuery.has("from")) {
                    from = DataSource.database(databases.get(searchQuery.getString("from")));
                } else {
                    from = DataSource.database(databases.get(dbName));
                }

                /*
                 * Process "where"
                 */
                if (searchQuery.has("where")) {
                    int whereLength = searchQuery.getJSONArray("where").length();
                    JSONArray whereArray = searchQuery.getJSONArray("where");
                    for (int i = 0; i < whereLength; i++) {
                        JSONObject item = whereArray.getJSONObject(i);
                        String logicalOperator = item.getString("comparison");
                        if (logicalOperator.equals("and")) {
                            if (where == null) break;
                            i++;
                            item = whereArray.getJSONObject(i);
                            Expression whereExpr = setComparision(item);
                            if (whereExpr != null) {
                                where = where.and(whereExpr);
                            }
                        } else if (logicalOperator.equals("or")) {
                            if (where == null) break;
                            i++;
                            item = whereArray.getJSONObject(i);
                            Expression whereExpr = setComparision(item);
                            if (whereExpr != null) {
                                where = where.or(whereExpr);
                            }
                        } else {
                            Expression whereExpr = setComparision(item);
                            if (whereExpr != null) {
                                where = whereExpr;
                            }
                        }
                    }
                }

                /*
                 * Process "groupBy"
                 */
                if (searchQuery.has("groupBy")) {
                    int groupByLength = searchQuery.getJSONArray("groupBy").length();
                    JSONArray groupByArray = searchQuery.getJSONArray("groupBy");
                    groupBy = new Expression[groupByLength];
                    for (int i = 0; i < groupByLength; i++) {
                        groupBy[i] = Expression.property(groupByArray.getString(i));
                    }
                }

                /*
                 * Process "orderBy"
                 */
                if (searchQuery.has("orderBy")) {
                    int orderLength = searchQuery.getJSONArray("orderBy").length();
                    JSONArray orderByArray = searchQuery.getJSONArray("orderBy");
                    orderBy = new Ordering[orderLength];
                    for (int i = 0; i < orderLength; i++) {
                        String property = ((JSONObject) orderByArray.get(i)).getString("property");
                        String direction = ((JSONObject) orderByArray.get(i)).getString("direction");
                        if (property.equals("COUCHBASE_ID")) {
                            if (direction.equals("desc")) {
                                orderBy[i] = Ordering.expression(Meta.id).descending();
                            } else {
                                orderBy[i] = Ordering.expression(Meta.id).ascending();
                            }
                        } else {
                            if (direction.equals("desc")) {
                                orderBy[i] = Ordering.property(property).descending();
                            } else {
                                orderBy[i] = Ordering.property(property).ascending();
                            }
                        }
                    }
                }

                /*
                 * Process limit and offset
                 */
                if (!searchQuery.isNull("limit")) {
                    limit = searchQuery.getInt("limit");
                }

                if (!searchQuery.isNull("offset")) {
                    offset = searchQuery.getInt("offset");
                }

                /*
                 * Build the query
                 */
                Query query;
                if (where != null) {
                    if (groupBy != null) {
                        if (orderBy != null) {
                            if (limit != null) {
                                if (offset != null) {
                                    query = QueryBuilder.select(select).from(from).where(where).groupBy(groupBy).orderBy(orderBy).limit(Expression.intValue(limit), Expression.intValue(offset));
                                } else {
                                    query = QueryBuilder.select(select).from(from).where(where).groupBy(groupBy).orderBy(orderBy).limit(Expression.intValue(limit));
                                }
                            } else {
                                query = QueryBuilder.select(select).from(from).where(where).groupBy(groupBy).orderBy(orderBy);
                            }
                        } else {
                            if (limit != null) {
                                if (offset != null) {
                                    query = QueryBuilder.select(select).from(from).where(where).groupBy(groupBy).limit(Expression.intValue(limit), Expression.intValue(offset));
                                } else {
                                    query = QueryBuilder.select(select).from(from).where(where).groupBy(groupBy).limit(Expression.intValue(limit));
                                }
                            } else {
                                query = QueryBuilder.select(select).from(from).where(where).groupBy(groupBy);
                            }
                        }
                    } else {
                        if (orderBy != null) {
                            if (limit != null) {
                                if (offset != null) {
                                    query = QueryBuilder.select(select).from(from).where(where).orderBy(orderBy).limit(Expression.intValue(limit), Expression.intValue(offset));
                                } else {
                                    query = QueryBuilder.select(select).from(from).where(where).orderBy(orderBy).limit(Expression.intValue(limit));
                                }
                            } else {
                                query = QueryBuilder.select(select).from(from).where(where).orderBy(orderBy);
                            }
                        } else {
                            if (limit != null) {
                                if (offset != null) {
                                    query = QueryBuilder.select(select).from(from).where(where).limit(Expression.intValue(limit), Expression.intValue(offset));
                                } else {
                                    query = QueryBuilder.select(select).from(from).where(where).limit(Expression.intValue(limit));
                                }
                            } else {
                                query = QueryBuilder.select(select).from(from).where(where);
                            }
                        }
                    }
                } else {
                    if (groupBy != null) {
                        if (orderBy != null) {
                            if (limit != null) {
                                if (offset != null) {
                                    query = QueryBuilder.select(select).from(from).groupBy(groupBy).orderBy(orderBy).limit(Expression.intValue(limit), Expression.intValue(offset));
                                } else {
                                    query = QueryBuilder.select(select).from(from).groupBy(groupBy).orderBy(orderBy).limit(Expression.intValue(limit));
                                }
                            } else {
                                query = QueryBuilder.select(select).from(from).groupBy(groupBy).orderBy(orderBy);
                            }
                        } else {
                            if (limit != null) {
                                if (offset != null) {
                                    query = QueryBuilder.select(select).from(from).groupBy(groupBy).limit(Expression.intValue(limit), Expression.intValue(offset));
                                } else {
                                    query = QueryBuilder.select(select).from(from).groupBy(groupBy).limit(Expression.intValue(limit));
                                }
                            } else {
                                query = QueryBuilder.select(select).from(from).groupBy(groupBy);
                            }
                        }
                    } else {
                        if (orderBy != null) {
                            if (limit != null) {
                                if (offset != null) {
                                    query = QueryBuilder.select(select).from(from).orderBy(orderBy).limit(Expression.intValue(limit), Expression.intValue(offset));
                                } else {
                                    query = QueryBuilder.select(select).from(from).orderBy(orderBy).limit(Expression.intValue(limit));
                                }
                            } else {
                                query = QueryBuilder.select(select).from(from).orderBy(orderBy);
                            }
                        } else {
                            if (limit != null) {
                                if (offset != null) {
                                    query = QueryBuilder.select(select).from(from).limit(Expression.intValue(limit), Expression.intValue(offset));
                                } else {
                                    query = QueryBuilder.select(select).from(from).limit(Expression.intValue(limit));
                                }
                            } else {
                                query = QueryBuilder.select(select).from(from);
                            }
                        }
                    }
                }

                /*
                 * Execute the query
                 */
                final List<Result> resultList = query.execute().allResults();

                int i = 0;
                JSONArray resultArray = new JSONArray();
                for (Result result : resultList) {
                    Map resultMap = result.toMap();
                    resultArray.put(new JSONObject(resultMap));
                    i++;
                }

                JSONObject response = new JSONObject();
                response.put("message", "Documents queried");
                response.put("elapsed", getElapsedTime(startTime));
                response.put("rows", resultArray);
                pluginResult = new PluginResult(PluginResult.Status.OK, response);
                callbackContext.sendPluginResult(pluginResult);
            } catch (final Exception e) {
                pluginResult = new PluginResult(PluginResult.Status.ERROR, e.getMessage());
                callbackContext.sendPluginResult(pluginResult);
            }
        });
    }

    /*
     * Misc
     */

    private void info(final JSONArray args, final CallbackContext callbackContext) {
        Log.d(TAG, "info() called");
        long startTime = SystemClock.elapsedRealtime();
        cordova.getThreadPool().execute(() -> {

            PluginResult pluginResult;

            try {
                String dbName = args.getString(0);

                if (!databases.containsKey(dbName)) {
                    pluginResult = new PluginResult(PluginResult.Status.ERROR, "Database does not exist");
                    callbackContext.sendPluginResult(pluginResult);
                    return;
                }

                String databasePath = databases.get(dbName).getPath();

                JSONObject replicatorInfo = new JSONObject();

                Iterator replicatorsIterator = replicators.entrySet().iterator();
                while (replicatorsIterator.hasNext()) {
                    Map.Entry mapEntry = (Map.Entry) replicatorsIterator.next();
                    String replicatorName = mapEntry.getKey().toString();
                    String replicatorStatus = ((Replicator) mapEntry.getValue()).getStatus().toString();
                    replicatorInfo.put("Replicator-" + replicatorName, replicatorStatus);
                }

                Iterator replicatorChangeListenerTokensIterator = replicatorChangeListenerTokens.entrySet().iterator();
                while (replicatorChangeListenerTokensIterator.hasNext()) {
                    Map.Entry mapEntry = (Map.Entry) replicatorChangeListenerTokensIterator.next();
                    String replicatorChangeListenerName = mapEntry.getKey().toString();
                    String listenerToken = ((ListenerToken) mapEntry.getValue()).toString();
                    replicatorInfo.put("Listener-" + replicatorChangeListenerName, listenerToken);
                }

                JSONObject response = new JSONObject();
                response.put("message", "Info");
                response.put("databasePath", databasePath);
                response.put("replicatorInfo", replicatorInfo);
                response.put("elapsed", getElapsedTime(startTime));
                pluginResult = new PluginResult(PluginResult.Status.OK, response);
                callbackContext.sendPluginResult(pluginResult);

            } catch (final Exception e) {
                pluginResult = new PluginResult(PluginResult.Status.ERROR, e.getLocalizedMessage());
                callbackContext.sendPluginResult(pluginResult);
            }

        });
    }

    /*
     * Utils
     */

    private void createDatabaseIndexes(Database database) {
        try {
            String typeIndex = "TypeIndex";

            List<String> databaseIndexes = database.getIndexes();

            if (!databaseIndexes.contains(typeIndex)) {
                database.createIndex(
                        typeIndex,
                        IndexBuilder.valueIndex(ValueIndexItem.property("type"))
                );
                Log.d(TAG, "Database " + typeIndex + " created");
            }
        } catch (CouchbaseLiteException e) {
            Log.d(TAG, "Error creating database indexes " + e.getLocalizedMessage(), e);
        }
    }

    private Expression setComparision(JSONObject item) {
        Expression nativeQuery = null;
        try {
            String property = item.getString("property");
            String comparison = item.getString("comparison");

            if (comparison.equals("equalTo")) {
                String value = item.getString("value");
                if (property.equals("COUCHBASE_ID")) {
                    nativeQuery = (Meta.id).equalTo(Expression.value(value));
                } else {
                    nativeQuery = Expression.property(property).equalTo(Expression.value(value));
                }
            } else if (comparison.equals("add")) {
                String value = item.getString("value");
                nativeQuery = Expression.property(property).add(Expression.value(value));
            } else if (comparison.equals("between")) {
                JSONArray valueArray = item.getJSONArray("value");
                if (valueArray.length() == 2) {
                    nativeQuery = Expression.property(property).between(Expression.value(valueArray.get(0)), Expression.value(valueArray.get(1)));
                }
            } else if (comparison.equals("collate")) {
//                nativeQuery = Expression.property(property).collate(Expression.value(value));
            } else if (comparison.equals("divide")) {
                String value = item.getString("value");
                nativeQuery = Expression.property(property).divide(Expression.value(value));
            } else if (comparison.equals("greaterThan")) {
                String value = item.getString("value");
                nativeQuery = Expression.property(property).greaterThan(Expression.value(value));
            } else if (comparison.equals("greaterThanOrEqualTo")) {
                String value = item.getString("value");
                nativeQuery = Expression.property(property).greaterThanOrEqualTo(Expression.value(value));
            } else if (comparison.equals("in")) {
                Expression[] expressionArray = null;
                Object valueObject = item.get("value");
                if (valueObject instanceof JSONArray) {
                    int length = ((JSONArray) valueObject).length();
                    if (length > 0) {
                        expressionArray = new Expression[length];
                        for (int i = 0; i < length; i++) {
                            expressionArray[i] = Expression.value(((JSONArray) valueObject).getString(i));
                        }
                    }
                } else {
                    expressionArray = new Expression[1];
                    expressionArray[0] = Expression.value(((JSONArray) valueObject).getString(0));
                }
                if (expressionArray != null) {
                    if (property.equals("COUCHBASE_ID")) {
                        nativeQuery = (Meta.id).in(expressionArray);
                    } else {
                        nativeQuery = Expression.property(property).in(expressionArray);
                    }
                }
            } else if (comparison.equals("is")) {
                String value = item.getString("value");
                nativeQuery = Expression.property(property).is(Expression.value(value));
            } else if (comparison.equals("isNot")) {
                String value = item.getString("value");
                nativeQuery = Expression.property(property).isNot(Expression.value(value));
            } else if (comparison.equals("isNullOrMissing")) {
                nativeQuery = Expression.property(property).isNullOrMissing();
            } else if (comparison.equals("lessThan")) {
                String value = item.getString("value");
                nativeQuery = Expression.property(property).lessThan(Expression.value(value));
            } else if (comparison.equals("lessThanOrEqualTo")) {
                String value = item.getString("value");
                nativeQuery = Expression.property(property).lessThanOrEqualTo(Expression.value(value));
            } else if (comparison.equals("like")) {
                String value = item.getString("value");
                if (property.equals("COUCHBASE_ID")) {
                    nativeQuery = (Meta.id).like(Expression.value(value));
                } else {
                    nativeQuery = Expression.property(property).like(Expression.value(value));
                }
            } else if (comparison.equals("likeLower")) {
                String value = item.getString("value");
                nativeQuery = (Function.lower(Expression.property(property))).like(Expression.value(value));
                // nativeQuery = Function.lower(Expression.property(property)).like(Expression.value(value));
            } else if (comparison.equals("modulo")) {
                String value = item.getString("value");
                nativeQuery = Expression.property(property).modulo(Expression.value(value));
            } else if (comparison.equals("multiply")) {
                String value = item.getString("value");
                nativeQuery = Expression.property(property).multiply(Expression.value(value));
            } else if (comparison.equals("notEqualTo")) {
                String value = item.getString("value");
                nativeQuery = Expression.property(property).notEqualTo(Expression.value(value));
            } else if (comparison.equals("notNullOrMissing")) {
                nativeQuery = Expression.property(property).notNullOrMissing();
            } else if (comparison.equals("regex")) {
                String value = item.getString("value");
                nativeQuery = Expression.property(property).regex(Expression.value(value));
            }
        } catch (JSONException e) {
            e.printStackTrace();
        }

        return nativeQuery;
    }

    private long getElapsedTime(long time) throws JSONException {
        return SystemClock.elapsedRealtime() - time;
    }

}
