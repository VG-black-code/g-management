package com.example.demoapp;

import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.ProgressBar;
import android.widget.TextView;
import android.widget.Toast;

import androidx.appcompat.app.AppCompatActivity;
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

        // Use the centralized stable API instance
        SupabaseApi api = SupabaseConfig.getApi();

        Map<String, String> filters = new HashMap<>();
        filters.put("user_id", "eq." + currentUserId);

        api.getIssues(SupabaseConfig.API_KEY, authHeader, filters)
                .enqueue(new Callback<List<Issue>>() {
                    @Override
                    public void onResponse(Call<List<Issue>> call, Response<List<Issue>> response) {
                        if (progressBar != null) progressBar.setVisibility(View.GONE);
                        if (swipeRefreshLayout != null) swipeRefreshLayout.setRefreshing(false);
                        
                        if (response.isSuccessful() && response.body() != null) {
                            displayIssues(response.body());
                        } else if (response.code() == 401) {
                            Log.e(TAG, "Unauthorized: Session expired");
                            Toast.makeText(MyIssuesActivity.this, "Session expired. Please login again.", Toast.LENGTH_LONG).show();
                            userPrefs.edit().putBoolean("is_logged_in", false).apply();
                            startActivity(new Intent(MyIssuesActivity.this, MainActivity.class));
                            finishAffinity();
                        } else {
                            Log.e(TAG, "Fetch Failed: " + response.code());
                            Toast.makeText(MyIssuesActivity.this, "Failed to load issues: " + response.code(), Toast.LENGTH_SHORT).show();
                            noIssuesText.setVisibility(View.VISIBLE);
                        }
                    }

                    @Override
                    public void onFailure(Call<List<Issue>> call, Throwable t) {
                        if (progressBar != null) progressBar.setVisibility(View.GONE);
                        if (swipeRefreshLayout != null) swipeRefreshLayout.setRefreshing(false);
                        Log.e(TAG, "Error: " + t.getMessage());
                        Toast.makeText(MyIssuesActivity.this, "Network Error: Check internet or Supabase project status", Toast.LENGTH_SHORT).show();
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
        for (int i = issues.size() - 1; i >= 0; i--) {
            Issue issue = issues.get(i);
            View complaintView = LayoutInflater.from(this).inflate(R.layout.item_complaint, issuesContainer, false);
            
            ImageView itemImage = complaintView.findViewById(R.id.itemImage);
            TextView title = complaintView.findViewById(R.id.itemTitle);
            TextView room = complaintView.findViewById(R.id.itemRoom);
            TextView status = complaintView.findViewById(R.id.itemStatus);
            TextView date = complaintView.findViewById(R.id.itemDate);
            TextView processDate = complaintView.findViewById(R.id.itemProcessDate);
            TextView resolveDate = complaintView.findViewById(R.id.itemResolveDate);

            title.setText(issue.getProblemType());
            room.setText("Location: " + issue.getLocation());
            status.setText("Status: " + issue.getStatus());
            
            date.setText("Sent: " + formatDate(issue.getCreatedAt()));

            if (issue.getProcessingAt() != null) {
                processDate.setVisibility(View.VISIBLE);
                processDate.setText("Proc: " + formatDate(issue.getProcessingAt()));
            }

            if (issue.getResolvedAt() != null) {
                resolveDate.setVisibility(View.VISIBLE);
                resolveDate.setText("Res: " + formatDate(issue.getResolvedAt()));
            }

            if (issue.getPhotoUrl() != null && !issue.getPhotoUrl().isEmpty()) {
                Glide.with(this).load(issue.getPhotoUrl()).into(itemImage);
                itemImage.setOnClickListener(v -> {
                    Intent fullScreenIntent = new Intent(this, FullScreenImageActivity.class);
                    fullScreenIntent.putExtra("image_url", issue.getPhotoUrl());
                    startActivity(fullScreenIntent);
                });
            } else {
                itemImage.setImageResource(android.R.drawable.ic_menu_gallery);
            }

            complaintView.setOnClickListener(v -> {
                Intent intent = new Intent(MyIssuesActivity.this, IssueDetailActivity.class);
                intent.putExtra("issue_data", new Gson().toJson(issue));
                startActivity(intent);
            });

            issuesContainer.addView(complaintView);
        }
    }

    private String formatDate(String isoString) {
        if (isoString == null || isoString.isEmpty()) return "";
        try {
            String cleanIso = isoString;
            if (cleanIso.contains(".")) {
                cleanIso = cleanIso.substring(0, cleanIso.indexOf("."));
            }
            if (cleanIso.endsWith("Z")) {
                cleanIso = cleanIso.substring(0, cleanIso.length() - 1);
            }
            
            SimpleDateFormat inputFormat = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", Locale.getDefault());
            inputFormat.setTimeZone(TimeZone.getTimeZone("UTC"));
            Date date = inputFormat.parse(cleanIso);
            
            SimpleDateFormat outputFormat = new SimpleDateFormat("dd MMM, hh:mm a", Locale.getDefault());
            outputFormat.setTimeZone(TimeZone.getDefault());
            return outputFormat.format(date);
        } catch (Exception e) {
            Log.e(TAG, "Date parse error: " + isoString);
            return isoString;
        }
    }

    @Override
    protected void onResume() {
        super.onResume();
        fetchIssuesFromBackend();
    }
}
