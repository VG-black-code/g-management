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
    private int lastNotificationId = -1;
    private SharedPreferences userPrefs;
    private static final int POLL_INTERVAL = 15000; // Increased to 15 seconds to reduce load

    @Override
    public void onCreate() {
        super.onCreate(savedInstanceState);
        userPrefs = getSharedPreferences("UserPrefs", MODE_PRIVATE);
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
        if (name.isEmpty()) return;

        SupabaseApi api = SupabaseConfig.getApi();

        Map<String, String> filters = new HashMap<>();
        filters.put("user_name", "eq." + name);
        filters.put("order", "id.desc");
        filters.put("limit", "1");

        api.getNotifications(SupabaseConfig.API_KEY, "Bearer " + SupabaseConfig.API_KEY, filters)
                .enqueue(new Callback<List<Notification>>() {
                    @Override
                    public void onResponse(Call<List<Notification>> call, Response<List<Notification>> response) {
                        if (response.isSuccessful() && response.body() != null && !response.body().isEmpty()) {
                            Notification latest = response.body().get(0);
                            int currentId = latest.getId();
                            
                            if (lastNotificationId != -1 && currentId > lastNotificationId) {
                                NotificationHelper.showNotification(getApplicationContext(), latest.getTitle(), latest.getMessage());
                            }
                            lastNotificationId = currentId;
                        }
                    }

                    @Override
                    public void onFailure(Call<List<Notification>> call, Throwable t) {
                        Log.e(TAG, "Failed to fetch notifications: " + t.getMessage());
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
