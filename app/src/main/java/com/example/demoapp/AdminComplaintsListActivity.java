package com.example.demoapp;

import android.content.Intent;
import android.content.SharedPreferences;
import android.content.res.ColorStateList;
import android.graphics.Color;
import android.os.Bundle;
import android.text.Editable;
import android.text.TextWatcher;
import android.util.Log;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;
import android.widget.Toast;
import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.content.ContextCompat;
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
import retrofit2.Retrofit;
import retrofit2.converter.gson.GsonConverterFactory;

public class AdminComplaintsListActivity extends AppCompatActivity {

    private SwipeRefreshLayout swipeRefresh;
    private LinearLayout complaintListContainer;
    private TextView titleText, noDataText, viewAllListBtn;
    private EditText listSearchInput;
    private String filterStatus = "All";
    private List<Issue> allIssues = new ArrayList<>();
    private SharedPreferences userPrefs;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        ThemeHelper.applyTheme(this);
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_admin_complaints_list);

        userPrefs = getSharedPreferences("UserPrefs", MODE_PRIVATE);
        filterStatus = getIntent().getStringExtra("filter_status");
        if (filterStatus == null) filterStatus = "All";

        swipeRefresh = findViewById(R.id.swipeRefresh);
        complaintListContainer = findViewById(R.id.complaintListContainer);
        titleText = findViewById(R.id.titleText);
        noDataText = findViewById(R.id.noDataText);
        viewAllListBtn = findViewById(R.id.viewAllListBtn);
        listSearchInput = findViewById(R.id.listSearchInput);

        updateTitleAndBtn();

        findViewById(R.id.closeBtn).setOnClickListener(v -> finish());
        swipeRefresh.setOnRefreshListener(this::fetchComplaints);
        
        if (viewAllListBtn != null) {
            viewAllListBtn.setOnClickListener(v -> {
                filterStatus = "All";
                updateTitleAndBtn();
                updateUI(filterIssues(allIssues));
            });
        }

        setupSearch();
        fetchComplaints();
    }

    private void updateTitleAndBtn() {
        if (titleText != null) titleText.setText(filterStatus + " Complaints");
        if (viewAllListBtn != null) {
            viewAllListBtn.setVisibility(filterStatus.equalsIgnoreCase("All") ? View.GONE : View.VISIBLE);
        }
    }

    private void setupSearch() {
        listSearchInput.addTextChangedListener(new TextWatcher() {
            @Override public void beforeTextChanged(CharSequence s, int start, int count, int after) {}
            @Override public void onTextChanged(CharSequence s, int start, int before, int count) {
                filterListBySearch(s.toString());
            }
            @Override public void afterTextChanged(Editable s) {}
        });
    }

    private void filterListBySearch(String query) {
        List<Issue> baseList = filterIssues(allIssues);
        if (query.isEmpty()) {
            updateUI(baseList);
            return;
        }
        List<Issue> filtered = new ArrayList<>();
        for (Issue issue : baseList) {
            String idStr = String.valueOf(issue.getId());
            String studentName = issue.getUserName() != null ? issue.getUserName().toLowerCase() : "";
            if (idStr.contains(query) || ("CMP" + idStr).toLowerCase().contains(query.toLowerCase()) || 
                studentName.contains(query.toLowerCase())) {
                filtered.add(issue);
            }
        }
        updateUI(filtered);
    }

    private void fetchComplaints() {
        swipeRefresh.setRefreshing(true);
        SupabaseConfig.getApi().getIssues(SupabaseConfig.API_KEY, "Bearer " + SupabaseConfig.API_KEY, new HashMap<>())
                .enqueue(new Callback<List<Issue>>() {
                    @Override
                    public void onResponse(Call<List<Issue>> call, Response<List<Issue>> response) {
                        swipeRefresh.setRefreshing(false);
                        if (response.isSuccessful() && response.body() != null) {
                            allIssues = response.body();
                            updateUI(filterIssues(allIssues));
                        }
                    }
                    @Override
                    public void onFailure(Call<List<Issue>> call, Throwable t) {
                        swipeRefresh.setRefreshing(false);
                        Toast.makeText(AdminComplaintsListActivity.this, "Network Error", Toast.LENGTH_SHORT).show();
                    }
                });
    }

    private List<Issue> filterIssues(List<Issue> issues) {
        if (filterStatus.equalsIgnoreCase("All")) return issues;
        List<Issue> filtered = new ArrayList<>();
        for (Issue issue : issues) {
            if (issue.getStatus() != null && issue.getStatus().equalsIgnoreCase(filterStatus)) {
                filtered.add(issue);
            }
        }
        return filtered;
    }

    private void updateUI(List<Issue> issuesToShow) {
        complaintListContainer.removeAllViews();
        if (issuesToShow.isEmpty()) {
            noDataText.setVisibility(View.VISIBLE);
        } else {
            noDataText.setVisibility(View.GONE);
            for (int i = issuesToShow.size() - 1; i >= 0; i--) {
                addIssueRow(issuesToShow.get(i));
            }
        }
    }

    private void addIssueRow(Issue issue) {
        View row = getLayoutInflater().inflate(R.layout.item_admin_complaint, complaintListContainer, false);
        
        TextView tvStatus = row.findViewById(R.id.tvStatus);
        Button btnPending = row.findViewById(R.id.btnPending);
        Button btnProcessing = row.findViewById(R.id.btnProcessing);
        Button btnResolve = row.findViewById(R.id.btnResolve);
        
        ((TextView)row.findViewById(R.id.tvStudentName)).setText(issue.getUserName());
        ((TextView)row.findViewById(R.id.tvComplaintId)).setText("CMP" + issue.getId());
        ((TextView)row.findViewById(R.id.tvCategory)).setText(issue.getProblemType());
        if (issue.getCreatedAt() != null && issue.getCreatedAt().length() >= 10) {
            ((TextView)row.findViewById(R.id.tvDate)).setText(issue.getCreatedAt().substring(0, 10));
        }

        String currentStatus = issue.getStatus() != null ? issue.getStatus() : "Pending";
        tvStatus.setText(currentStatus);

        int colorRed = Color.parseColor("#F44336"), colorOrange = Color.parseColor("#FF9800"), colorGreen = Color.parseColor("#4CAF50");
        btnPending.setBackgroundTintList(ColorStateList.valueOf(colorRed));
        btnProcessing.setBackgroundTintList(ColorStateList.valueOf(colorOrange));
        btnResolve.setBackgroundTintList(ColorStateList.valueOf(colorGreen));

        if (currentStatus.equalsIgnoreCase("Pending")) {
            tvStatus.setTextColor(colorRed); btnPending.setEnabled(false); btnPending.setAlpha(0.3f);
        } else if (currentStatus.equalsIgnoreCase("Processing")) {
            tvStatus.setTextColor(colorOrange); btnPending.setEnabled(false); btnPending.setAlpha(0.3f); btnProcessing.setEnabled(false); btnProcessing.setAlpha(0.3f);
        } else if (currentStatus.equalsIgnoreCase("Resolved")) {
            tvStatus.setTextColor(colorGreen); btnPending.setEnabled(false); btnPending.setAlpha(0.3f); btnProcessing.setEnabled(false); btnProcessing.setAlpha(0.3f); btnResolve.setEnabled(false); btnResolve.setAlpha(0.3f);
        }

        btnPending.setOnClickListener(v -> showConfirmationDialog(issue, "Pending"));
        btnProcessing.setOnClickListener(v -> showConfirmationDialog(issue, "Processing"));
        btnResolve.setOnClickListener(v -> showConfirmationDialog(issue, "Resolved"));
        
        View.OnClickListener openDetails = v -> showComplaintDetailDialog(issue);
        row.findViewById(R.id.btnDetails).setOnClickListener(openDetails);
        row.setOnClickListener(openDetails);

        complaintListContainer.addView(row);
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
                color = ContextCompat.getColor(this, R.color.blue_primary);
            }
            statusTv.setTextColor(color);
            if (iconView != null) iconView.setColorFilter(color);
        }

        ImageView detailImage = view.findViewById(R.id.detailImage);
        if (detailImage != null && issue.getPhotoUrl() != null && !issue.getPhotoUrl().isEmpty()) {
            detailImage.setVisibility(View.VISIBLE);
            Glide.with(this).load(issue.getPhotoUrl()).placeholder(android.R.drawable.ic_menu_gallery).into(detailImage);
            detailImage.setOnClickListener(v -> {
                Intent intent = new Intent(this, FullScreenImageActivity.class);
                intent.putExtra("image_url", issue.getPhotoUrl());
                startActivity(intent);
            });
        }

        view.findViewById(R.id.btnClose).setOnClickListener(v -> dialog.dismiss());
        if (dialog.getWindow() != null) dialog.getWindow().setBackgroundDrawableResource(android.R.color.transparent);
        dialog.show();
    }

    private String formatDateTime(String isoString) {
        if (isoString == null || isoString.isEmpty()) return "-";
        try {
            String cleanIso = isoString.endsWith("Z") ? isoString.substring(0, isoString.length() - 1) : isoString;
            String pattern = cleanIso.contains(".") ? "yyyy-MM-dd'T'HH:mm:ss.SSS" : "yyyy-MM-dd'T'HH:mm:ss";
            SimpleDateFormat inputFormat = new SimpleDateFormat(pattern, Locale.getDefault());
            inputFormat.setTimeZone(TimeZone.getTimeZone("UTC"));
            Date date = inputFormat.parse(cleanIso);
            return new SimpleDateFormat("dd MMM yyyy, hh:mm a", Locale.getDefault()).format(date);
        } catch (Exception e) { return isoString; }
    }

    private void showConfirmationDialog(Issue issue, String newStatus) {
        new AlertDialog.Builder(this).setTitle("Confirm Status Change").setMessage("Change to " + newStatus + "?")
                .setPositiveButton("Confirm", (d, w) -> updateStatus(issue, newStatus)).setNegativeButton("Cancel", null).show();
    }

    private void updateStatus(Issue issue, String newStatus) {
        Map<String, String> query = new HashMap<>(); query.put("id", "eq." + issue.getId());
        Map<String, Object> updates = new HashMap<>(); updates.put("status", newStatus);
        SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.getDefault());
        sdf.setTimeZone(TimeZone.getTimeZone("UTC")); String now = sdf.format(new Date());

        if (newStatus.equalsIgnoreCase("Processing")) updates.put("processing_at", now);
        else if (newStatus.equalsIgnoreCase("Resolved")) updates.put("resolved_at", now);

        SupabaseConfig.getApi().updateIssue(SupabaseConfig.API_KEY, "Bearer " + SupabaseConfig.API_KEY, query, updates)
                .enqueue(new Callback<Void>() {
                    @Override
                    public void onResponse(Call<Void> call, Response<Void> response) {
                        if (response.isSuccessful()) {
                            sendStudentNotification(issue, newStatus);
                            Toast.makeText(AdminComplaintsListActivity.this, "Status updated!", Toast.LENGTH_SHORT).show();
                            fetchComplaints();
                        }
                    }
                    @Override public void onFailure(Call<Void> call, Throwable t) {}
                });
    }

    private void sendStudentNotification(Issue issue, String newStatus) {
        String name = issue.getUserName();
        if (name != null && name.contains(" / ")) name = name.split(" / ")[0].trim();
        Notification notification = new Notification(name, "Complaint Update", "Your complaint is now: " + newStatus, issue.getId());
        SupabaseConfig.getApi().sendNotification(SupabaseConfig.API_KEY, "Bearer " + SupabaseConfig.API_KEY, notification).enqueue(new Callback<Void>() {
            @Override public void onResponse(Call<Void> call, Response<Void> response) {}
            @Override public void onFailure(Call<Void> call, Throwable t) {}
        });
    }
}
