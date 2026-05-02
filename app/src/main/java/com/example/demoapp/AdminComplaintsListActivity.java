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
import android.widget.LinearLayout;
import android.widget.TextView;
import android.widget.Toast;
import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.content.ContextCompat;
import androidx.swiperefreshlayout.widget.SwipeRefreshLayout;
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
    private TextView titleText, noDataText;
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
        listSearchInput = findViewById(R.id.listSearchInput);

        titleText.setText(filterStatus + " Complaints");

        findViewById(R.id.closeBtn).setOnClickListener(v -> finish());
        swipeRefresh.setOnRefreshListener(this::fetchComplaints);
        
        setupSearch();
        fetchComplaints();
    }

    private void setupSearch() {
        listSearchInput.addTextChangedListener(new TextWatcher() {
            @Override
            public void beforeTextChanged(CharSequence s, int start, int count, int after) {}
            @Override
            public void onTextChanged(CharSequence s, int start, int before, int count) {
                filterListBySearch(s.toString());
            }
            @Override
            public void afterTextChanged(Editable s) {}
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
        Retrofit retrofit = new Retrofit.Builder()
                .baseUrl(SupabaseConfig.URL)
                .addConverterFactory(GsonConverterFactory.create())
                .build();

        SupabaseApi api = retrofit.create(SupabaseApi.class);
        Map<String, String> filters = new HashMap<>();

        api.getIssues(SupabaseConfig.API_KEY, "Bearer " + SupabaseConfig.API_KEY, filters)
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

        // Define precise colors as requested
        int colorRed = Color.parseColor("#F44336");
        int colorOrange = Color.parseColor("#FF9800");
        int colorGreen = Color.parseColor("#4CAF50");

        // Set action button colors explicitly
        btnPending.setBackgroundTintList(ColorStateList.valueOf(colorRed));
        btnProcessing.setBackgroundTintList(ColorStateList.valueOf(colorOrange));
        btnResolve.setBackgroundTintList(ColorStateList.valueOf(colorGreen));

        // Reset state
        btnPending.setEnabled(true);
        btnProcessing.setEnabled(true);
        btnResolve.setEnabled(true);
        btnPending.setAlpha(1.0f);
        btnProcessing.setAlpha(1.0f);
        btnResolve.setAlpha(1.0f);

        if (currentStatus.equalsIgnoreCase("Pending")) {
            tvStatus.setTextColor(colorRed);
            btnPending.setEnabled(false);
            btnPending.setAlpha(0.3f);
        } else if (currentStatus.equalsIgnoreCase("Processing")) {
            tvStatus.setTextColor(colorOrange);
            btnPending.setEnabled(false);
            btnPending.setAlpha(0.3f);
            btnProcessing.setEnabled(false);
            btnProcessing.setAlpha(0.3f);
        } else if (currentStatus.equalsIgnoreCase("Resolved")) {
            tvStatus.setTextColor(colorGreen);
            btnPending.setEnabled(false);
            btnPending.setAlpha(0.3f);
            btnProcessing.setEnabled(false);
            btnProcessing.setAlpha(0.3f);
            btnResolve.setEnabled(false);
            btnResolve.setAlpha(0.3f);
        }

        btnPending.setOnClickListener(v -> showConfirmationDialog(issue, "Pending"));
        btnProcessing.setOnClickListener(v -> showConfirmationDialog(issue, "Processing"));
        btnResolve.setOnClickListener(v -> showConfirmationDialog(issue, "Resolved"));
        
        View.OnClickListener openDetails = v -> {
            Intent intent = new Intent(this, IssueDetailActivity.class);
            intent.putExtra("issue_data", new com.google.gson.Gson().toJson(issue));
            intent.putExtra("is_admin", true);
            startActivity(intent);
        };

        row.findViewById(R.id.btnDetails).setOnClickListener(openDetails);
        row.setOnClickListener(openDetails);

        complaintListContainer.addView(row);
    }

    private void showConfirmationDialog(Issue issue, String newStatus) {
        AlertDialog.Builder builder = new AlertDialog.Builder(this);
        builder.setTitle("Confirm Status Change");
        builder.setMessage("Change status of CMP" + issue.getId() + " to " + newStatus + "?");
        builder.setPositiveButton("Confirm", (dialog, which) -> {
            updateStatus(issue, newStatus);
        });
        builder.setNegativeButton("Cancel", (dialog, which) -> dialog.dismiss());
        builder.create().show();
    }

    private void updateStatus(Issue issue, String newStatus) {
        if (issue.getId() == null) {
            Toast.makeText(this, "Error: Issue ID is missing", Toast.LENGTH_SHORT).show();
            return;
        }

        Retrofit retrofit = new Retrofit.Builder()
                .baseUrl(SupabaseConfig.URL)
                .addConverterFactory(GsonConverterFactory.create())
                .build();

        SupabaseApi api = retrofit.create(SupabaseApi.class);
        
        Map<String, String> queryParams = new HashMap<>();
        queryParams.put("id", "eq." + issue.getId());

        Map<String, Object> updates = new HashMap<>();
        updates.put("status", newStatus);
        
        SimpleDateFormat isoFormat = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.getDefault());
        isoFormat.setTimeZone(TimeZone.getTimeZone("UTC"));
        String now = isoFormat.format(new Date());

        if (newStatus.equalsIgnoreCase("Processing")) {
            updates.put("processing_at", now);
        } else if (newStatus.equalsIgnoreCase("Resolved")) {
            updates.put("resolved_at", now);
        }

        api.updateIssue(SupabaseConfig.API_KEY, "Bearer " + SupabaseConfig.API_KEY, queryParams, updates)
                .enqueue(new Callback<Void>() {
                    @Override
                    public void onResponse(Call<Void> call, Response<Void> response) {
                        if (response.isSuccessful()) {
                            sendStudentNotification(issue, newStatus);
                            Toast.makeText(AdminComplaintsListActivity.this, "Status updated!", Toast.LENGTH_SHORT).show();
                            fetchComplaints();
                        } else {
                            Toast.makeText(AdminComplaintsListActivity.this, "Update failed (" + response.code() + ")", Toast.LENGTH_SHORT).show();
                        }
                    }
                    @Override
                    public void onFailure(Call<Void> call, Throwable t) {
                        Toast.makeText(AdminComplaintsListActivity.this, "Error: " + t.getMessage(), Toast.LENGTH_SHORT).show();
                    }
                });
    }

    private void sendStudentNotification(Issue issue, String newStatus) {
        String title = "Complaint Update";
        String message = "Your complaint regarding '" + issue.getProblemType() + "' has been updated to: " + newStatus;
        
        Notification notification = new Notification(issue.getUserName(), title, message);
        
        Retrofit retrofit = new Retrofit.Builder()
                .baseUrl(SupabaseConfig.URL)
                .addConverterFactory(GsonConverterFactory.create())
                .build();
        SupabaseApi api = retrofit.create(SupabaseApi.class);

        api.sendNotification(SupabaseConfig.API_KEY, "Bearer " + SupabaseConfig.API_KEY, notification)
                .enqueue(new Callback<Void>() {
                    @Override
                    public void onResponse(Call<Void> call, Response<Void> response) {
                        Log.d("AdminList", "Notification sent to student");
                    }
                    @Override
                    public void onFailure(Call<Void> call, Throwable t) {
                        Log.e("AdminList", "Failed to send notification");
                    }
                });
    }
}
