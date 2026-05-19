package com.example.demoapp;

import android.Manifest;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.pm.PackageManager;
import android.content.res.ColorStateList;
import android.graphics.BitmapFactory;
import android.graphics.Color;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.text.Editable;
import android.text.TextWatcher;
import android.util.Base64;
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
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;
import androidx.core.view.GravityCompat;
import androidx.drawerlayout.widget.DrawerLayout;
import androidx.swiperefreshlayout.widget.SwipeRefreshLayout;

import com.bumptech.glide.Glide;
import com.google.android.material.navigation.NavigationView;

import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.TimeZone;

import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class AdminDashboardActivity extends AppCompatActivity {

    private static final String TAG = "AdminDashboard";
    private TextView totalComplaints, pendingComplaints, processingComplaints, resolvedComplaints;
    private TextView adminName, viewAllBtn;
    private ImageView profileImage, themeToggle, menuIcon, notificationIcon;
    private SharedPreferences userPrefs, themePrefs;
    private DrawerLayout drawerLayout;
    private NavigationView navigationView;
    private SwipeRefreshLayout swipeRefreshLayout;
    private LinearLayout adminComplaintList;
    private List<Issue> allIssues = new ArrayList<>();

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        ThemeHelper.applyTheme(this);
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_admin_dashboard);

        userPrefs = getSharedPreferences("UserPrefs", MODE_PRIVATE);
        themePrefs = getSharedPreferences("ThemePrefs", MODE_PRIVATE);

        totalComplaints = findViewById(R.id.totalComplaints);
        pendingComplaints = findViewById(R.id.pendingComplaints);
        processingComplaints = findViewById(R.id.processingComplaints);
        resolvedComplaints = findViewById(R.id.resolvedComplaints);
        adminName = findViewById(R.id.adminTitle);
        viewAllBtn = findViewById(R.id.viewAllBtn);
        adminComplaintList = findViewById(R.id.adminComplaintList);
        
        menuIcon = findViewById(R.id.adminMenuIcon);
        themeToggle = findViewById(R.id.themeToggle);
        drawerLayout = findViewById(R.id.adminDrawerLayout);
        navigationView = findViewById(R.id.adminNavigationView);
        notificationIcon = findViewById(R.id.adminNotificationIcon);
        swipeRefreshLayout = findViewById(R.id.adminSwipeRefresh);

        setupDrawer();
        setupThemeToggle();
        setupClickListeners();
        setupRefreshLayout();
        setupSearch();

        if (notificationIcon != null) {
            notificationIcon.setOnClickListener(v -> startActivity(new Intent(this, NotificationsActivity.class)));
        }

        updateHeader();
        fetchStatistics();
        requestNotificationPermission();
        startNotificationService();
    }

    private void setupSearch() {
        EditText searchInput = findViewById(R.id.adminSearchInput);
        if (searchInput != null) {
            searchInput.addTextChangedListener(new TextWatcher() {
                @Override public void beforeTextChanged(CharSequence s, int start, int count, int after) {}
                @Override public void onTextChanged(CharSequence s, int start, int before, int count) {
                    filterDashboardList(s.toString());
                }
                @Override public void afterTextChanged(Editable s) {}
            });
        }
    }

    private void filterDashboardList(String query) {
        if (query.isEmpty()) {
            populateRecentComplaints(allIssues);
            return;
        }
        List<Issue> filtered = new ArrayList<>();
        for (Issue issue : allIssues) {
            String idStr = String.valueOf(issue.getId());
            String name = issue.getUserName() != null ? issue.getUserName().toLowerCase() : "";
            if (idStr.contains(query) || name.contains(query.toLowerCase())) {
                filtered.add(issue);
            }
        }
        populateRecentComplaints(filtered);
    }

    private void requestNotificationPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
                ActivityCompat.requestPermissions(this, new String[]{Manifest.permission.POST_NOTIFICATIONS}, 101);
            }
        }
    }

    private void startNotificationService() {
        startService(new Intent(this, NotificationService.class));
    }

    private void setupRefreshLayout() {
        if (swipeRefreshLayout != null) {
            swipeRefreshLayout.setOnRefreshListener(() -> {
                updateHeader();
                fetchStatistics();
                swipeRefreshLayout.setRefreshing(false);
            });
        }
    }

    private void setupDrawer() {
        if (menuIcon != null && drawerLayout != null) {
            menuIcon.setOnClickListener(v -> drawerLayout.openDrawer(GravityCompat.START));
        }

        if (navigationView != null) {
            navigationView.setNavigationItemSelectedListener(item -> {
                drawerLayout.closeDrawer(GravityCompat.START);
                int id = item.getItemId();
                if (id == R.id.nav_analytics) startActivity(new Intent(this, ComplaintAnalyticsActivity.class));
                else if (id == R.id.nav_admin_notifications) startActivity(new Intent(this, NotificationsActivity.class));
                else if (id == R.id.nav_users_data) startActivity(new Intent(this, UsersListActivity.class));
                else if (id == R.id.nav_update_profile) startActivity(new Intent(this, ProfileActivity.class));
                else if (id == R.id.nav_total_complaints) openComplaintsList("All");
                else if (id == R.id.nav_pending_complaints) openComplaintsList("Pending");
                else if (id == R.id.nav_processing_complaints) openComplaintsList("Processing");
                else if (id == R.id.nav_resolved_complaints) openComplaintsList("Resolved");
                else if (id == R.id.nav_logout) logout();
                return true;
            });
            updateNavHeader();
        }
    }

    private void setupClickListeners() {
        findViewById(R.id.cardTotal).setOnClickListener(v -> openComplaintsList("All"));
        findViewById(R.id.cardPending).setOnClickListener(v -> openComplaintsList("Pending"));
        findViewById(R.id.cardProcessing).setOnClickListener(v -> openComplaintsList("Processing"));
        findViewById(R.id.cardResolved).setOnClickListener(v -> openComplaintsList("Resolved"));
        if (viewAllBtn != null) viewAllBtn.setOnClickListener(v -> openComplaintsList("All"));
    }

    private void openComplaintsList(String filter) {
        Intent intent = new Intent(this, AdminComplaintsListActivity.class);
        intent.putExtra("filter_status", filter);
        startActivity(intent);
    }

    private void logout() {
        stopService(new Intent(this, NotificationService.class));
        userPrefs.edit().clear().apply();
        finishAffinity();
        startActivity(new Intent(this, MainActivity.class));
    }

    private void updateHeader() {
        if (adminName != null) adminName.setText(userPrefs.getString("name", "Admin"));
        updateProfileImageView(menuIcon);
    }

    private void updateNavHeader() {
        View headerView = navigationView.getHeaderView(0);
        if (headerView == null) return;
        ((TextView) headerView.findViewById(R.id.nav_header_name)).setText(userPrefs.getString("name", "Admin"));
        ((TextView) headerView.findViewById(R.id.nav_header_role)).setText(userPrefs.getString("role", "Administrator"));
        updateProfileImageView(headerView.findViewById(R.id.nav_header_image));
    }

    private void updateProfileImageView(ImageView imageView) {
        if (imageView == null) return;
        String encodedImage = userPrefs.getString("profileImage", "");
        if (!encodedImage.isEmpty() && !encodedImage.equals("null")) {
            try {
                byte[] decodedString = Base64.decode(encodedImage, Base64.DEFAULT);
                imageView.setImageBitmap(BitmapFactory.decodeByteArray(decodedString, 0, decodedString.length));
            } catch (Exception e) { imageView.setImageResource(R.mipmap.ic_launcher_round); }
        } else imageView.setImageResource(R.mipmap.ic_launcher_round);
    }

    private void fetchStatistics() {
        SupabaseConfig.getApi().getIssues(SupabaseConfig.API_KEY, "Bearer " + SupabaseConfig.API_KEY, new HashMap<>())
                .enqueue(new Callback<List<Issue>>() {
                    @Override
                    public void onResponse(Call<List<Issue>> call, Response<List<Issue>> response) {
                        if (response.isSuccessful() && response.body() != null) {
                            allIssues = new ArrayList<>(response.body());
                            Collections.sort(allIssues, (i1, i2) -> {
                                if (i1.getId() == null || i2.getId() == null) return 0;
                                return i2.getId().compareTo(i1.getId());
                            });
                            updateStatsUI(allIssues);
                        }
                    }
                    @Override public void onFailure(Call<List<Issue>> call, Throwable t) {}
                });
    }

    private void updateStatsUI(List<Issue> issues) {
        int p = 0, pr = 0, r = 0;
        for (Issue issue : issues) {
            String s = issue.getStatus();
            if ("Pending".equalsIgnoreCase(s)) p++;
            else if ("Processing".equalsIgnoreCase(s)) pr++;
            else if ("Resolved".equalsIgnoreCase(s)) r++;
        }
        totalComplaints.setText(String.valueOf(issues.size()));
        pendingComplaints.setText(String.valueOf(p));
        processingComplaints.setText(String.valueOf(pr));
        resolvedComplaints.setText(String.valueOf(r));
        populateRecentComplaints(issues);
    }

    private void populateRecentComplaints(List<Issue> issues) {
        if (adminComplaintList == null) return;
        adminComplaintList.removeAllViews();
        int limit = Math.min(issues.size(), 10);
        for (int i = 0; i < limit; i++) addIssueRow(issues.get(i));
        findViewById(R.id.adminNoDataText).setVisibility(issues.isEmpty() ? View.VISIBLE : View.GONE);
    }

    private void addIssueRow(Issue issue) {
        View row = getLayoutInflater().inflate(R.layout.item_admin_complaint, adminComplaintList, false);
        ((TextView)row.findViewById(R.id.tvStudentName)).setText(issue.getUserName());
        ((TextView)row.findViewById(R.id.tvComplaintId)).setText("CMP" + issue.getId());
        ((TextView)row.findViewById(R.id.tvCategory)).setText(issue.getProblemType());
        if (issue.getCreatedAt() != null && issue.getCreatedAt().length() >= 10)
            ((TextView)row.findViewById(R.id.tvDate)).setText(issue.getCreatedAt().substring(0, 10));

        TextView tvStatus = row.findViewById(R.id.tvStatus);
        Button bP = row.findViewById(R.id.btnPending), bPr = row.findViewById(R.id.btnProcessing), bR = row.findViewById(R.id.btnResolve);
        String s = issue.getStatus() != null ? issue.getStatus() : "Pending";
        tvStatus.setText(s);

        int red = Color.parseColor("#F44336"), orange = Color.parseColor("#FF9800"), green = Color.parseColor("#4CAF50");
        bP.setBackgroundTintList(ColorStateList.valueOf(red)); bPr.setBackgroundTintList(ColorStateList.valueOf(orange)); bR.setBackgroundTintList(ColorStateList.valueOf(green));

        if ("Pending".equalsIgnoreCase(s)) { tvStatus.setTextColor(red); bP.setEnabled(false); bP.setAlpha(0.3f); }
        else if ("Processing".equalsIgnoreCase(s)) { tvStatus.setTextColor(orange); bP.setEnabled(false); bP.setAlpha(0.3f); bPr.setEnabled(false); bPr.setAlpha(0.3f); }
        else if ("Resolved".equalsIgnoreCase(s)) { tvStatus.setTextColor(green); bP.setEnabled(false); bP.setAlpha(0.3f); bPr.setEnabled(false); bPr.setAlpha(0.3f); bR.setEnabled(false); bR.setAlpha(0.3f); }

        bP.setOnClickListener(v -> confirmUpdate(issue, "Pending"));
        bPr.setOnClickListener(v -> confirmUpdate(issue, "Processing"));
        bR.setOnClickListener(v -> confirmUpdate(issue, "Resolved"));
        
        View.OnClickListener openDetails = v -> showComplaintDetailDialog(issue);
        row.findViewById(R.id.btnDetails).setOnClickListener(openDetails);
        row.setOnClickListener(openDetails);
        adminComplaintList.addView(row);
    }

    private void showComplaintDetailDialog(Issue issue) {
        View view = getLayoutInflater().inflate(R.layout.dialog_complaint_details, null);
        AlertDialog dialog = new AlertDialog.Builder(this).setView(view).setCancelable(true).create();

        ((TextView) view.findViewById(R.id.detailId)).setText("CMP" + issue.getId());
        ((TextView) view.findViewById(R.id.detailProblem)).setText(issue.getProblemType());
        ((TextView) view.findViewById(R.id.detailDescription)).setText(issue.getDescription());
        
        TextView statusTv = view.findViewById(R.id.detailStatus);
        String s = issue.getStatus();
        statusTv.setText(s);

        ImageView iconView = view.findViewById(R.id.notifIcon);

        if (s != null) {
            int color;
            if (s.equalsIgnoreCase("Pending")) {
                color = ContextCompat.getColor(this, R.color.status_pending);
            } else if (s.equalsIgnoreCase("Processing")) {
                color = ContextCompat.getColor(this, R.color.status_in_progress);
            } else if (s.equalsIgnoreCase("Resolved") || s.equalsIgnoreCase("Approved")) {
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
                detailImage.setOnClickListener(v -> {
                    startActivity(new Intent(this, FullScreenImageActivity.class).putExtra("image_url", issue.getPhotoUrl()));
                });
            } else {
                detailImage.setVisibility(View.GONE);
            }
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

    private void confirmUpdate(Issue issue, String status) {
        new AlertDialog.Builder(this).setTitle("Update Status").setMessage("Change to " + status + "?")
                .setPositiveButton("Update", (d, w) -> performUpdate(issue, status)).setNegativeButton("Cancel", null).show();
    }

    private void performUpdate(Issue issue, String status) {
        Map<String, Object> updates = new HashMap<>(); updates.put("status", status);
        SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.getDefault());
        sdf.setTimeZone(TimeZone.getTimeZone("UTC")); String now = sdf.format(new Date());
        if ("Processing".equalsIgnoreCase(status)) updates.put("processing_at", now);
        else if ("Resolved".equalsIgnoreCase(status)) updates.put("resolved_at", now);

        Map<String, String> q = new HashMap<>(); q.put("id", "eq." + issue.getId());
        SupabaseConfig.getApi().updateIssue(SupabaseConfig.API_KEY, "Bearer " + SupabaseConfig.API_KEY, q, updates)
                .enqueue(new Callback<Void>() {
                    @Override
                    public void onResponse(Call<Void> call, Response<Void> response) {
                        if (response.isSuccessful()) {
                            sendNotification(issue, status);
                            Toast.makeText(AdminDashboardActivity.this, "Status updated!", Toast.LENGTH_SHORT).show();
                            fetchStatistics();
                        }
                    }
                    @Override public void onFailure(Call<Void> call, Throwable t) {}
                });
    }

    private void sendNotification(Issue issue, String status) {
        String n = issue.getUserName();
        if (n != null && n.contains(" / ")) n = n.split(" / ")[0].trim();
        Notification notification = new Notification(n, "Complaint Update", "Your complaint is now: " + status, issue.getId());
        SupabaseConfig.getApi().sendNotification(SupabaseConfig.API_KEY, "Bearer " + SupabaseConfig.API_KEY, notification).enqueue(new Callback<Void>() {
            @Override public void onResponse(Call<Void> call, Response<Void> response) {}
            @Override public void onFailure(Call<Void> call, Throwable t) {}
        });
    }

    private void setupThemeToggle() { if (themeToggle != null) themeToggle.setOnClickListener(v -> showThemeDialog()); }
    private void showThemeDialog() {
        String[] themes = {"Dark", "Lavender", "Light Blue", "Orange"};
        new AlertDialog.Builder(this).setTitle("Select Theme").setSingleChoiceItems(themes, -1, (dialog, which) -> {
            themePrefs.edit().putString("selectedTheme", themes[which]).apply();
            dialog.dismiss(); recreate();
        }).show();
    }
    @Override protected void onResume() { super.onResume(); updateHeader(); updateNavHeader(); fetchStatistics(); }
}
