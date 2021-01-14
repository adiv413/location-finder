package com.example.location_sender;

import android.os.Bundle;
import android.telephony.SmsManager;
import android.util.Log;
import android.os.Build.VERSION;
import android.os.Build.VERSION_CODES;

import io.flutter.app.FlutterActivity;
import io.flutter.plugins.GeneratedPluginRegistrant;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "send_SMS";

    @Override
    public void onCreate(Bundle savedInstanceState) {

        super.onCreate(savedInstanceState);
        GeneratedPluginRegistrant.registerWith(this);

        new MethodChannel(getFlutterView(), CHANNEL).setMethodCallHandler(
                new MethodCallHandler() {
                    @Override
                    public void onMethodCall(MethodCall call, Result result) {
                        // Note: this method is invoked on the main thread.
                        if (call.method.equals("sendSMS")) {
                            String num = call.argument("number");
                            String msg = call.argument("message");
                            sendSMS(num, msg, result);
                        } else {
                            result.notImplemented();
                        }
                    }
                });
    }

    private void sendSMS(String phoneNo, String msg, MethodChannel.Result result) {
        try {
            if (VERSION.SDK_INT >= VERSION_CODES.LOLLIPOP) {
                SmsManager smsManager = SmsManager.getDefault();
                smsManager.sendTextMessage(phoneNo, null, msg, null, null);
                result.success("SMS Sent");
            } else {
                result.error("UNAVAILABLE","SMS Capability not available on this device.","");
            }
        } catch (Exception ex) {
            ex.printStackTrace();
            result.error("ERROR","Error sending SMS.","");
        }
    }
}
