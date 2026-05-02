package com.example.demoapp;

import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.os.CountDownTimer;
import android.util.Log;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.ProgressBar;
import android.widget.Toast;
import androidx.appcompat.app.AppCompatActivity;

import org.json.JSONObject;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import okhttp3.ResponseBody;
import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class RegisterActivity extends AppCompatActivity {

    private static final String TAG = "RegisterActivity";
    private EditText fullName, email, emailOtp, mobile, studentId, studentDept, academicYear, password, confirmPassword;
    private Button sendEmailOtp, createBtn;
    private ProgressBar progressBar;
    
    private String userId = "";
    private String currentAccessToken = "";
    private CountDownTimer otpTimer;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        ThemeHelper.applyTheme(this);
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_register);

        // Initialize Views
        fullName = findViewById(R.id.fullName);
        email = findViewById(R.id.email); 
        emailOtp = findViewById(R.id.emailOtp);
        mobile = findViewById(R.id.mobile);
        studentId = findViewById(R.id.studentId);
        studentDept = findViewById(R.id.studentDept);
        academicYear = findViewById(R.id.academicYear);
        password = findViewById(R.id.password);
        confirmPassword = findViewById(R.id.confirmPassword);
        
        sendEmailOtp = findViewById(R.id.sendEmailOtp);
        createBtn = findViewById(R.id.createBtn);
        progressBar = findViewById(R.id.progressBar);

        sendEmailOtp.setOnClickListener(v -> checkEmailAndSendOtp());

        createBtn.setOnClickListener(v -> {
            if (validateForm()) {
                verifyAndRegister();
            }
        });

        View backBtn = findViewById(R.id.backBtn);
        if (backBtn != null) backBtn.setOnClickListener(v -> finish());
    }

    private void checkEmailAndSendOtp() {
        String emailVal = email.getText().toString().trim();

        if (emailVal.isEmpty()) {
            email.setError("Required");
            return;
        }

        if (!android.util.Patterns.EMAIL_ADDRESS.matcher(emailVal).matches()) {
            email.setError("Enter a valid email");
            return;
        }

        progressBar.setVisibility(View.VISIBLE);
        sendEmailOtp.setEnabled(false);

        Map<String, String> filters = new HashMap<>();
        filters.put("email_id", "eq." + emailVal);

        SupabaseConfig.getApi().getProfiles(SupabaseConfig.API_KEY, "Bearer " + SupabaseConfig.API_KEY, filters)
            .enqueue(new Callback<List<Map<String, Object>>>() {
                @Override
                public void onResponse(Call<List<Map<String, Object>>> call, Response<List<Map<String, Object>>> response) {
                    if (response.isSuccessful() && response.body() != null && !response.body().isEmpty()) {
                        stopProcess("Email already registered. Please login.");
                    } else {
                        sendEmailOtpInternal(emailVal);
                    }
                }

                @Override
                public void onFailure(Call<List<Map<String, Object>>> call, Throwable t) {
                    Log.e(TAG, "DB Check failed: " + t.getMessage());
                    sendEmailOtpInternal(emailVal);
                }
            });
    }

    private void stopProcess(String message) {
        progressBar.setVisibility(View.GONE);
        sendEmailOtp.setEnabled(true);
        Toast.makeText(RegisterActivity.this, message, Toast.LENGTH_LONG).show();
    }

    private void startTimer() {
        sendEmailOtp.setEnabled(false);
        otpTimer = new CountDownTimer(60000, 1000) {
            @Override
            public void onTick(long millisUntilFinished) {
                sendEmailOtp.setText("Retry in " + (millisUntilFinished / 1000) + "s");
            }

            @Override
            public void onFinish() {
                sendEmailOtp.setEnabled(true);
                sendEmailOtp.setText("Get OTP");
            }
        }.start();
    }

    private void sendEmailOtpInternal(String emailVal) {
        Map<String, Object> body = new HashMap<>();
        body.put("email", emailVal);
        body.put("create_user", true);

        SupabaseConfig.getApi().sendOtp(SupabaseConfig.API_KEY, "Bearer " + SupabaseConfig.API_KEY, body).enqueue(new Callback<Void>() {
            @Override
            public void onResponse(Call<Void> call, Response<Void> response) {
                progressBar.setVisibility(View.GONE);
                if (response.isSuccessful()) {
                    Toast.makeText(RegisterActivity.this, "OTP sent to " + emailVal, Toast.LENGTH_SHORT).show();
                    startTimer();
                } else if (response.code() == 429) {
                    Toast.makeText(RegisterActivity.this, "Too many requests. Please wait a minute.", Toast.LENGTH_LONG).show();
                    startTimer();
                } else {
                    sendEmailOtp.setEnabled(true);
                    Toast.makeText(RegisterActivity.this, "Failed to send OTP: " + response.code(), Toast.LENGTH_SHORT).show();
                }
            }

            @Override
            public void onFailure(Call<Void> call, Throwable t) {
                stopProcess("Network Error: " + t.getMessage());
            }
        });
    }

    private void verifyAndRegister() {
        progressBar.setVisibility(View.VISIBLE);
        createBtn.setEnabled(false);

        Map<String, String> emailVerify = new HashMap<>();
        emailVerify.put("email", email.getText().toString().trim());
        emailVerify.put("token", emailOtp.getText().toString().trim());
        emailVerify.put("type", "signup");

        SupabaseConfig.getApi().verifyOtp(SupabaseConfig.API_KEY, "Bearer " + SupabaseConfig.API_KEY, emailVerify).enqueue(new Callback<ResponseBody>() {
            @Override
            public void onResponse(Call<ResponseBody> call, Response<ResponseBody> response) {
                if (response.isSuccessful() && response.body() != null) {
                    try {
                        String responseString = response.body().string();
                        JSONObject json = new JSONObject(responseString);
                        currentAccessToken = json.getString("access_token");
                        userId = json.getJSONObject("user").getString("id");
                        finalizeAccount();
                    } catch (Exception e) {
                        showError("Verification error: " + e.getMessage());
                    }
                } else {
                    showError("Invalid OTP or expired session.");
                }
            }

            @Override
            public void onFailure(Call<ResponseBody> call, Throwable t) {
                showError("Network Error: " + t.getMessage());
            }
        });
    }

    private void finalizeAccount() {
        Map<String, Object> update = new HashMap<>();
        update.put("password", password.getText().toString().trim());
        
        Map<String, String> metadata = new HashMap<>();
        metadata.put("full_name", fullName.getText().toString().trim());
        metadata.put("user_type", "Student");
        update.put("data", metadata);

        SupabaseConfig.getApi().updateUserAuth(SupabaseConfig.API_KEY, "Bearer " + currentAccessToken, update).enqueue(new Callback<ResponseBody>() {
            @Override
            public void onResponse(Call<ResponseBody> call, Response<ResponseBody> response) {
                saveProfileToBackend();
            }

            @Override
            public void onFailure(Call<ResponseBody> call, Throwable t) {
                saveProfileToBackend();
            }
        });
    }

    private void saveProfileToBackend() {
        Map<String, Object> profile = new HashMap<>();
        profile.put("id", userId);
        profile.put("email_id", email.getText().toString().trim());
        profile.put("full_name", fullName.getText().toString().trim());
        profile.put("mobile_number", mobile.getText().toString().trim());
        profile.put("user_role", "Student");
        profile.put("student_id", studentId.getText().toString().trim());
        profile.put("department", studentDept.getText().toString().trim());
        profile.put("year", academicYear.getText().toString().trim());

        SupabaseConfig.getApi().createProfile(SupabaseConfig.API_KEY, "Bearer " + currentAccessToken, profile)
            .enqueue(new Callback<Void>() {
                @Override
                public void onResponse(Call<Void> call, Response<Void> response) {
                    progressBar.setVisibility(View.GONE);
                    if (response.isSuccessful()) {
                        Toast.makeText(RegisterActivity.this, "Registration Successful!", Toast.LENGTH_LONG).show();
                    } else {
                        Toast.makeText(RegisterActivity.this, "Profile creation failed, but account exists.", Toast.LENGTH_SHORT).show();
                    }
                    finish();
                }

                @Override
                public void onFailure(Call<Void> call, Throwable t) {
                    progressBar.setVisibility(View.GONE);
                    Toast.makeText(RegisterActivity.this, "Network error during profile creation", Toast.LENGTH_SHORT).show();
                    finish();
                }
            });
    }

    private void showError(String msg) {
        progressBar.setVisibility(View.GONE);
        createBtn.setEnabled(true);
        Toast.makeText(this, msg, Toast.LENGTH_LONG).show();
    }

    private boolean validateForm() {
        if (fullName.getText().toString().isEmpty()) { fullName.setError("Required"); return false; }
        if (email.getText().toString().isEmpty()) { email.setError("Required"); return false; }
        if (emailOtp.getText().toString().isEmpty()) { emailOtp.setError("Required"); return false; }
        if (mobile.getText().toString().length() != 10) { mobile.setError("10 digits required"); return false; }
        if (studentId.getText().toString().isEmpty()) { studentId.setError("Required"); return false; }
        if (studentDept.getText().toString().isEmpty()) { studentDept.setError("Required"); return false; }
        if (academicYear.getText().toString().isEmpty()) { academicYear.setError("Required"); return false; }
        if (password.getText().toString().length() < 6) { password.setError("Min 6 chars"); return false; }
        if (!password.getText().toString().equals(confirmPassword.getText().toString())) {
            confirmPassword.setError("Passwords do not match");
            return false;
        }
        return true;
    }

    @Override
    protected void onDestroy() {
        if (otpTimer != null) otpTimer.cancel();
        super.onDestroy();
    }
}
