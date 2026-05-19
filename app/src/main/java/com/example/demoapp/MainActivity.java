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
        
        // Automatic logout: Always clear login state on app start for testing
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

            if (input.equals("admin") && password.equals("admin123")) {
                performDemoAdminLogin();
                return;
            }

            loginBtn.setEnabled(false);
            if (input.contains("@")) {
                loginWithEmail(input, password);
            } else {
                resolveEmailAndLogin(input, password);
            }
        });

        registerText.setOnClickListener(v -> startActivity(new Intent(this, RegisterActivity.class)));
        forgotPasswordText.setOnClickListener(v -> startActivity(new Intent(this, ForgotPasswordActivity.class)));
    }

    private void performDemoAdminLogin() {
        SharedPreferences prefs = getSharedPreferences("UserPrefs", MODE_PRIVATE);
        SharedPreferences.Editor editor = prefs.edit();
        editor.putString("user_id", "00000000-0000-0000-0000-000000000000");
        editor.putString("email", "admin@demo.com");
        editor.putString("name", "Admin");
        editor.putString("role", "Admin");
        editor.putString("access_token", SupabaseConfig.API_KEY); // Use API Key as fallback token
        editor.putBoolean("is_logged_in", true);
        editor.apply();

        Toast.makeText(this, "Admin Login Successful", Toast.LENGTH_SHORT).show();
        startActivity(new Intent(this, AdminDashboardActivity.class));
        finish();
    }

    private void resolveEmailAndLogin(String input, String password) {
        SupabaseApi api = SupabaseConfig.getApi();
        String authHeader = "Bearer " + SupabaseConfig.API_KEY;
        api.getProfileByMobile(SupabaseConfig.API_KEY, authHeader, "eq." + input)
            .enqueue(new Callback<List<Map<String, Object>>>() {
                @Override
                public void onResponse(Call<List<Map<String, Object>>> call, Response<List<Map<String, Object>>> response) {
                    if (response.isSuccessful() && response.body() != null && !response.body().isEmpty()) {
                        loginWithEmail((String) response.body().get(0).get("email_id"), password);
                    } else {
                        api.getProfileByStudentId(SupabaseConfig.API_KEY, authHeader, "eq." + input)
                            .enqueue(new Callback<List<Map<String, Object>>>() {
                                @Override
                                public void onResponse(Call<List<Map<String, Object>>> call, Response<List<Map<String, Object>>> response) {
                                    if (response.isSuccessful() && response.body() != null && !response.body().isEmpty()) {
                                        loginWithEmail((String) response.body().get(0).get("email_id"), password);
                                    } else {
                                        loginBtn.setEnabled(true);
                                        Toast.makeText(MainActivity.this, "Invalid ID or Credentials", Toast.LENGTH_SHORT).show();
                                    }
                                }
                                @Override
                                public void onFailure(Call<List<Map<String, Object>>> call, Throwable t) {
                                    loginBtn.setEnabled(true);
                                    Toast.makeText(MainActivity.this, "Network Error: " + t.getMessage(), Toast.LENGTH_SHORT).show();
                                }
                            });
                    }
                }
                @Override
                public void onFailure(Call<List<Map<String, Object>>> call, Throwable t) {
                    loginBtn.setEnabled(true);
                    Toast.makeText(MainActivity.this, "Network Error: " + t.getMessage(), Toast.LENGTH_SHORT).show();
                }
            });
    }

    private void loginWithEmail(String email, String password) {
        Map<String, String> body = new HashMap<>();
        body.put("email", email);
        body.put("password", password);

        String authHeader = "Bearer " + SupabaseConfig.API_KEY;
        SupabaseConfig.getApi().login(SupabaseConfig.API_KEY, authHeader, body).enqueue(new Callback<ResponseBody>() {
            @Override
            public void onResponse(Call<ResponseBody> call, Response<ResponseBody> response) {
                loginBtn.setEnabled(true);
                if (response.isSuccessful() && response.body() != null) {
                    handleLoginSuccess(email, password, response.body());
                } else {
                    Toast.makeText(MainActivity.this, "Login Failed: Invalid Email/Password", Toast.LENGTH_SHORT).show();
                }
            }
            @Override
            public void onFailure(Call<ResponseBody> call, Throwable t) {
                loginBtn.setEnabled(true);
                Toast.makeText(MainActivity.this, "Network Error: " + t.getMessage(), Toast.LENGTH_SHORT).show();
            }
        });
    }

    private void handleLoginSuccess(String email, String password, ResponseBody responseBody) {
        try {
            String bodyStr = responseBody.string();
            JSONObject jsonObject = new JSONObject(bodyStr);
            String accessToken = jsonObject.getString("access_token");
            JSONObject user = jsonObject.getJSONObject("user");
            String userId = user.getString("id");
            
            JSONObject userMetadata = user.optJSONObject("user_metadata");
            String nameFromAuth = userMetadata != null ? userMetadata.optString("full_name", "User") : "User";
            String roleFromAuth = userMetadata != null ? userMetadata.optString("user_type", "Student") : "Student";

            if (email.equalsIgnoreCase("demo@test.com") || email.equalsIgnoreCase("admin@test.com")) {
                roleFromAuth = "Admin";
            }

            SharedPreferences.Editor editor = getSharedPreferences("UserPrefs", MODE_PRIVATE).edit();
            editor.putString("access_token", accessToken);
            editor.putString("user_id", userId);
            editor.putString("email", email);
            editor.putString("password", password);
            editor.putString("name", nameFromAuth);
            editor.putString("role", roleFromAuth);
            editor.putBoolean("is_logged_in", true);
            editor.apply();

            fetchProfileAndNavigate(userId, accessToken, email, nameFromAuth, roleFromAuth);

        } catch (Exception e) {
            Toast.makeText(this, "Error processing login response", Toast.LENGTH_SHORT).show();
        }
    }

    private void fetchProfileAndNavigate(String userId, String token, String email, String defaultName, String defaultRole) {
        Map<String, String> filters = new HashMap<>();
        filters.put("id", "eq." + userId);

        SupabaseApi api = SupabaseConfig.getApi();
        String authHeader = "Bearer " + token;

        Call<List<Map<String, Object>>> call;
        if (defaultRole != null && (defaultRole.equalsIgnoreCase("Admin") || defaultRole.equalsIgnoreCase("Administrator"))) {
            call = api.getAdmins(SupabaseConfig.API_KEY, authHeader, filters);
        } else {
            call = api.getProfiles(SupabaseConfig.API_KEY, authHeader, filters);
        }

        call.enqueue(new Callback<List<Map<String, Object>>>() {
            @Override
            public void onResponse(Call<List<Map<String, Object>>> call, Response<List<Map<String, Object>>> response) {
                String finalName = defaultName;
                String finalRole = defaultRole;

                if (response.isSuccessful() && response.body() != null && !response.body().isEmpty()) {
                    Map<String, Object> profile = response.body().get(0);
                    finalName = String.valueOf(profile.getOrDefault("full_name", defaultName));
                    finalRole = String.valueOf(profile.getOrDefault("user_role", defaultRole));
                    
                    SharedPreferences.Editor editor = getSharedPreferences("UserPrefs", MODE_PRIVATE).edit();
                    for (Map.Entry<String, Object> entry : profile.entrySet()) {
                        if (entry.getValue() != null) {
                            String key = entry.getKey();
                            String val = String.valueOf(entry.getValue());
                            if (key.equals("mobile_number")) editor.putString("phone", val);
                            else if (key.equals("email_id")) editor.putString("email", val);
                            else if (key.equals("full_name")) editor.putString("name", val);
                            else if (key.equals("user_role")) editor.putString("role", val);
                            else if (key.equals("profile_image")) editor.putString("profileImage", val);
                            else editor.putString(key, val);
                        }
                    }
                    editor.apply();
                }

                if (email.equalsIgnoreCase("demo@test.com") || email.equalsIgnoreCase("admin@test.com")) {
                    finalRole = "Admin";
                    getSharedPreferences("UserPrefs", MODE_PRIVATE).edit().putString("role", "Admin").apply();
                }

                Toast.makeText(MainActivity.this, "Welcome " + finalName, Toast.LENGTH_SHORT).show();
                Intent intent = (finalRole != null && (finalRole.equalsIgnoreCase("Admin") || finalRole.equalsIgnoreCase("Administrator"))) ?
                        new Intent(MainActivity.this, AdminDashboardActivity.class) : 
                        new Intent(MainActivity.this, DashboardActivity.class);
                startActivity(intent);
                finish();
            }

            @Override
            public void onFailure(Call<List<Map<String, Object>>> call, Throwable t) {
                Intent intent = (defaultRole != null && (defaultRole.equalsIgnoreCase("Admin") || defaultRole.equalsIgnoreCase("Administrator"))) ?
                        new Intent(MainActivity.this, AdminDashboardActivity.class) : 
                        new Intent(MainActivity.this, DashboardActivity.class);
                startActivity(intent);
                finish();
            }
        });
    }

    private void startBackgroundAnimations() {
        Animation pulse = AnimationUtils.loadAnimation(this, android.R.anim.fade_in);
        pulse.setDuration(3000);
        pulse.setRepeatCount(Animation.INFINITE);
        pulse.setRepeatMode(Animation.REVERSE);
        bgCircle1.startAnimation(pulse);
        
        Animation pulse2 = AnimationUtils.loadAnimation(this, android.R.anim.fade_in);
        pulse2.setDuration(4000);
        pulse2.setRepeatCount(Animation.INFINITE);
        pulse2.setRepeatMode(Animation.REVERSE);
        bgCircle2.startAnimation(pulse2);
    }
}
