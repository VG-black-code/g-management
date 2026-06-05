package com.example.demoapp;

import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.ProgressBar;
import android.widget.TextView;
import android.widget.Toast;

import androidx.appcompat.app.AppCompatActivity;
import androidx.core.content.ContextCompat;
import androidx.swiperefreshlayout.widget.SwipeRefreshLayout;

import com.bumptech.glide.Glide;
import com.google.gson.Gson;

import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.TimeZone;

import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class MyIssuesActivity extends AppCompatActivity {

    private static final String TAG = "MyIssuesActivity";
    private LinearLayout issuesContainer;
    private TextView noIssuesText;
    private ProgressBar progressBar;
    private SwipeRefreshLayout swipeRefreshLayout;
    private SharedPreferences userPrefs;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        ThemeHelper.applyTheme(this);
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_my_issues);

        issuesContainer = findViewById(R.id.issuesContainer);
        noIssuesText = findViewById(R.id.noIssuesText);
        progressBar = findViewById(R.id.progressBar);
        swipeRefreshLayout = findViewById(R.id.swipeRefreshLayout);
        userPrefs = getSharedPreferences("UserPrefs", MODE_PRIVATE);

        View backBtn = findViewById(R.id.backBtn);
        if (backBtn != null) {
            backBtn.setOnClickListener(v -> finish());
        }

        ImageView refreshBtn = findViewById(R.id.refreshBtn);
        if (refreshBtn != null) {
            refreshBtn.setOnClickListener(v -> fetchIssuesFromBackend());
        }

        setupRefreshLayout();
        fetchIssuesFromBackend();
    }

    private void setupRefreshLayout() {
        if (swipeRefreshLayout != null) {
            swipeRefreshLayout.setOnRefreshListener(this::fetchIssuesFromBackend);
        }
    }

    private void fetchIssuesFromBackend() {
        if (swipeRefreshLayout != null && !swipeRefreshLayout.isRefreshing()) {
            if (progressBar != null) progressBar.setVisibility(View.VISIBLE);
        }
        noIssuesText.setVisibility(View.GONE);

        String currentUserId = userPrefs.getString("user_id", "");
        String token = userPrefs.getString("access_token", "");

        if (currentUserId.isEmpty() || token.isEmpty()) {
            if (progressBar != null) progressBar.setVisibility(View.GONE);
            if (swipeRefreshLayout != null) swipeRefreshLayout.setRefreshing(false);
            noIssuesText.setVisibility(View.VISIBLE);
            noIssuesText.setText("Please login again to see your issues.");
            
            Toast.makeText(this, "Session expired. Please login again.", Toast.LENGTH_LONG).show();
            startActivity(new Intent(this, MainActivity.class));
            finishAffinity();
            return;
        }
        
        String authHeader = token.startsWith("Bearer ") ? token : "Bearer " + token;

        SupabaseApi api = SupabaseConfig.getApi();
        Map<String, String> filters = new HashMap<>();
        filters.put("user_id", "eq." + currentUserId);
        filters.put("order", "id.desc");

        api.getIssues(SupabaseConfig.API_KEY, authHeader, filters)
                .enqueue(new Callback<List<Issue>>() {
                    @Override
                    public void onResponse(Call<List<Issue>> call, Response<List<Issue>> response) {
                        if (progressBar != null) progressBar.setVisibility(View.GONE);
                        if (swipeRefreshLayout != null) swipeRefreshLayout.setRefreshing(false);
                        
                        if (response.isSuccessful() && response.body() != null) {
                            displayIssues(response.body());
                        } else if (response.code() == 401) {
                            Toast.makeText(MyIssuesActivity.this, "Session expired. Please login again.", Toast.LENGTH_LONG).show();
                            userPrefs.edit().putBoolean("is_logged_in", false).apply();
                            startActivity(new Intent(MyIssuesActivity.this, MainActivity.class));
                            finishAffinity();
                        } else {
                            noIssuesText.setVisibility(View.VISIBLE);
                        }
                    }

                    @Override
                    public void onFailure(Call<List<Issue>> call, Throwable t) {
                        if (progressBar != null) progressBar.setVisibility(View.GONE);
                        if (swipeRefreshLayout != null) swipeRefreshLayout.setRefreshing(false);
                        noIssuesText.setVisibility(View.VISIBLE);
                        noIssuesText.setText("Failed to connect to server.");
                    }
                });
    }

    private void displayIssues(List<Issue> issues) {
        issuesContainer.removeAllViews();
        
        if (issues.isEmpty()) {
            noIssuesText.setVisibility(View.VISIBLE);
            return;
        }

        noIssuesText.setVisibility(View.GONE);
        for (Issue issue : issues) {
            View view = LayoutInflater.from(this).inflate(R.layout.item_complaint, issuesContainer, false);
            
            ImageView itemImage = view.findViewById(R.id.itemImage);
            TextView title = view.findViewById(R.id.itemTitle);
            TextView room = view.findViewById(R.id.itemRoom);
            TextView status = view.findViewById(R.id.itemStatus);
            TextView date = view.findViewById(R.id.itemDate);

            title.setText(issue.getProblemType());
            room.setText("Location: " + issue.getLocation());
            
            String statusText = issue.getStatus();
            status.setText("Status: " + statusText);
            
            if (statusText != null) {
                if (statusText.equalsIgnoreCase("Pending")) {
                    status.setTextColor(ContextCompat.getColor(this, R.color.status_pending));
                } else if (statusText.equalsIgnoreCase("Processing")) {
                    status.setTextColor(ContextCompat.getColor(this, R.color.status_in_progress));
                } else if (statusText.equalsIgnoreCase("Resolved") || statusText.equalsIgnoreCase("Approved")) {
                    status.setTextColor(ContextCompat.getColor(this, R.color.status_resolved));
                }
            }
            
            date.setText("Sent: " + formatDateShort(issue.getCreatedAt()));

            if (issue.getPhotoUrl() != null && !issue.getPhotoUrl().isEmpty()) {
                Glide.with(this).load(issue.getPhotoUrl()).into(itemImage);
            } else {
                itemImage.setImageResource(android.R.drawable.ic_menu_gallery);
            }

            view.setOnClickListener(v -> showComplaintDetail(issue));
            issuesContainer.addView(view);
        }
    }

    private void showComplaintDetail(Issue issue) {
        Intent intent = new Intent(this, IssueDetailActivity.class);
        intent.putExtra("issue_data", new Gson().toJson(issue));
        startActivity(intent);
    }

    private String formatDateShort(String isoString) {
        if (isoString == null || isoString.isEmpty()) return "N/A";
        try {
            String cleanIso = isoString.endsWith("Z") ? isoString.substring(0, isoString.length() - 1) : isoString;
            String pattern = cleanIso.contains(".") ? "yyyy-MM-dd'T'HH:mm:ss.SSS" : "yyyy-MM-dd'T'HH:mm:ss";
            SimpleDateFormat inputFormat = new SimpleDateFormat(pattern, Locale.getDefault());
            inputFormat.setTimeZone(TimeZone.getTimeZone("UTC"));
            Date date = inputFormat.parse(cleanIso);
            SimpleDateFormat outputFormat = new SimpleDateFormat("MMM dd", Locale.getDefault());
            outputFormat.setTimeZone(TimeZone.getDefault());
            return outputFormat.format(date);
        } catch (Exception e) { return isoString; }
    }

    @Override
    protected void onResume() {
        super.onResume();
        fetchIssuesFromBackend();
    }
}
