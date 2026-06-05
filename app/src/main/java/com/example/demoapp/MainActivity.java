package com.example.demoapp;

import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.view.animation.Animation;
import android.view.animation.AnimationUtils;
import android.widget.Button;
import android.widget.TextView;
import android.widget.Toast;
import androidx.appcompat.app.AppCompatActivity;
import com.google.android.material.textfield.TextInputEditText;
import okhttp3.ResponseBody;
import org.json.JSONObject;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class MainActivity extends AppCompatActivity {

    private static final String TAG = "MainActivity";
    private TextInputEditText identifierEdit, passwordEdit;
    private Button loginBtn;
    private TextView registerText, forgotPasswordText;
    private View bgCircle1, bgCircle2;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        ThemeHelper.applyTheme(this);
        super.onCreate(savedInstanceState);
        
        SharedPreferences prefs = getSharedPreferences("UserPrefs", MODE_PRIVATE);
        prefs.edit().putBoolean("is_logged_in", false).apply();

        setContentView(R.layout.activity_main);

        identifierEdit = findViewById(R.id.email);
        passwordEdit = findViewById(R.id.password);
        loginBtn = findViewById(R.id.loginBtn);
        registerText = findViewById(R.id.registerText);
        forgotPasswordText = findViewById(R.id.forgotPassword);
        bgCircle1 = findViewById(R.id.bgCircle1);
        bgCircle2 = findViewById(R.id.bgCircle2);

        startBackgroundAnimations();

        loginBtn.setOnClickListener(v -> {
            String input = identifierEdit.getText().toString().trim();
            String password = passwordEdit.getText().toString().trim();

            if (input.isEmpty() || password.isEmpty()) {
                Toast.makeText(this, "Please enter all fields", Toast.LENGTH_SHORT).show();
                return;
            }

            if (input.contains("@")) input = input.toLowerCase();

            if (input.equalsIgnoreCase("admin") && password.equals("admin123")) {
                performDemoAdminLogin();
                return;
            }

            loginBtn.setEnabled(false);
            if (input.contains("@")) loginWithEmail(input, password);
            else resolveEmailAndLogin(input, password);
        });

        registerText.setOnClickListener(v -> startActivity(new Intent(this, RegisterActivity.class)));
        forgotPasswordText.setOnClickListener(v -> startActivity(new Intent(this, ForgotPasswordActivity.class)));
    }

    private void performDemoAdminLogin() {
        SharedPreferences.Editor editor = getSharedPreferences("UserPrefs", MODE_PRIVATE).edit();
        editor.clear();
        editor.putString("user_id", "00000000-0000-0000-0000-000000000000");
        editor.putString("email", "admin@demo.com");
        editor.putString("name", "Demo Admin");
        editor.putString("role", "Admin");
        editor.putString("access_token", SupabaseConfig.API_KEY); 
        editor.putBoolean("is_logged_in", true);
        editor.apply();
        startActivity(new Intent(this, AdminDashboardActivity.class));
        finish();
    }

    private void resolveEmailAndLogin(String input, String password) {
        SupabaseApi api = SupabaseConfig.getApi();
        String authHeader = "Bearer " + SupabaseConfig.API_KEY;
        
        Map<String, String> adminFilters = new HashMap<>();
        adminFilters.put("admin_id", "eq." + input);
        api.getAdmins(SupabaseConfig.API_KEY, authHeader, adminFilters).enqueue(new Callback<List<Map<String, Object>>>() {
            @Override
            public void onResponse(Call<List<Map<String, Object>>> call, Response<List<Map<String, Object>>> response) {
                if (response.isSuccessful() && response.body() != null && !response.body().isEmpty()) {
                    loginWithEmail((String) response.body().get(0).get("email"), password);
                } else {
                    api.getProfileByMobile(SupabaseConfig.API_KEY, authHeader, "eq." + input).enqueue(new Callback<List<Map<String, Object>>>() {
                        @Override
                        public void onResponse(Call<List<Map<String, Object>>> call, Response<List<Map<String, Object>>> response) {
                            if (response.isSuccessful() && response.body() != null && !response.body().isEmpty()) {
                                loginWithEmail((String) response.body().get(0).get("email_id"), password);
                            } else {
                                api.getProfileByStudentId(SupabaseConfig.API_KEY, authHeader, "eq." + input).enqueue(new Callback<List<Map<String, Object>>>() {
                                    @Override
                                    public void onResponse(Call<List<Map<String, Object>>> call, Response<List<Map<String, Object>>> response) {
                                        if (response.isSuccessful() && response.body() != null && !response.body().isEmpty()) {
                                            loginWithEmail((String) response.body().get(0).get("email_id"), password);
                                        } else {
                                            loginBtn.setEnabled(true);
                                            Toast.makeText(MainActivity.this, "User ID not found", Toast.LENGTH_SHORT).show();
                                        }
                                    }
                                    @Override public void onFailure(Call<List<Map<String, Object>>> call, Throwable t) { loginBtn.setEnabled(true); }
                                });
                            }
                        }
                        @Override public void onFailure(Call<List<Map<String, Object>>> call, Throwable t) { loginBtn.setEnabled(true); }
                    });
                }
            }
            @Override public void onFailure(Call<List<Map<String, Object>>> call, Throwable t) { loginBtn.setEnabled(true); }
        });
    }

    private void loginWithEmail(String email, String password) {
        final String finalEmail = email.trim().toLowerCase();
        Map<String, String> body = new HashMap<>();
        body.put("email", finalEmail);
        body.put("password", password);
        SupabaseConfig.getApi().login(SupabaseConfig.API_KEY, "Bearer " + SupabaseConfig.API_KEY, body).enqueue(new Callback<ResponseBody>() {
            @Override
            public void onResponse(Call<ResponseBody> call, Response<ResponseBody> response) {
                loginBtn.setEnabled(true);
                if (response.isSuccessful() && response.body() != null) handleLoginSuccess(finalEmail, password, response.body());
                else Toast.makeText(MainActivity.this, "Invalid Credentials", Toast.LENGTH_SHORT).show();
            }
            @Override public void onFailure(Call<ResponseBody> call, Throwable t) { loginBtn.setEnabled(true); }
        });
    }

    private void handleLoginSuccess(String email, String password, ResponseBody responseBody) {
        try {
            JSONObject jsonObject = new JSONObject(responseBody.string());
            String accessToken = jsonObject.getString("access_token");
            JSONObject user = jsonObject.getJSONObject("user");
            String userId = user.getString("id");
            JSONObject userMetadata = user.optJSONObject("user_metadata");
            String roleFromAuth = userMetadata != null ? userMetadata.optString("user_type", "Student") : "Student";
            
            SharedPreferences.Editor editor = getSharedPreferences("UserPrefs", MODE_PRIVATE).edit();
            editor.clear();
            editor.putString("access_token", accessToken);
            editor.putString("user_id", userId);
            editor.putString("email", email);
            editor.putString("role", roleFromAuth);
            editor.apply();

            Log.d(TAG, "Login successful. Role from Auth: " + roleFromAuth);

            if ("Admin".equalsIgnoreCase(roleFromAuth)) {
                fetchAdminData(userId, email, "Bearer " + accessToken);
            } else {
                fetchProfileData(userId, email, "Bearer " + accessToken);
            }
        } catch (Exception e) { Toast.makeText(this, "Login Error", Toast.LENGTH_SHORT).show(); }
    }

    private void fetchAdminData(String userId, String email, String userHeader) {
        Map<String, String> filters = new HashMap<>();
        filters.put("id", "eq." + userId);
        SupabaseConfig.getApi().getAdmins(SupabaseConfig.API_KEY, userHeader, filters).enqueue(new Callback<List<Map<String, Object>>>() {
            @Override
            public void onResponse(Call<List<Map<String, Object>>> call, Response<List<Map<String, Object>>> response) {
                if (response.isSuccessful() && response.body() != null && !response.body().isEmpty()) {
                    processAdminRecord(response.body().get(0));
                } else {
                    Log.w(TAG, "Admin record not found by UUID, trying Email...");
                    Map<String, String> emailFilters = new HashMap<>();
                    emailFilters.put("email", "eq." + email);
                    SupabaseConfig.getApi().getAdmins(SupabaseConfig.API_KEY, "Bearer " + SupabaseConfig.API_KEY, emailFilters).enqueue(new Callback<List<Map<String, Object>>>() {
                        @Override
                        public void onResponse(Call<List<Map<String, Object>>> call, Response<List<Map<String, Object>>> response) {
                            if (response.isSuccessful() && response.body() != null && !response.body().isEmpty()) {
                                processAdminRecord(response.body().get(0));
                            } else {
                                Toast.makeText(MainActivity.this, "Admin record missing in database.", Toast.LENGTH_SHORT).show();
                            }
                        }
                        @Override public void onFailure(Call<List<Map<String, Object>>> call, Throwable t) {}
                    });
                }
            }
            @Override public void onFailure(Call<List<Map<String, Object>>> call, Throwable t) {}
        });
    }

    private void processAdminRecord(Map<String, Object> admin) {
        boolean isApproved = Boolean.parseBoolean(String.valueOf(admin.getOrDefault("is_approved", "false")));
        if (isApproved) {
            saveUserData(admin, true);
            startActivity(new Intent(MainActivity.this, AdminDashboardActivity.class));
            finish();
        } else Toast.makeText(this, "Account pending approval.", Toast.LENGTH_LONG).show();
    }

    private void fetchProfileData(String userId, String email, String userHeader) {
        Map<String, String> filters = new HashMap<>();
        filters.put("id", "eq." + userId);
        SupabaseConfig.getApi().getProfiles(SupabaseConfig.API_KEY, userHeader, filters).enqueue(new Callback<List<Map<String, Object>>>() {
            @Override
            public void onResponse(Call<List<Map<String, Object>>> call, Response<List<Map<String, Object>>> response) {
                if (response.isSuccessful() && response.body() != null && !response.body().isEmpty()) {
                    saveUserData(response.body().get(0), false);
                    startActivity(new Intent(MainActivity.this, DashboardActivity.class));
                    finish();
                } else {
                    Map<String, String> emailFilters = new HashMap<>();
                    emailFilters.put("email_id", "eq." + email);
                    SupabaseConfig.getApi().getProfiles(SupabaseConfig.API_KEY, "Bearer " + SupabaseConfig.API_KEY, emailFilters).enqueue(new Callback<List<Map<String, Object>>>() {
                        @Override
                        public void onResponse(Call<List<Map<String, Object>>> call, Response<List<Map<String, Object>>> response) {
                            if (response.isSuccessful() && response.body() != null && !response.body().isEmpty()) {
                                saveUserData(response.body().get(0), false);
                                startActivity(new Intent(MainActivity.this, DashboardActivity.class));
                                finish();
                            }
                        }
                        @Override public void onFailure(Call<List<Map<String, Object>>> call, Throwable t) {}
                    });
                }
            }
            @Override public void onFailure(Call<List<Map<String, Object>>> call, Throwable t) {}
        });
    }

    private void saveUserData(Map<String, Object> data, boolean isAdmin) {
        SharedPreferences.Editor editor = getSharedPreferences("UserPrefs", MODE_PRIVATE).edit();
        editor.putBoolean("is_logged_in", true);
        
        String dbId = String.valueOf(data.get("id"));
        if (dbId != null && !dbId.isEmpty() && !dbId.equals("null")) editor.putString("user_id", dbId);

        editor.putString("name", String.valueOf(data.getOrDefault("full_name", "")));
        
        Object imgObj = data.get("profile_image");
        if (imgObj != null) {
            String profileImg = String.valueOf(imgObj);
            if (!profileImg.isEmpty() && !profileImg.equalsIgnoreCase("null")) {
                editor.putString("profileImage", profileImg);
                Log.d(TAG, "Profile image loaded for " + (isAdmin ? "Admin" : "User"));
            }
        }

        if (isAdmin) {
            editor.putString("role", "Admin");
            editor.putString("admin_id", String.valueOf(data.getOrDefault("admin_id", "")));
            editor.putString("department", String.valueOf(data.getOrDefault("department", "")));
            editor.putString("position", String.valueOf(data.getOrDefault("position", "")));
            editor.putString("email", String.valueOf(data.getOrDefault("email", "")));
        } else {
            editor.putString("role", String.valueOf(data.getOrDefault("user_role", "Student")));
            editor.putString("email", String.valueOf(data.getOrDefault("email_id", "")));
            editor.putString("phone", String.valueOf(data.getOrDefault("mobile_number", "")));
            editor.putString("dob", String.valueOf(data.getOrDefault("dob", "")));
            editor.putString("gender", String.valueOf(data.getOrDefault("gender", "")));
            editor.putString("student_id", String.valueOf(data.getOrDefault("student_id", "")));
            editor.putString("department", String.valueOf(data.getOrDefault("department", "")));
            editor.putString("year", String.valueOf(data.getOrDefault("year", "")));
        }
        editor.apply();
    }

    private void startBackgroundAnimations() {
        Animation pulse = AnimationUtils.loadAnimation(this, R.anim.pulse);
        if (bgCircle1 != null) bgCircle1.startAnimation(pulse);
        if (bgCircle2 != null) bgCircle2.startAnimation(pulse);
    }
}
