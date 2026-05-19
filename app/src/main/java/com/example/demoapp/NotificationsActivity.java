package com.example.demoapp;

import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.view.View;
import android.widget.ImageView;
import android.widget.ProgressBar;
import android.widget.TextView;
import android.widget.Toast;
import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.content.ContextCompat;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;
import androidx.swiperefreshlayout.widget.SwipeRefreshLayout;
import com.bumptech.glide.Glide;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.TimeZone;
import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class NotificationsActivity extends AppCompatActivity {

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
        if (backBtn != null) {
            backBtn.setOnClickListener(v -> finish());
        }

        recyclerView = findViewById(R.id.notificationsRecyclerView);
        swipeRefresh = findViewById(R.id.swipeRefresh);
        progressBar = findViewById(R.id.progressBar);
        emptyText = findViewById(R.id.emptyText);

        recyclerView.setLayoutManager(new LinearLayoutManager(this));
        adapter = new NotificationAdapter(notificationList, this::handleNotificationClick);
        recyclerView.setAdapter(adapter);

        swipeRefresh.setOnRefreshListener(this::fetchNotifications);

        fetchNotifications();
        handleIntent(getIntent());
    }

    @Override
    protected void onNewIntent(Intent intent) {
        super.onNewIntent(intent);
        handleIntent(intent);
    }

    private void handleIntent(Intent intent) {
        if (intent != null && intent.hasExtra("target_issue_id")) {
            long issueId = intent.getLongExtra("target_issue_id", 0);
            if (issueId != 0) {
                fetchIssueAndOpenDetails(issueId);
            }
        }
    }

    private void fetchNotifications() {
        String name = userPrefs.getString("name", "");
        String role = userPrefs.getString("role", "");
        if (name.isEmpty()) return;

        progressBar.setVisibility(View.VISIBLE);
        SupabaseApi api = SupabaseConfig.getApi();
        Map<String, String> filters = new HashMap<>();
        
        boolean isAdmin = role.equalsIgnoreCase("Admin") || role.equalsIgnoreCase("Administrator");
        if (isAdmin) {
            filters.put("user_name", "in.(\"" + name + "\",\"Admin\")");
        } else {
            filters.put("user_name", "eq." + name);
        }
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
                            emptyText.setVisibility(notificationList.isEmpty() ? View.VISIBLE : View.GONE);
                        }
                    }

                    @Override
                    public void onFailure(Call<List<Notification>> call, Throwable t) {
                        progressBar.setVisibility(View.GONE);
                        swipeRefresh.setRefreshing(false);
                    }
                });
    }

    private void handleNotificationClick(Notification notification) {
        markAsRead(notification);
        if (notification.getIssueId() != null && notification.getIssueId() != 0) {
            fetchIssueAndOpenDetails(notification.getIssueId());
        } else {
            showNotificationMessageCard(notification);
        }
    }

    private void fetchIssueAndOpenDetails(Long issueId) {
        progressBar.setVisibility(View.VISIBLE);
        SupabaseApi api = SupabaseConfig.getApi();
        Map<String, String> filters = new HashMap<>();
        filters.put("id", "eq." + issueId);

        api.getIssues(SupabaseConfig.API_KEY, "Bearer " + SupabaseConfig.API_KEY, filters)
                .enqueue(new Callback<List<Issue>>() {
                    @Override
                    public void onResponse(Call<List<Issue>> call, Response<List<Issue>> response) {
                        progressBar.setVisibility(View.GONE);
                        if (response.isSuccessful() && response.body() != null && !response.body().isEmpty()) {
                            showComplaintDetailDialog(response.body().get(0));
                        } else {
                            Toast.makeText(NotificationsActivity.this, "Complaint details not found", Toast.LENGTH_SHORT).show();
                        }
                    }
                    @Override
                    public void onFailure(Call<List<Issue>> call, Throwable t) {
                        progressBar.setVisibility(View.GONE);
                    }
                });
    }

    private void showComplaintDetailDialog(Issue issue) {
        View view = getLayoutInflater().inflate(R.layout.dialog_complaint_details, null);
        AlertDialog dialog = new AlertDialog.Builder(this).setView(view).setCancelable(true).create();

        ((TextView) view.findViewById(R.id.detailId)).setText("CMP" + issue.getId());
        ((TextView) view.findViewById(R.id.detailProblem)).setText(issue.getProblemType());
        ((TextView) view.findViewById(R.id.detailDescription)).setText(issue.getDescription());
        
        TextView statusTv = view.findViewById(R.id.detailStatus);
        String status = issue.getStatus();
        statusTv.setText(status);

        ImageView iconView = view.findViewById(R.id.notifIcon);

        if (status != null) {
            int color;
            if (status.equalsIgnoreCase("Pending")) {
                color = ContextCompat.getColor(this, R.color.status_pending);
            } else if (status.equalsIgnoreCase("Processing")) {
                color = ContextCompat.getColor(this, R.color.status_in_progress);
            } else if (status.equalsIgnoreCase("Resolved") || status.equalsIgnoreCase("Approved")) {
                color = ContextCompat.getColor(this, R.color.status_resolved);
            } else {
                color = ContextCompat.getColor(this, R.color.lavender_primary);
            }
            statusTv.setTextColor(color);
            if (iconView != null) iconView.setColorFilter(color);
        }

        ImageView detailImage = view.findViewById(R.id.detailImage);
        if (detailImage != null) {
            if (issue.getPhotoUrl() != null && !issue.getPhotoUrl().isEmpty()) {
                detailImage.setVisibility(View.VISIBLE);
                Glide.with(this).load(issue.getPhotoUrl()).placeholder(android.R.drawable.ic_menu_gallery).into(detailImage);
            } else {
                detailImage.setVisibility(View.GONE);
            }
        }

        view.findViewById(R.id.btnClose).setOnClickListener(v -> dialog.dismiss());
        if (dialog.getWindow() != null) {
            dialog.getWindow().setBackgroundDrawableResource(android.R.color.transparent);
        }
        dialog.show();
    }

    private void showNotificationMessageCard(Notification notification) {
        View view = getLayoutInflater().inflate(R.layout.dialog_notification_msg_card, null);
        AlertDialog dialog = new AlertDialog.Builder(this).setView(view).setCancelable(true).create();

        ((TextView) view.findViewById(R.id.notifDialogTitle)).setText(notification.getTitle());
        ((TextView) view.findViewById(R.id.notifDialogMessage)).setText(notification.getMessage());

        view.findViewById(R.id.btnNotifClose).setOnClickListener(v -> dialog.dismiss());
        if (dialog.getWindow() != null) {
            dialog.getWindow().setBackgroundDrawableResource(android.R.color.transparent);
        }
        dialog.show();
    }

    private String formatDateTime(String isoString) {
        if (isoString == null || isoString.isEmpty()) return "-";
        try {
            String cleanIso = isoString;
            if (cleanIso.endsWith("Z")) cleanIso = cleanIso.substring(0, cleanIso.length() - 1);
            String pattern = cleanIso.contains(".") ? "yyyy-MM-dd'T'HH:mm:ss.SSS" : "yyyy-MM-dd'T'HH:mm:ss";
            SimpleDateFormat inputFormat = new SimpleDateFormat(pattern, Locale.getDefault());
            inputFormat.setTimeZone(TimeZone.getTimeZone("UTC"));
            Date date = inputFormat.parse(cleanIso);
            
            SimpleDateFormat outputFormat = new SimpleDateFormat("dd MMM yyyy, hh:mm a", Locale.getDefault());
            outputFormat.setTimeZone(TimeZone.getDefault());
            return outputFormat.format(date);
        } catch (Exception e) {
            return isoString;
        }
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
                    @Override public void onFailure(Call<Void> call, Throwable t) {}
                });
    }
}
