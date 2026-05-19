package com.example.demoapp;

import android.app.Service;
import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Handler;
import android.os.IBinder;
import android.util.Log;
import androidx.annotation.Nullable;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class NotificationService extends Service {
    private static final String TAG = "NotificationService";
    private Handler handler = new Handler();
    private Runnable runnable;
    private int lastShownId = -1;
    private SharedPreferences userPrefs;
    private static final int POLL_INTERVAL = 10000; // 10 seconds

    @Override
    public void onCreate() {
        super.onCreate();
        userPrefs = getSharedPreferences("UserPrefs", MODE_PRIVATE);
        Log.d(TAG, "Notification Service Started");
        startPolling();
    }

    private void startPolling() {
        runnable = new Runnable() {
            @Override
            public void run() {
                checkNotifications();
                handler.postDelayed(this, POLL_INTERVAL);
            }
        };
        handler.postDelayed(runnable, POLL_INTERVAL);
    }

    private void checkNotifications() {
        String name = userPrefs.getString("name", "");
        String token = userPrefs.getString("access_token", "");
        String role = userPrefs.getString("role", "");
        
        if (name.isEmpty()) {
            Log.w(TAG, "Username is empty, skipping check");
            return;
        }

        String authHeader = token.startsWith("Bearer ") ? token : "Bearer " + token;
        SupabaseApi api = SupabaseConfig.getApi();
        Map<String, String> filters = new HashMap<>();
        
        boolean isAdmin = role.equalsIgnoreCase("Admin") || role.equalsIgnoreCase("Administrator");
        
        if (isAdmin) {
            filters.put("user_name", "in.(\"" + name + "\",\"Admin\")");
        } else {
            filters.put("user_name", "eq." + name);
        }
        
        filters.put("is_read", "is.false");
        filters.put("order", "id.desc");
        filters.put("limit", "1");

        api.getNotifications(SupabaseConfig.API_KEY, authHeader, filters)
                .enqueue(new Callback<List<Notification>>() {
                    @Override
                    public void onResponse(Call<List<Notification>> call, Response<List<Notification>> response) {
                        if (response.isSuccessful() && response.body() != null && !response.body().isEmpty()) {
                            Notification latest = response.body().get(0);
                            
                            Log.d(TAG, "Found unread notification: " + latest.getTitle() + " (ID: " + latest.getId() + ")");

                            if (latest.getId() > lastShownId) {
                                // Important: pass the issue_id to the helper
                                NotificationHelper.showNotification(getApplicationContext(), latest.getTitle(), latest.getMessage(), latest.getIssueId());
                                lastShownId = latest.getId();
                            }
                        }
                    }

                    @Override
                    public void onFailure(Call<List<Notification>> call, Throwable t) {
                        Log.e(TAG, "Polling failed: " + t.getMessage());
                    }
                });
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        return START_STICKY;
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        Log.d(TAG, "Notification Service Destroyed");
        if (handler != null && runnable != null) {
            handler.removeCallbacks(runnable);
        }
    }

    @Nullable
    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }
}
