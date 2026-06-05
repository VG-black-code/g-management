package com.example.demoapp;

import android.content.Intent;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.widget.Button;
import android.widget.ImageView;
import android.widget.TextView;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.content.ContextCompat;
import com.bumptech.glide.Glide;
import com.google.gson.Gson;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;
import java.util.TimeZone;

public class IssueDetailActivity extends AppCompatActivity {

    private static final String TAG = "IssueDetailActivity";
    private Issue currentIssue;

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
        
        TextView detailRaisedDateTime = findViewById(R.id.detailRaisedDateTime);
        TextView detailProcessingDateTime = findViewById(R.id.detailProcessingDateTime);
        TextView detailResolvedDateTime = findViewById(R.id.detailResolvedDateTime);
        
        View layoutProcessing = findViewById(R.id.layoutProcessing);
        View layoutResolved = findViewById(R.id.layoutResolved);
        
        Button backBtn = findViewById(R.id.backBtn);

        String issueJson = getIntent().getStringExtra("issue_data");
        
        if (issueJson != null) {
            currentIssue = new Gson().fromJson(issueJson, Issue.class);
            
            detailTitle.setText(currentIssue.getProblemType());
            
            String status = currentIssue.getStatus();
            detailStatus.setText(status);
            if (status != null) {
                if (status.equalsIgnoreCase("Pending")) {
                    detailStatus.setTextColor(ContextCompat.getColor(this, R.color.status_pending));
                } else if (status.equalsIgnoreCase("Processing")) {
                    detailStatus.setTextColor(ContextCompat.getColor(this, R.color.status_in_progress));
                } else if (status.equalsIgnoreCase("Resolved") || status.equalsIgnoreCase("Approved")) {
                    detailStatus.setTextColor(ContextCompat.getColor(this, R.color.status_resolved));
                }
            }

            detailCategory.setText(currentIssue.getCategory());
            detailLocation.setText(currentIssue.getLocation());
            detailDescription.setText(currentIssue.getDescription());
            detailComplaintId.setText("#CMP" + (currentIssue.getId() != null ? currentIssue.getId() : "---"));

            detailDateTime.setText("Raised on: " + formatDateTime(currentIssue.getCreatedAt()));

            // Status History
            detailRaisedDateTime.setText(formatStatusDateTime(currentIssue.getCreatedAt()));

            if (currentIssue.getProcessingAt() != null && !currentIssue.getProcessingAt().isEmpty()) {
                layoutProcessing.setVisibility(View.VISIBLE);
                detailProcessingDateTime.setText(formatStatusDateTime(currentIssue.getProcessingAt()));
            } else {
                layoutProcessing.setVisibility(View.GONE);
            }

            if (currentIssue.getResolvedAt() != null && !currentIssue.getResolvedAt().isEmpty()) {
                layoutResolved.setVisibility(View.VISIBLE);
                detailResolvedDateTime.setText(formatStatusDateTime(currentIssue.getResolvedAt()));
            } else {
                layoutResolved.setVisibility(View.GONE);
            }

            // Image loading with logging and error handling
            if (currentIssue.getPhotoUrl() != null && !currentIssue.getPhotoUrl().isEmpty()) {
                detailImage.setVisibility(View.VISIBLE);
                Log.d(TAG, "Loading image from URL: " + currentIssue.getPhotoUrl());
                Glide.with(this)
                        .load(currentIssue.getPhotoUrl())
                        .placeholder(android.R.drawable.ic_menu_gallery)
                        .error(android.R.drawable.stat_notify_error)
                        .into(detailImage);
                
                detailImage.setOnClickListener(v -> {
                    Intent intent = new Intent(this, FullScreenImageActivity.class);
                    intent.putExtra("image_url", currentIssue.getPhotoUrl());
                    startActivity(intent);
                });
            } else {
                Log.d(TAG, "No photo URL found for this issue.");
                detailImage.setVisibility(View.GONE);
            }
        }

        if (backBtn != null) {
            backBtn.setOnClickListener(v -> finish());
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

    private String formatStatusDateTime(String isoString) {
        if (isoString == null || isoString.isEmpty()) return "-";
        try {
            Date date = parseIso(isoString);
            SimpleDateFormat outputFormat = new SimpleDateFormat("dd MMM yyyy\nhh:mm a", Locale.getDefault());
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
