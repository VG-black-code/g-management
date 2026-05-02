package com.example.demoapp;

import android.Manifest;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.pm.PackageManager;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.util.Base64;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;
import android.widget.Toast;
import androidx.annotation.NonNull;
import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;
import androidx.core.view.GravityCompat;
import androidx.drawerlayout.widget.DrawerLayout;
import androidx.swiperefreshlayout.widget.SwipeRefreshLayout;

import com.bumptech.glide.Glide;
import com.google.android.material.bottomnavigation.BottomNavigationView;
import com.google.android.material.navigation.NavigationView;

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

public class DashboardActivity extends AppCompatActivity {

    private static final String TAG = "DashboardActivity";
    private SharedPreferences themePrefs;
    private SharedPreferences userPrefs;
    private TextView userName, userRole;
    private LinearLayout complaintList;
    private TextView noComplaintsText;
    private ImageView themeToggle, profileImage, notificationIcon, menuIcon;
    private View notificationBadge;
    private SwipeRefreshLayout swipeRefreshLayout;
    private DrawerLayout drawerLayout;
    private NavigationView navigationView;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        ThemeHelper.applyTheme(this);
        super.onCreate(savedInstanceState);

        userPrefs = getSharedPreferences("UserPrefs", MODE_PRIVATE);
        themePrefs = getSharedPreferences("ThemePrefs", MODE_PRIVATE);
        
        String email = userPrefs.getString("email", "");
        if (email != null && (email.equalsIgnoreCase("demo@test.com") || email.equalsIgnoreCase("admin@test.com"))) {
            userPrefs.edit().putString("role", "Admin").apply();
            startActivity(new Intent(this, AdminDashboardActivity.class));
            finish();
            return;
        }

        setContentView(R.layout.activity_dashboard);

        drawerLayout = findViewById(R.id.drawerLayout);
        navigationView = findViewById(R.id.navigationView);
        menuIcon = findViewById(R.id.menuIcon);
        
        userName = findViewById(R.id.userName);
        userRole = findViewById(R.id.userRole);
        complaintList = findViewById(R.id.complaintList);
        noComplaintsText = findViewById(R.id.noComplaintsText);
        themeToggle = findViewById(R.id.themeToggle);
        profileImage = findViewById(R.id.profileImage);
        notificationIcon = findViewById(R.id.notificationIcon);
        notificationBadge = findViewById(R.id.notificationBadge);
        swipeRefreshLayout = findViewById(R.id.swipeRefreshLayout);
        
        setupThemeToggle();
        setupBottomNav();
        setupCategoryClicks();
        setupRefreshLayout();
        setupDrawer();

        if (notificationIcon != null) {
            notificationIcon.setOnClickListener(v -> {
                startActivity(new Intent(this, NotificationsActivity.class));
            });
        }

        updateHeader();
        fetchRecentIssues();

        findViewById(R.id.raiseIssueBtn).setOnClickListener(v -> 
            startActivity(new Intent(this, ComplaintActivity.class)));

