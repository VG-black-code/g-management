package com.example.demoapp;

import android.content.SharedPreferences;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.widget.ImageView;
import android.widget.ProgressBar;
import android.widget.TextView;
import android.widget.Toast;
import androidx.appcompat.app.AppCompatActivity;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;
import androidx.swiperefreshlayout.widget.SwipeRefreshLayout;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class NotificationsActivity extends AppCompatActivity {

    private static final String TAG = "NotificationsActivity";
    private RecyclerView recyclerView;
    private SwipeRefreshLayout swipeRefresh;
    private ProgressBar progressBar;
    private TextView emptyText;
    private NotificationAdapter adapter;
    private List<Notification> notificationList = new ArrayList<>();
    private SharedPreferences userPrefs;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        ThemeHelper.applyTheme(this);
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_notifications);

        userPrefs = getSharedPreferences("UserPrefs", MODE_PRIVATE);

        ImageView backBtn = findViewById(R.id.backBtn);
        backBtn.setOnClickListener(v -> finish());

        recyclerView = findViewById(R.id.notificationsRecyclerView);
        swipeRefresh = findViewById(R.id.swipeRefresh);
        progressBar = findViewById(R.id.progressBar);
        emptyText = findViewById(R.id.emptyText);

        recyclerView.setLayoutManager(new LinearLayoutManager(this));
        adapter = new NotificationAdapter(notificationList, this::markAsRead);
        recyclerView.setAdapter(adapter);

        swipeRefresh.setOnRefreshListener(this::fetchNotifications);

        fetchNotifications();
    }

    private void fetchNotifications() {
        String name = userPrefs.getString("name", "");
        if (name.isEmpty()) return;

        progressBar.setVisibility(View.VISIBLE);
        
        SupabaseApi api = SupabaseConfig.getApi();

        Map<String, String> filters = new HashMap<>();
        filters.put("user_name", "eq." + name);
        filters.put("order", "id.desc");

        api.getNotifications(SupabaseConfig.API_KEY, "Bearer " + SupabaseConfig.API_KEY, filters)
                .enqueue(new Callback<List<Notification>>() {
                    @Override
                    public void onResponse(Call<List<Notification>> call, Response<List<Notification>> response) {
                        progressBar.setVisibility(View.GONE);
                        swipeRefresh.setRefreshing(false);
                        if (response.isSuccessful() && response.body() != null) {
                            notificationList.clear();
                            notificationList.addAll(response.body());
                            adapter.notifyDataSetChanged();
                            
                            if (notificationList.isEmpty()) {
                                emptyText.setVisibility(View.VISIBLE);
                            } else {
                                emptyText.setVisibility(View.GONE);
                            }
                        }
                    }

                    @Override
                    public void onFailure(Call<List<Notification>> call, Throwable t) {
                        progressBar.setVisibility(View.GONE);
                        swipeRefresh.setRefreshing(false);
                        Toast.makeText(NotificationsActivity.this, "Network Error: " + t.getMessage(), Toast.LENGTH_SHORT).show();
                    }
                });
    }

    private void markAsRead(Notification notification) {
        if (notification.isRead()) return;

        SupabaseApi api = SupabaseConfig.getApi();

        Map<String, String> filters = new HashMap<>();
        filters.put("id", "eq." + notification.getId());

        Map<String, Object> updateData = new HashMap<>();
        updateData.put("is_read", true);

        api.updateNotification(SupabaseConfig.API_KEY, "Bearer " + SupabaseConfig.API_KEY, filters, updateData)
                .enqueue(new Callback<Void>() {
                    @Override
                    public void onResponse(Call<Void> call, Response<Void> response) {
                        if (response.isSuccessful()) {
                            notification.setRead(true);
                            adapter.notifyDataSetChanged();
                        }
                    }

                    @Override
                    public void onFailure(Call<Void> call, Throwable t) {
                        Log.e(TAG, "Failed to mark as read", t);
                    }
                });
    }
}
