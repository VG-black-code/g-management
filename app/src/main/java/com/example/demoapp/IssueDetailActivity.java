package com.example.demoapp;

import android.content.Intent;
import android.graphics.Color;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.widget.Button;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;
import android.widget.Toast;
import androidx.appcompat.app.AppCompatActivity;
import com.bumptech.glide.Glide;
import com.google.gson.Gson;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.HashMap;
import java.util.Locale;
import java.util.Map;
import java.util.TimeZone;
import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;
import retrofit2.Retrofit;
import retrofit2.converter.gson.GsonConverterFactory;

public class IssueDetailActivity extends AppCompatActivity {

    private Issue currentIssue;
    private boolean isAdmin = false;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        ThemeHelper.applyTheme(this);
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_issue_detail);

        ImageView detailImage = findViewById(R.id.detailImage);
        TextView detailTitle = findViewById(R.id.detailTitle);
        TextView detailStatus = findViewById(R.id.detailStatus);
        TextView detailCategory = findViewById(R.id.detailCategory);
        TextView detailLocation = findViewById(R.id.detailLocation);
        TextView detailDescription = findViewById(R.id.detailDescription);
        TextView detailComplaintId = findViewById(R.id.detailComplaintId);
        TextView detailDateTime = findViewById(R.id.detailDateTime);
        TextView detailStudentName = findViewById(R.id.detailStudentName);
        View labelStudentName = findViewById(R.id.labelStudentName);
        
        // Status History Views
        TextView detailRaisedDate = findViewById(R.id.detailRaisedDate);
        TextView detailRaisedTime = findViewById(R.id.detailRaisedTime);
        TextView detailProcessingDate = findViewById(R.id.detailProcessingDate);
        TextView detailProcessingTime = findViewById(R.id.detailProcessingTime);
        TextView detailResolvedDate = findViewById(R.id.detailResolvedDate);
        TextView detailResolvedTime = findViewById(R.id.detailResolvedTime);
        
        View layoutProcessing = findViewById(R.id.layoutProcessing);
        View layoutResolved = findViewById(R.id.layoutResolved);
        
        ImageView closeBtn = findViewById(R.id.closeBtn);

        isAdmin = getIntent().getBooleanExtra("is_admin", false);
        String issueJson = getIntent().getStringExtra("issue_data");
        
        if (issueJson != null) {
            currentIssue = new Gson().fromJson(issueJson, Issue.class);
            
            detailTitle.setText(currentIssue.getProblemType());
            
            // 1. Set current status and its color
            String status = currentIssue.getStatus();
            detailStatus.setText(status);
            int statusColor = Color.GRAY;
            if (status != null) {
                if (status.equalsIgnoreCase("Pending")) {
                    statusColor = Color.parseColor("#F44336"); // Red
                } else if (status.equalsIgnoreCase("Processing")) {
                    statusColor = Color.parseColor("#FF9800"); // Orange
                } else if (status.equalsIgnoreCase("Resolved")) {
                    statusColor = Color.parseColor("#4CAF50"); // Green
                }
            }
            detailStatus.setTextColor(statusColor);

            detailCategory.setText(currentIssue.getCategory());
            detailLocation.setText(currentIssue.getLocation());
            detailDescription.setText(currentIssue.getDescription());
            detailComplaintId.setText("#CMP" + (currentIssue.getId() != null ? currentIssue.getId() : "---"));

            // Set Student Name (Hide if not admin and viewing own profile, but keeping it visible for transparency as requested)
            if (currentIssue.getUserName() != null && !currentIssue.getUserName().isEmpty()) {
                detailStudentName.setText(currentIssue.getUserName());
                detailStudentName.setVisibility(View.VISIBLE);
                labelStudentName.setVisibility(View.VISIBLE);
            } else {
                detailStudentName.setVisibility(View.GONE);
                labelStudentName.setVisibility(View.GONE);
            }

            // Main date at top
            detailDateTime.setText("Raised on: " + formatDateTime(currentIssue.getCreatedAt()));

            // 2. Status History Logic
            detailRaisedDate.setText(formatDateOnly(currentIssue.getCreatedAt()));
            detailRaisedTime.setText(formatTimeOnly(currentIssue.getCreatedAt()));
            if ("Pending".equalsIgnoreCase(status)) {
                detailRaisedDate.setTextColor(Color.parseColor("#F44336"));
                detailRaisedTime.setTextColor(Color.parseColor("#F44336"));
            }

            // Processing row
            if (currentIssue.getProcessingAt() != null && !currentIssue.getProcessingAt().isEmpty()) {
                layoutProcessing.setVisibility(View.VISIBLE);
                detailProcessingDate.setText(formatDateOnly(currentIssue.getProcessingAt()));
                detailProcessingTime.setText(formatTimeOnly(currentIssue.getProcessingAt()));
                detailProcessingDate.setTextColor(Color.parseColor("#FF9800"));
                detailProcessingTime.setTextColor(Color.parseColor("#FF9800"));
            }

            // Resolved row
            if (currentIssue.getResolvedAt() != null && !currentIssue.getResolvedAt().isEmpty()) {
                layoutResolved.setVisibility(View.VISIBLE);
                detailResolvedDate.setText(formatDateOnly(currentIssue.getResolvedAt()));
                detailResolvedTime.setText(formatTimeOnly(currentIssue.getResolvedAt()));
                detailResolvedDate.setTextColor(Color.parseColor("#4CAF50"));
                detailResolvedTime.setTextColor(Color.parseColor("#4CAF50"));
            }

            if (currentIssue.getPhotoUrl() != null && !currentIssue.getPhotoUrl().isEmpty()) {
                Glide.with(this)
                        .load(currentIssue.getPhotoUrl())
                        .placeholder(android.R.drawable.ic_menu_gallery)
                        .into(detailImage);
                
                detailImage.setOnClickListener(v -> {
                    Intent fullScreenIntent = new Intent(this, FullScreenImageActivity.class);
                    fullScreenIntent.putExtra("image_url", currentIssue.getPhotoUrl());
                    startActivity(fullScreenIntent);
                });
            }
        }

        if (closeBtn != null) {
            closeBtn.setOnClickListener(v -> finish());
        }
    }

    private String formatDateTime(String isoString) {
        if (isoString == null || isoString.isEmpty()) return "Date unavailable";
        try {
            Date date = parseIso(isoString);
            SimpleDateFormat outputFormat = new SimpleDateFormat("dd MMM yyyy, hh:mm a", Locale.getDefault());
            outputFormat.setTimeZone(TimeZone.getDefault());
            return outputFormat.format(date);
        } catch (Exception e) {
            return isoString;
        }
    }

    private String formatDateOnly(String isoString) {
        if (isoString == null || isoString.isEmpty()) return "-";
        try {
            Date date = parseIso(isoString);
            SimpleDateFormat outputFormat = new SimpleDateFormat("dd MMM yyyy", Locale.getDefault());
            outputFormat.setTimeZone(TimeZone.getDefault());
            return outputFormat.format(date);
        } catch (Exception e) { return "-"; }
    }

    private String formatTimeOnly(String isoString) {
        if (isoString == null || isoString.isEmpty()) return "-";
        try {
            Date date = parseIso(isoString);
            SimpleDateFormat outputFormat = new SimpleDateFormat("hh:mm a", Locale.getDefault());
            outputFormat.setTimeZone(TimeZone.getDefault());
            return outputFormat.format(date);
        } catch (Exception e) { return "-"; }
    }

    private Date parseIso(String isoString) throws Exception {
        String cleanIso = isoString;
        if (cleanIso.endsWith("Z")) cleanIso = cleanIso.substring(0, cleanIso.length() - 1);
        String pattern = cleanIso.contains(".") ? "yyyy-MM-dd'T'HH:mm:ss.SSS" : "yyyy-MM-dd'T'HH:mm:ss";
        SimpleDateFormat inputFormat = new SimpleDateFormat(pattern, Locale.getDefault());
        inputFormat.setTimeZone(TimeZone.getTimeZone("UTC"));
        return inputFormat.parse(cleanIso);
    }
}