        requestNotificationPermission();
        startNotificationService();
    }

    private void setupDrawer() {
        if (profileImage != null) {
            profileImage.setOnClickListener(v -> {
                if (drawerLayout.isDrawerOpen(GravityCompat.START)) {
                    drawerLayout.closeDrawer(GravityCompat.START);
                    openProfileCard();
                } else {
                    drawerLayout.openDrawer(GravityCompat.START);
                }
            });
        }

        if (menuIcon != null) {
            menuIcon.setOnClickListener(v -> {
                if (drawerLayout.isDrawerOpen(GravityCompat.START)) {
                    drawerLayout.closeDrawer(GravityCompat.START);
                    openProfileCard();
                } else {
                    drawerLayout.openDrawer(GravityCompat.START);
                }
            });
        }

        navigationView.setNavigationItemSelectedListener(item -> {
            int id = item.getItemId();
            if (id == R.id.nav_update_profile) {
                startActivity(new Intent(this, ProfileActivity.class));
            } else if (id == R.id.nav_complaint_status) {
                startActivity(new Intent(this, ComplaintStatusActivity.class));
            } else if (id == R.id.nav_raise_complaint) {
                startActivity(new Intent(this, ComplaintActivity.class));
            } else if (id == R.id.nav_my_complaints) {
                startActivity(new Intent(this, MyIssuesActivity.class));
            } else if (id == R.id.nav_help) {
                showHelpDialog();
            } else if (id == R.id.nav_contact) {
                showContactSupportDialog();
            } else if (id == R.id.nav_about) {
                showAboutDialog();
            } else if (id == R.id.nav_theme) {
                showThemeSelectionDialog();
            } else if (id == R.id.nav_change_password) {
                showChangePasswordDialog();
            } else if (id == R.id.nav_logout) {
                logout();
            }
            drawerLayout.closeDrawer(GravityCompat.START);
            return true;
        });

        if (navigationView.getMenu().findItem(R.id.nav_admin_dashboard) != null) {
            navigationView.getMenu().findItem(R.id.nav_admin_dashboard).setVisible(false);
            navigationView.getMenu().findItem(R.id.nav_admin_notifications).setVisible(false);
            navigationView.getMenu().findItem(R.id.nav_users_data).setVisible(false);
            navigationView.getMenu().findItem(R.id.nav_total_complaints).setVisible(false);
            navigationView.getMenu().findItem(R.id.nav_pending_complaints).setVisible(false);
            navigationView.getMenu().findItem(R.id.nav_processing_complaints).setVisible(false);
            navigationView.getMenu().findItem(R.id.nav_resolved_complaints).setVisible(false);
        }
        
        updateNavHeader();
    }

    private void openProfileCard() {
        Intent intent = new Intent(this, UserDetailsActivity.class);
        intent.putExtra("is_view_only", false);
        startActivity(intent);
    }

    private void updateNavHeader() {
        View headerView = navigationView.getHeaderView(0);
        if (headerView == null) return;
        
        TextView navName = headerView.findViewById(R.id.nav_header_name);
        TextView navRole = headerView.findViewById(R.id.nav_header_role);
        ImageView navImage = headerView.findViewById(R.id.nav_header_image);

        if (navName != null) navName.setText(userPrefs.getString("name", "User Name"));
        if (navRole != null) navRole.setText(userPrefs.getString("role", "Student"));
        
        if (navImage != null) {
            updateProfileImageView(navImage);
            navImage.setOnClickListener(v -> {
                drawerLayout.closeDrawer(GravityCompat.START);
                openProfileCard();
            });
        }
    }

    private void requestNotificationPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
                ActivityCompat.requestPermissions(this, new String[]{Manifest.permission.POST_NOTIFICATIONS}, 101);
            }
        }
    }

    private void startNotificationService() {
        Intent intent = new Intent(this, NotificationService.class);
        startService(intent);
    }

    private void setupRefreshLayout() {
        swipeRefreshLayout.setOnRefreshListener(() -> {
            updateHeader();
            updateNavHeader();
            fetchRecentIssues();
            checkUnreadNotifications();
            swipeRefreshLayout.setRefreshing(false);
        });
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

    private void setupBottomNav() {
        BottomNavigationView bottomNav = findViewById(R.id.bottomNav);
        bottomNav.setOnItemSelectedListener(item -> {
            int id = item.getItemId();
            if (id == R.id.nav_home) return true;
            if (id == R.id.nav_issues) startActivity(new Intent(this, MyIssuesActivity.class));
            if (id == R.id.nav_profile) {
                startActivity(new Intent(this, UserDetailsActivity.class));
            }
            return true;
        });
    }

    private void logout() {
        stopService(new Intent(this, NotificationService.class));
        userPrefs.edit().clear().apply();
        finishAffinity();
        startActivity(new Intent(this, MainActivity.class));
    }

    private void showAboutDialog() {
        View dialogView = getLayoutInflater().inflate(R.layout.dialog_about_app, null);
        AlertDialog dialog = new AlertDialog.Builder(this)
                .setView(dialogView)
                .setCancelable(true)
                .create();

        dialogView.findViewById(R.id.btnClose).setOnClickListener(v -> dialog.dismiss());

        if (dialog.getWindow() != null) {
            dialog.getWindow().setBackgroundDrawableResource(android.R.color.transparent);
        }
        dialog.show();
    }

    private void showHelpDialog() {
        String videoUrl = "https://www.youtube.com/watch?v=V1ibms88GBQ";
        new AlertDialog.Builder(this)
                .setTitle("Help / User Guide")
                .setMessage("Watch our tutorial video to understand how to use the Student Dashboard.")
                .setPositiveButton("Watch Video", (dialog, which) -> {
                    Intent intent = new Intent(Intent.ACTION_VIEW, Uri.parse(videoUrl));
                    startActivity(intent);
                })
                .setNegativeButton("Close", null)
                .show();
    }

    private void showContactSupportDialog() {
        View dialogView = getLayoutInflater().inflate(R.layout.dialog_contact_support, null);
        AlertDialog dialog = new AlertDialog.Builder(this)
                .setView(dialogView)
                .setCancelable(true)
                .create();

        dialogView.findViewById(R.id.btnCall1).setOnClickListener(v -> makePhoneCall("9986916779"));
        dialogView.findViewById(R.id.btnCall2).setOnClickListener(v -> makePhoneCall("8618927590"));
        dialogView.findViewById(R.id.btnEmail1).setOnClickListener(v -> sendEmail("gaganashriranganath@gmail.com"));
        dialogView.findViewById(R.id.btnEmail2).setOnClickListener(v -> sendEmail("hiremathamruta58@gmail.com"));
        dialogView.findViewById(R.id.btnClose).setOnClickListener(v -> dialog.dismiss());

        if (dialog.getWindow() != null) {
            dialog.getWindow().setBackgroundDrawableResource(android.R.color.transparent);
        }
        dialog.show();
    }

    private void makePhoneCall(String phoneNumber) {
        Intent intent = new Intent(Intent.ACTION_DIAL);
        intent.setData(Uri.parse("tel:" + phoneNumber));
        startActivity(intent);
    }

    private void sendEmail(String email) {
        Intent intent = new Intent(Intent.ACTION_SENDTO);
        intent.setData(Uri.parse("mailto:" + email));
        try {
            startActivity(Intent.createChooser(intent, "Send Email"));
        } catch (Exception e) {
            Toast.makeText(this, "No email app found", Toast.LENGTH_SHORT).show();
        }
    }

    private void showChangePasswordDialog() {
        View dialogView = getLayoutInflater().inflate(R.layout.dialog_change_password, null);
        AlertDialog dialog = new AlertDialog.Builder(this)
                .setView(dialogView)
                .setCancelable(true)
                .create();

        EditText newPassEdit = dialogView.findViewById(R.id.newPasswordEdit);
        EditText confirmPassEdit = dialogView.findViewById(R.id.confirmPasswordEdit);
        Button btnSubmit = dialogView.findViewById(R.id.btnSubmit);
        Button btnCancel = dialogView.findViewById(R.id.btnCancel);

        btnSubmit.setOnClickListener(v -> {
            String newPass = newPassEdit.getText().toString().trim();
            String confirmPass = confirmPassEdit.getText().toString().trim();

            if (newPass.isEmpty() || newPass.length() < 6) {
                newPassEdit.setError("Password must be at least 6 characters");
                return;
            }
            if (!newPass.equals(confirmPass)) {
                confirmPassEdit.setError("Passwords do not match");
                return;
            }

            updatePasswordInSupabase(newPass, dialog);
        });

        btnCancel.setOnClickListener(v -> dialog.dismiss());

        if (dialog.getWindow() != null) {
            dialog.getWindow().setBackgroundDrawableResource(android.R.color.transparent);
        }
        dialog.show();
    }

    private void updatePasswordInSupabase(String newPass, AlertDialog dialog) {
        String token = userPrefs.getString("access_token", "");
        if (token.isEmpty()) {
            Toast.makeText(this, "Session expired. Please login again.", Toast.LENGTH_SHORT).show();
            return;
        }

        SupabaseApi api = SupabaseConfig.getApi();
        Map<String, String> body = new HashMap<>();
        body.put("password", newPass);

        api.updatePassword(SupabaseConfig.API_KEY, "Bearer " + token, body)
                .enqueue(new Callback<Void>() {
                    @Override
                    public void onResponse(Call<Void> call, Response<Void> response) {
                        if (response.isSuccessful()) {
                            Toast.makeText(DashboardActivity.this, "Password updated successfully!", Toast.LENGTH_SHORT).show();
                            dialog.dismiss();
                        } else {
                            Toast.makeText(DashboardActivity.this, "Failed to update password: " + response.code(), Toast.LENGTH_SHORT).show();
                        }
                    }

                    @Override
                    public void onFailure(Call<Void> call, Throwable t) {
                        Toast.makeText(DashboardActivity.this, "Network error: " + t.getMessage(), Toast.LENGTH_SHORT).show();
                    }
                });
    }

    @Override
    protected void onResume() {
        super.onResume();
        updateHeader();
        updateNavHeader();
        fetchRecentIssues();
        checkUnreadNotifications();
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
                        Log.e(TAG, "Failed to check unread notifications", t);
                    }
                });
    }

    private void updateHeader() {
        if (userName != null) userName.setText(userPrefs.getString("name", "User"));
        if (userRole != null) userRole.setText(userPrefs.getString("role", "Student"));
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

    private void fetchRecentIssues() {
        String currentUserName = userPrefs.getString("name", "");
        if (currentUserName.isEmpty()) return;

        SupabaseApi api = SupabaseConfig.getApi();
        Map<String, String> filters = new HashMap<>();
        filters.put("user_name", "eq." + currentUserName);

        api.getIssues(SupabaseConfig.API_KEY, "Bearer " + SupabaseConfig.API_KEY, filters)
                .enqueue(new Callback<List<Issue>>() {
                    @Override
                    public void onResponse(Call<List<Issue>> call, Response<List<Issue>> response) {
                        if (response.isSuccessful() && response.body() != null) {
                            displayRecentIssues(response.body());
                        }
                    }

                    @Override
                    public void onFailure(Call<List<Issue>> call, Throwable t) {
                        Log.e(TAG, "Error fetching issues: " + t.getMessage());
                    }
                });
    }

    private void displayRecentIssues(List<Issue> issues) {
        if (complaintList.getChildCount() > 1) {
            complaintList.removeViews(1, complaintList.getChildCount() - 1);
        }

        if (issues.isEmpty()) {
            noComplaintsText.setVisibility(View.VISIBLE);
        } else {
            noComplaintsText.setVisibility(View.GONE);
            int count = 0;
            for (int i = issues.size() - 1; i >= 0 && count < 3; i--) {
                Issue issue = issues.get(i);
                View view = getLayoutInflater().inflate(R.layout.item_complaint, complaintList, false);
                
                ImageView itemImage = view.findViewById(R.id.itemImage);
                TextView title = view.findViewById(R.id.itemTitle);
                TextView room = view.findViewById(R.id.itemRoom);
                TextView statusTv = view.findViewById(R.id.itemStatus);
                TextView dateTv = view.findViewById(R.id.itemDate);
                
                title.setText(issue.getProblemType());
                room.setText("Location: " + issue.getLocation());
                statusTv.setText("Status: " + issue.getStatus());
                
                if (dateTv != null) {
                    dateTv.setText("Sent: " + formatDate(issue.getCreatedAt()));
                }
                
                if (issue.getPhotoUrl() != null && !issue.getPhotoUrl().isEmpty()) {
                    Glide.with(this).load(issue.getPhotoUrl()).into(itemImage);
                } else {
                    itemImage.setImageResource(android.R.drawable.ic_menu_gallery);
                }
                
                if (issue.getStatus().equalsIgnoreCase("Resolved")) {
                    statusTv.setTextColor(getResources().getColor(android.R.color.holo_green_dark));
                } else if (issue.getStatus().equalsIgnoreCase("Processing")) {
                    statusTv.setTextColor(getResources().getColor(android.R.color.holo_orange_dark));
                }

                view.setOnClickListener(v -> {
                    Intent intent = new Intent(DashboardActivity.this, IssueDetailActivity.class);
                    intent.putExtra("issue_data", new com.google.gson.Gson().toJson(issue));
                    startActivity(intent);
                });
                
                complaintList.addView(view);
                count++;
            }
        }
    }

    private String formatDate(String isoString) {
        if (isoString == null || isoString.isEmpty()) return "N/A";
        try {
            String cleanIso = isoString;
            if (cleanIso.endsWith("Z")) cleanIso = cleanIso.substring(0, cleanIso.length() - 1);
            String pattern = cleanIso.contains(".") ? "yyyy-MM-dd'T'HH:mm:ss.SSS" : "yyyy-MM-dd'T'HH:mm:ss";
            
            SimpleDateFormat inputFormat = new SimpleDateFormat(pattern, Locale.getDefault());
            inputFormat.setTimeZone(TimeZone.getTimeZone("UTC"));
            Date date = inputFormat.parse(cleanIso);
            
            SimpleDateFormat outputFormat = new SimpleDateFormat("MMM dd", Locale.getDefault());
            outputFormat.setTimeZone(TimeZone.getDefault());
            return outputFormat.format(date);
        } catch (Exception e) {
            return isoString;
        }
    }

    private void setupCategoryClicks() {
        findViewById(R.id.classroomCard).setOnClickListener(v -> openComplaint(0));
        findViewById(R.id.facilitiesCard).setOnClickListener(v -> openComplaint(1));
        findViewById(R.id.hostelCard).setOnClickListener(v -> openComplaint(2));
        findViewById(R.id.labCard).setOnClickListener(v -> openComplaint(3));
    }

    private void openComplaint(int index) {
        Intent intent = new Intent(this, ComplaintActivity.class);
        intent.putExtra("category_index", index);
        startActivity(intent);
    }
}
