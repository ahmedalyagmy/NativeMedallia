package com.medallia;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import android.util.Log;

import com.facebook.react.bridge.ActivityEventListener;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.BaseActivityEventListener;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.modules.core.DeviceEventManagerModule;

import org.json.JSONObject;

public class MedalliaNativeModule extends ReactContextBaseJavaModule {
    private static final String MODULE_NAME = "MedalliaNativeModule";
    private static final String TAG = "MedalliaNative";
    private ReactApplicationContext reactContext;
    private Promise medalliaPromise;

    private final ActivityEventListener activityEventListener = new BaseActivityEventListener() {
        @Override
        public void onActivityResult(Activity activity, int requestCode, int resultCode, Intent data) {
            if (requestCode == 1001) { // Medallia request code
                if (resultCode == Activity.RESULT_OK) {
                    handleMedalliaResult(data, "submit");
                } else {
                    handleMedalliaResult(data, "cancel");
                }
            }
        }
    };

    public MedalliaNativeModule(ReactApplicationContext reactContext) {
        super(reactContext);
        this.reactContext = reactContext;
        reactContext.addActivityEventListener(activityEventListener);
    }

    @Override
    public String getName() {
        return MODULE_NAME;
    }

    @ReactMethod
    public void showFeedbackForm(Promise promise) {
        try {
            this.medalliaPromise = promise;
            
            // استرجاع البيانات المحفوظة
            android.content.SharedPreferences prefs = reactContext.getSharedPreferences("MedalliaData", Context.MODE_PRIVATE);
            String username = prefs.getString("username", "");
            String password = prefs.getString("password", "");
            String medalliaToken = prefs.getString("medalliaToken", "default-medallia-token");
            String surveyId = prefs.getString("surveyId", "default-survey-id");

            Log.d(TAG, "Showing Medallia feedback form for user: " + username);

            // إنشاء Intent لفتح Medallia feedback form
            Intent intent = new Intent(reactContext, MedalliaFeedbackActivity.class);
            intent.putExtra("username", username);
            intent.putExtra("password", password);
            intent.putExtra("medalliaToken", medalliaToken);
            intent.putExtra("surveyId", surveyId);
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);

            reactContext.startActivity(intent);

            // إرسال إشارة أن النموذج جاهز
            WritableMap params = Arguments.createMap();
            params.putString("status", "ready");
            params.putString("message", "Medallia feedback form is ready");
            sendEvent("MedalliaFeedbackReady", params);

        } catch (Exception e) {
            Log.e(TAG, "Error showing feedback form: " + e.getMessage());
            promise.reject("ERROR", e.getMessage());
        }
    }

    @ReactMethod
    public void injectUserData(String username, String password, String medalliaToken, String surveyId, Promise promise) {
        try {
            Log.d(TAG, "Injecting user data: " + username);
            
            // حفظ جميع البيانات في SharedPreferences
            android.content.SharedPreferences prefs = reactContext.getSharedPreferences("MedalliaData", Context.MODE_PRIVATE);
            android.content.SharedPreferences.Editor editor = prefs.edit();
            editor.putString("username", username);
            editor.putString("password", password);
            editor.putString("medalliaToken", medalliaToken);
            editor.putString("surveyId", surveyId);
            editor.apply();

            WritableMap params = Arguments.createMap();
            params.putString("username", username);
            params.putString("status", "injected");
            sendEvent("UserDataInjected", params);
            
            promise.resolve("User data injected successfully");
        } catch (Exception e) {
            Log.e(TAG, "Error injecting user data: " + e.getMessage());
            promise.reject("ERROR", e.getMessage());
        }
    }

    @ReactMethod
    public void handleFormSubmit(String formData, Promise promise) {
        try {
            Log.d(TAG, "Form submitted with data: " + formData);
            
            WritableMap params = Arguments.createMap();
            params.putString("formData", formData);
            params.putString("action", "submit");
            sendEvent("MedalliaFormAction", params);
            
            promise.resolve("Form submitted successfully");
        } catch (Exception e) {
            Log.e(TAG, "Error handling form submit: " + e.getMessage());
            promise.reject("ERROR", e.getMessage());
        }
    }

    @ReactMethod
    public void handleFormCancel(Promise promise) {
        try {
            Log.d(TAG, "Form cancelled");
            
            WritableMap params = Arguments.createMap();
            params.putString("action", "cancel");
            sendEvent("MedalliaFormAction", params);
            
            promise.resolve("Form cancelled");
        } catch (Exception e) {
            Log.e(TAG, "Error handling form cancel: " + e.getMessage());
            promise.reject("ERROR", e.getMessage());
        }
    }

    @ReactMethod
    public void getStoredUserData(Promise promise) {
        try {
            android.content.SharedPreferences prefs = reactContext.getSharedPreferences("MedalliaData", Context.MODE_PRIVATE);
            String username = prefs.getString("username", "");
            String password = prefs.getString("password", "");
            String medalliaToken = prefs.getString("medalliaToken", "");
            String surveyId = prefs.getString("surveyId", "");
            
            WritableMap result = Arguments.createMap();
            result.putString("username", username);
            result.putString("password", password);
            result.putString("medalliaToken", medalliaToken);
            result.putString("surveyId", surveyId);
            
            promise.resolve(result);
        } catch (Exception e) {
            Log.e(TAG, "Error getting stored user data: " + e.getMessage());
            promise.reject("ERROR", e.getMessage());
        }
    }

    @ReactMethod
    public void handleNotification(ReadableMap notificationData, Promise promise) {
        try {
            String type = notificationData.hasKey("type") ? notificationData.getString("type") : "";
            String username = notificationData.hasKey("username") ? notificationData.getString("username") : "";
            String password = notificationData.hasKey("password") ? notificationData.getString("password") : "";
            String medalliaToken = notificationData.hasKey("medalliaToken") ? notificationData.getString("medalliaToken") : "";
            String surveyId = notificationData.hasKey("surveyId") ? notificationData.getString("surveyId") : "";
            
            Log.d(TAG, "Handling notification of type: " + type);
            
            if ("feedback_request".equals(type)) {
                // حفظ البيانات من الـ notification
                android.content.SharedPreferences prefs = reactContext.getSharedPreferences("MedalliaData", Context.MODE_PRIVATE);
                android.content.SharedPreferences.Editor editor = prefs.edit();
                editor.putString("username", username);
                editor.putString("password", password);
                editor.putString("medalliaToken", medalliaToken);
                editor.putString("surveyId", surveyId);
                editor.apply();
                
                // عرض نموذج التقييم تلقائياً
                showFeedbackForm(promise);
            } else {
                promise.resolve("Notification handled but no action taken");
            }
        } catch (Exception e) {
            Log.e(TAG, "Error handling notification: " + e.getMessage());
            promise.reject("ERROR", e.getMessage());
        }
    }

    private void handleMedalliaResult(Intent data, String action) {
        try {
            String resultData = data != null ? data.getStringExtra("result") : "";
            
            WritableMap params = Arguments.createMap();
            params.putString("action", action);
            params.putString("data", resultData);
            sendEvent("MedalliaFormAction", params);
            
            if (medalliaPromise != null) {
                medalliaPromise.resolve("Medallia form completed with action: " + action);
                medalliaPromise = null;
            }
        } catch (Exception e) {
            Log.e(TAG, "Error handling Medallia result: " + e.getMessage());
            if (medalliaPromise != null) {
                medalliaPromise.reject("ERROR", e.getMessage());
                medalliaPromise = null;
            }
        }
    }

    private void sendEvent(String eventName, WritableMap params) {
        reactContext
            .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
            .emit(eventName, params);
    }
}
