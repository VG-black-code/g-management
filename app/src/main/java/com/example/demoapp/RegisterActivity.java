package com.example.demoapp;

import android.os.Bundle;
import android.os.CountDownTimer;
import android.util.Log;
import android.util.Patterns;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.ProgressBar;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.appcompat.app.AppCompatActivity;

import com.google.android.material.button.MaterialButtonToggleGroup;

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
    private String selectedRole = "Student";
    private String emailUsedForOtp = ""; 

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
        MaterialButtonToggleGroup roleToggleGroup = findViewById(R.id.roleToggleGroup);

        roleToggleGroup.addOnButtonCheckedListener((group, checkedId, isChecked) -> {
            if (isChecked) {
                if (checkedId == R.id.btnStudent) {
                    selectedRole = "Student";
                    mobile.setVisibility(View.VISIBLE);
                    studentId.setVisibility(View.VISIBLE);
                    studentId.setHint("Student ID");
                    studentDept.setVisibility(View.VISIBLE);
                    studentDept.setHint("Department");
                    academicYear.setVisibility(View.VISIBLE);
                } else if (checkedId == R.id.btnAdmin) {
                    selectedRole = "Admin";
                    mobile.setVisibility(View.GONE);
                    studentId.setVisibility(View.VISIBLE);
                    studentId.setHint("Admin ID");
                    studentDept.setVisibility(View.VISIBLE);
                    studentDept.setHint("Department");
                    academicYear.setVisibility(View.GONE);
                }
            }
        });

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
        String emailVal = email.getText().toString().trim().toLowerCase();

        if (emailVal.isEmpty()) {
            email.setError("Required");
            return;
        }

        if (!Patterns.EMAIL_ADDRESS.matcher(emailVal).matches()) {
            email.setError("Enter a valid email");
            return;
        }

        progressBar.setVisibility(View.VISIBLE);
        sendEmailOtp.setEnabled(false);

        checkEmailExists(emailVal);
    }

    private void checkEmailExists(String emailVal) {
        Map<String, String> filters = new HashMap<>();
        filters.put("email_id", "eq." + emailVal);

        SupabaseConfig.getApi().getProfiles(SupabaseConfig.API_KEY, "Bearer " + SupabaseConfig.API_KEY, filters)
            .enqueue(new Callback<List<Map<String, Object>>>() {
                @Override
                public void onResponse(@NonNull Call<List<Map<String, Object>>> call, @NonNull Response<List<Map<String, Object>>> response) {
                    if (response.isSuccessful() && response.body() != null && !response.body().isEmpty()) {
                        stopProcess("Email already registered in system.");
                    } else {
                        Map<String, String> adminFilters = new HashMap<>();
                        adminFilters.put("email", "eq." + emailVal);
                        SupabaseConfig.getApi().getAdmins(SupabaseConfig.API_KEY, "Bearer " + SupabaseConfig.API_KEY, adminFilters)
                            .enqueue(new Callback<List<Map<String, Object>>>() {
                                @Override
                                public void onResponse(@NonNull Call<List<Map<String, Object>>> call, @NonNull Response<List<Map<String, Object>>> response) {
                                    if (response.isSuccessful() && response.body() != null && !response.body().isEmpty()) {
                                        stopProcess("Admin Email already registered.");
                                    } else {
                                        sendEmailOtpInternal(emailVal);
                                    }
                                }
                                @Override
                                public void onFailure(@NonNull Call<List<Map<String, Object>>> call, @NonNull Throwable t) {
                                    sendEmailOtpInternal(emailVal);
                                }
                            });
                    }
                }

                @Override
                public void onFailure(@NonNull Call<List<Map<String, Object>>> call, @NonNull Throwable t) {
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
                sendEmailOtp.setText(getString(R.string.otp_retry_timer, (millisUntilFinished / 1000)));
            }

            @Override
            public void onFinish() {
                sendEmailOtp.setEnabled(true);
                sendEmailOtp.setText(R.string.get_otp);
            }
        }.start();
    }

    private void sendEmailOtpInternal(String emailVal) {
        emailUsedForOtp = emailVal;
        Map<String, Object> body = new HashMap<>();
        body.put("email", emailVal);
        body.put("create_user", true);

        SupabaseConfig.getApi().sendOtp(SupabaseConfig.API_KEY, "Bearer " + SupabaseConfig.API_KEY, body).enqueue(new Callback<Void>() {
            @Override
            public void onResponse(@NonNull Call<Void> call, @NonNull Response<Void> response) {
                progressBar.setVisibility(View.GONE);
                if (response.isSuccessful()) {
                    Toast.makeText(RegisterActivity.this, "OTP sent to " + emailVal, Toast.LENGTH_SHORT).show();
                    startTimer();
                } else {
                    sendEmailOtp.setEnabled(true);
                    Toast.makeText(RegisterActivity.this, "Request failed. Check email or try later.", Toast.LENGTH_SHORT).show();
                }
            }

            @Override
            public void onFailure(@NonNull Call<Void> call, @NonNull Throwable t) {
                stopProcess("Network Error: " + t.getMessage());
            }
        });
    }

    private void verifyAndRegister() {
        if (emailUsedForOtp == null || emailUsedForOtp.isEmpty()) {
            Toast.makeText(this, "Please get OTP first", Toast.LENGTH_SHORT).show();
            return;
        }

        String currentEmail = email.getText().toString().trim().toLowerCase();
        if (!currentEmail.equals(emailUsedForOtp)) {
            email.setError("Email changed. Get OTP again.");
            return;
        }

        String token = emailOtp.getText().toString().trim();
        if (token.isEmpty()) {
            emailOtp.setError("Required");
            return;
        }

        progressBar.setVisibility(View.VISIBLE);
        createBtn.setEnabled(false);

        // Verification chain: signup -> magiclink -> email -> invite -> recovery
        performVerification(emailUsedForOtp, token, "signup");
    }

    private void performVerification(final String emailVal, final String token, final String type) {
        Map<String, String> emailVerify = new HashMap<>();
        emailVerify.put("email", emailVal);
        emailVerify.put("token", token);
        emailVerify.put("type", type);

        String authHeader = "Bearer " + SupabaseConfig.API_KEY;
        SupabaseConfig.getApi().verifyOtp(SupabaseConfig.API_KEY, authHeader, emailVerify).enqueue(new Callback<ResponseBody>() {
            @Override
            public void onResponse(@NonNull Call<ResponseBody> call, @NonNull Response<ResponseBody> response) {
                if (response.isSuccessful()) {
                    handleVerificationSuccess(response);
                } else {
                    // Fallback to different verification types
                    switch (type) {
                        case "signup":
                            performVerification(emailVal, token, "magiclink");
                            break;
                        case "magiclink":
                            performVerification(emailVal, token, "email");
                            break;
                        case "email":
                            performVerification(emailVal, token, "invite");
                            break;
                        case "invite":
                            performVerification(emailVal, token, "recovery");
                            break;
                        default:
                            handleVerificationFailure(response);
                            break;
                    }
                }
            }

            @Override
            public void onFailure(@NonNull Call<ResponseBody> call, @NonNull Throwable t) {
                showError("Network Error: " + t.getMessage());
            }
        });
    }

    private void handleVerificationSuccess(Response<ResponseBody> response) {
        try (ResponseBody responseBody = response.body()) {
            if (responseBody != null) {
                String responseString = responseBody.string();
                JSONObject json = new JSONObject(responseString);
                currentAccessToken = json.getString("access_token");
                userId = json.getJSONObject("user").getString("id");
                finalizeAccount();
            } else {
                showError("Empty server response.");
            }
        } catch (Exception e) {
            showError("Processing error: " + e.getMessage());
        }
    }

    private void handleVerificationFailure(Response<ResponseBody> response) {
        String errorMsg = "Invalid OTP.";
        try {
            if (response.errorBody() != null) {
                String errStr = response.errorBody().string();
                JSONObject json = new JSONObject(errStr);
                
                if (json.has("error_description")) errorMsg = json.getString("error_description");
                else if (json.has("msg")) errorMsg = json.getString("msg");
                else if (json.has("error")) errorMsg = json.getString("error");

                String lowerMsg = errorMsg.toLowerCase();
                if (lowerMsg.contains("expired")) errorMsg = "OTP expired. Get a new one.";
                else if (lowerMsg.contains("invalid")) errorMsg = "Invalid code. Check your email.";
            }
        } catch (Exception e) { /* fallback */ }
        showError(errorMsg);
    }

    private void finalizeAccount() {
        Map<String, Object> update = new HashMap<>();
        update.put("password", password.getText().toString().trim());
        
        Map<String, Object> metadata = new HashMap<>();
        metadata.put("full_name", fullName.getText().toString().trim());
        metadata.put("user_type", selectedRole);
        metadata.put("is_approved", !selectedRole.equals("Admin")); 
        
        update.put("data", metadata);

        SupabaseConfig.getApi().updateUserAuth(SupabaseConfig.API_KEY, "Bearer " + currentAccessToken, update).enqueue(new Callback<ResponseBody>() {
            @Override
            public void onResponse(@NonNull Call<ResponseBody> call, @NonNull Response<ResponseBody> response) {
                if (response.isSuccessful()) {
                    if (selectedRole.equals("Admin")) saveAdminToBackend();
                    else saveProfileToBackend();
                } else {
                    showError("Auth update failed. Check password strength.");
                }
            }

            @Override
            public void onFailure(@NonNull Call<ResponseBody> call, @NonNull Throwable t) {
                if (selectedRole.equals("Admin")) saveAdminToBackend();
                else saveProfileToBackend();
            }
        });
    }

    private void saveAdminToBackend() {
        Map<String, Object> admin = new HashMap<>();
        admin.put("id", userId);
        admin.put("full_name", fullName.getText().toString().trim());
        admin.put("admin_id", studentId.getText().toString().trim());
        admin.put("department", studentDept.getText().toString().trim());
        admin.put("email", emailUsedForOtp);
        admin.put("is_approved", false);

        SupabaseConfig.getApi().createAdmin(SupabaseConfig.API_KEY, "Bearer " + currentAccessToken, admin)
            .enqueue(new Callback<Void>() {
                @Override
                public void onResponse(@NonNull Call<Void> call, @NonNull Response<Void> response) {
                    progressBar.setVisibility(View.GONE);
                    triggerMakeWebhook();
                    Toast.makeText(RegisterActivity.this, "Admin Registered! Please wait for approval.", Toast.LENGTH_LONG).show();
                    finish();
                }

                @Override
                public void onFailure(@NonNull Call<Void> call, @NonNull Throwable t) {
                    progressBar.setVisibility(View.GONE);
                    Toast.makeText(RegisterActivity.this, "Record saved. Pending admin approval.", Toast.LENGTH_SHORT).show();
                    finish();
                }
            });
    }

    private void saveProfileToBackend() {
        Map<String, Object> profile = new HashMap<>();
        profile.put("id", userId);
        profile.put("email_id", emailUsedForOtp);
        profile.put("full_name", fullName.getText().toString().trim());
        profile.put("mobile_number", mobile.getText().toString().trim());
        profile.put("user_role", selectedRole);
        profile.put("is_approved", true);
        profile.put("student_id", studentId.getText().toString().trim());
        profile.put("department", studentDept.getText().toString().trim());
        profile.put("year", academicYear.getText().toString().trim());

        SupabaseConfig.getApi().createProfile(SupabaseConfig.API_KEY, "Bearer " + currentAccessToken, profile)
            .enqueue(new Callback<Void>() {
                @Override
                public void onResponse(@NonNull Call<Void> call, @NonNull Response<Void> response) {
                    progressBar.setVisibility(View.GONE);
                    triggerMakeWebhook();
                    Toast.makeText(RegisterActivity.this, "Registration Successful!", Toast.LENGTH_SHORT).show();
                    finish();
                }

                @Override
                public void onFailure(@NonNull Call<Void> call, @NonNull Throwable t) {
                    progressBar.setVisibility(View.GONE);
                    finish();
                }
            });
    }

    private void triggerMakeWebhook() {
        Map<String, Object> payload = new HashMap<>();
        payload.put("fullName", fullName.getText().toString().trim());
        payload.put("email", emailUsedForOtp);
        payload.put("studentId", studentId.getText().toString().trim());
        payload.put("studentDept", studentDept.getText().toString().trim());
        payload.put("role", selectedRole);

        SupabaseConfig.getApi().triggerWebhook(SupabaseConfig.MAKE_WEBHOOK_URL, payload).enqueue(new Callback<Void>() {
            @Override public void onResponse(@NonNull Call<Void> call, @NonNull Response<Void> response) {}
            @Override public void onFailure(@NonNull Call<Void> call, @NonNull Throwable t) {}
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
        
        if (selectedRole.equals("Student")) {
            if (mobile.getText().toString().length() != 10) { mobile.setError("10 digits required"); return false; }
            if (studentId.getText().toString().isEmpty()) { studentId.setError("Required"); return false; }
            if (studentDept.getText().toString().isEmpty()) { studentDept.setError("Department Required"); return false; }
            if (academicYear.getText().toString().isEmpty()) { academicYear.setError("Required"); return false; }
        } else {
            if (studentId.getText().toString().isEmpty()) { studentId.setError("Admin ID Required"); return false; }
            if (studentDept.getText().toString().isEmpty()) { studentDept.setError("Department Required"); return false; }
        }

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
