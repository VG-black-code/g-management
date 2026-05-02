package com.example.demoapp;

import android.content.Intent;
import android.content.SharedPreferences;
import android.graphics.BitmapFactory;
import android.os.Bundle;
import android.util.Base64;
import android.util.Log;
import android.view.View;
import android.widget.ImageView;
import android.widget.TextView;
import android.widget.Toast;
import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.view.GravityCompat;
import androidx.drawerlayout.widget.DrawerLayout;
import androidx.swiperefreshlayout.widget.SwipeRefreshLayout;

import com.google.android.material.navigation.NavigationView;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class AdminDashboardActivity extends AppCompatActivity {

    private static final String TAG = "AdminDashboard";
    private TextView totalComplaints, pendingComplaints, processingComplaints, resolvedComplaints;
    private TextView adminName, adminRole;
    private ImageView profileImage, themeToggle, menuIcon, notificationIcon;
    private View notificationBadge;
    private SharedPreferences userPrefs, themePrefs;
    private DrawerLayout drawerLayout;
    private NavigationView navigationView;
    private SwipeRefreshLayout swipeRefreshLayout;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        ThemeHelper.applyTheme(this);
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_admin_dashboard);

        userPrefs = getSharedPreferences("UserPrefs", MODE_PRIVATE);
        themePrefs = getSharedPreferences("ThemePrefs", MODE_PRIVATE);

        // Initialize UI components
        totalComplaints = findViewById(R.id.totalComplaints);
        pendingComplaints = findViewById(R.id.pendingComplaints);
        processingComplaints = findViewById(R.id.processingComplaints);
        resolvedComplaints = findViewById(R.id.resolvedComplaints);
        adminName = findViewById(R.id.adminName);
        adminRole = findViewById(R.id.adminRole);
        profileImage = findViewById(R.id.profileImage);
        themeToggle = findViewById(R.id.themeToggle);
        drawerLayout = findViewById(R.id.drawerLayout);
        navigationView = findViewById(R.id.navigationView);
        menuIcon = findViewById(R.id.menuIcon);
        notificationIcon = findViewById(R.id.notificationIcon);
        notificationBadge = findViewById(R.id.notificationBadge);
        swipeRefreshLayout = findViewById(R.id.swipeRefreshLayout);

        setupDrawer();
        setupThemeToggle();
        setupClickListeners();
        setupRefreshLayout();

        if (notificationIcon != null) {
            notificationIcon.setOnClickListener(v -> {
                startActivity(new Intent(this, NotificationsActivity.class));
            });
        }

        updateHeader();
        fetchStatistics();
        checkUnreadNotifications();
        
        startNotificationService();
    }

    private void startNotificationService() {
        Intent intent = new Intent(this, NotificationService.class);
        startService(intent);
    }

    private void setupRefreshLayout() {
        if (swipeRefreshLayout != null) {
            swipeRefreshLayout.setOnRefreshListener(() -> {
                updateHeader();
                fetchStatistics();
                checkUnreadNotifications();
                swipeRefreshLayout.setRefreshing(false);
            });
        }
    }

    private void setupDrawer() {
        if (menuIcon != null) {
            menuIcon.setOnClickListener(v -> drawerLayout.openDrawer(GravityCompat.START));
        }

        navigationView.setNavigationItemSelectedListener(item -> {
            int id = item.getItemId();
            if (id == R.id.nav_admin_dashboard) {
                // Already here
            } else if (id == R.id.nav_total_complaints) {
                openComplaintsList("All");
            } else if (id == R.id.nav_pending_complaints) {
                openComplaintsList("Pending");
            } else if (id == R.id.nav_processing_complaints) {
                openComplaintsList("Processing");
            } else if (id == R.id.nav_resolved_complaints) {
                openComplaintsList("Resolved");
            } else if (id == R.id.nav_users_data) {
                startActivity(new Intent(this, UsersListActivity.class));
            } else if (id == R.id.nav_admin_notifications) {
                startActivity(new Intent(this, NotificationsActivity.class));
            } else if (id == R.id.nav_theme) {
                showThemeSelectionDialog();
            } else if (id == R.id.nav_logout) {
                logout();
            }
            drawerLayout.closeDrawer(GravityCompat.START);
            return true;
        });

        updateNavHeader();
    }

    private void updateNavHeader() {
        View headerView = navigationView.getHeaderView(0);
        if (headerView == null) return;
        
        TextView navName = headerView.findViewById(R.id.nav_header_name);
        TextView navRole = headerView.findViewById(R.id.nav_header_role);
        ImageView navImage = headerView.findViewById(R.id.nav_header_image);

        if (navName != null) navName.setText(userPrefs.getString("name", "Admin"));
        if (navRole != null) navRole.setText(userPrefs.getString("role", "Administrator"));
        
        if (navImage != null) {
            updateProfileImageView(navImage);
        }
    }

    private void setupThemeToggle() {
        if (themeToggle != null) {
            themeToggle.setOnClickListener(v -> showThemeSelectionDialog());
        }
    }

    private void showThemeSelectionDialog() {
        String[] themes = {"Dark", "Lavender", "Light Blue", "Orange"};
        int checkedItem = 0;
        String current = themePrefs.getString("selectedTheme", "Lavender");
        for (int i = 0; i < themes.length; i++) {
            if (themes[i].equals(current)) checkedItem = i;
        }

        new AlertDialog.Builder(this)
                .setTitle("✨ Select App Theme")
                .setSingleChoiceItems(themes, checkedItem, (dialog, which) -> {
                    themePrefs.edit().putString("selectedTheme", themes[which]).apply();
                    Toast.makeText(this, "Applying " + themes[which] + " Theme...", Toast.LENGTH_SHORT).show();
                    dialog.dismiss();
                    recreate();
                })
                .show();
    }

    private void setupClickListeners() {
        findViewById(R.id.cardTotal).setOnClickListener(v -> openComplaintsList("All"));
        findViewById(R.id.cardPending).setOnClickListener(v -> openComplaintsList("Pending"));
        findViewById(R.id.cardProcessing).setOnClickListener(v -> openComplaintsList("Processing"));
        findViewById(R.id.cardResolved).setOnClickListener(v -> openComplaintsList("Resolved"));
        findViewById(R.id.cardAnalytics).setOnClickListener(v -> startActivity(new Intent(this, ComplaintAnalyticsActivity.class)));
        findViewById(R.id.cardUsers).setOnClickListener(v -> startActivity(new Intent(this, UsersListActivity.class)));
        
        if (profileImage != null) {
            profileImage.setOnClickListener(v -> {
                Intent intent = new Intent(this, UserDetailsActivity.class);
                intent.putExtra("is_view_only", false);
                startActivity(intent);
            });
        }
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
        if (adminRole != null) adminRole.setText(userPrefs.getString("role", "Administrator"));
        if (profileImage != null) updateProfileImageView(profileImage);
    }

    private void updateProfileImageView(ImageView imageView) {
        String encodedImage = userPrefs.getString("profileImage", "");
        if (!encodedImage.isEmpty() && !encodedImage.equals("null")) {
            try {
                byte[] decodedString = Base64.decode(encodedImage, Base64.DEFAULT);
                imageView.setImageBitmap(BitmapFactory.decodeByteArray(decodedString, 0, decodedString.length));
            } catch (Exception e) {
                imageView.setImageResource(R.mipmap.ic_launcher_round);
            }
        } else {
            imageView.setImageResource(R.mipmap.ic_launcher_round);
        }
    }

    private void fetchStatistics() {
        SupabaseApi api = SupabaseConfig.getApi();

        api.getIssues(SupabaseConfig.API_KEY, "Bearer " + SupabaseConfig.API_KEY, new HashMap<>())
                .enqueue(new Callback<List<Issue>>() {
                    @Override
                    public void onResponse(Call<List<Issue>> call, Response<List<Issue>> response) {
                        if (response.isSuccessful() && response.body() != null) {
                            updateStatsUI(response.body());
                        }
                    }

                    @Override
                    public void onFailure(Call<List<Issue>> call, Throwable t) {
                        Log.e(TAG, "Error fetching stats: " + t.getMessage());
                    }
                });
    }

    private void updateStatsUI(List<Issue> issues) {
        int total = issues.size();
        int pending = 0;
        int processing = 0;
        int resolved = 0;

        for (Issue issue : issues) {
            String status = issue.getStatus();
            if (status.equalsIgnoreCase("Pending")) pending++;
            else if (status.equalsIgnoreCase("Processing")) processing++;
            else if (status.equalsIgnoreCase("Resolved")) resolved++;
        }

        totalComplaints.setText(String.valueOf(total));
        pendingComplaints.setText(String.valueOf(pending));
        processingComplaints.setText(String.valueOf(processing));
        resolvedComplaints.setText(String.valueOf(resolved));
    }

    private void checkUnreadNotifications() {
        String name = userPrefs.getString("name", "");
        if (name.isEmpty()) return;

        SupabaseApi api = SupabaseConfig.getApi();

        Map<String, String> filters = new HashMap<>();
        filters.put("user_name", "eq." + name);
        filters.put("is_read", "is.false");

        api.getNotifications(SupabaseConfig.API_KEY, "Bearer " + SupabaseConfig.API_KEY, filters)
                .enqueue(new Callback<List<Notification>>() {
                    @Override
                    public void onResponse(Call<List<Notification>> call, Response<List<Notification>> response) {
                        if (response.isSuccessful() && response.body() != null) {
                            if (!response.body().isEmpty()) {
                                notificationBadge.setVisibility(View.VISIBLE);
                            } else {
                                notificationBadge.setVisibility(View.GONE);
                            }
                        }
                    }

                    @Override
                    public void onFailure(Call<List<Notification>> call, Throwable t) {
                        Log.e(TAG, "Failed to check notifications", t);
                    }
                });
    }

    @Override
    protected void onResume() {
        super.onResume();
        updateHeader();
        updateNavHeader();
        fetchStatistics();
        checkUnreadNotifications();
    }
}
