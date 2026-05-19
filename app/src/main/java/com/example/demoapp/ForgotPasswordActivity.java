package com.example.demoapp;

import android.os.Bundle;
import android.text.TextUtils;
import android.view.View;
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.ProgressBar;
import android.widget.TextView;
import android.widget.Toast;
import androidx.appcompat.app.AppCompatActivity;
import com.google.android.material.button.MaterialButton;
import com.google.android.material.textfield.TextInputLayout;

import java.util.HashMap;
import java.util.Map;

import okhttp3.ResponseBody;
import org.json.JSONObject;
import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class ForgotPasswordActivity extends AppCompatActivity {

    private static final String TAG = "ForgotPassActivity";
    private EditText emailEdit, otpCodeEdit, newPasswordEdit;
    private TextInputLayout emailLayout;
    private MaterialButton sendOtpBtn, resetBtn;
    private LinearLayout inputSection, otpSection;
    private ProgressBar progressBar;
    private ImageView backBtn;
    private TextView footerText, otpDescriptionText;
    
    private String identifier = ""; // This will be the email

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        ThemeHelper.applyTheme(this);
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_forgot_password);

        emailEdit = findViewById(R.id.email);
        otpCodeEdit = findViewById(R.id.otpCode);
        newPasswordEdit = findViewById(R.id.newPassword);
        emailLayout = findViewById(R.id.emailLayout);
        sendOtpBtn = findViewById(R.id.sendOtpBtn);
        resetBtn = findViewById(R.id.resetBtn);
        inputSection = findViewById(R.id.inputSection);
        otpSection = findViewById(R.id.otpSection);
        progressBar = findViewById(R.id.progressBar);
        backBtn = findViewById(R.id.backBtn);
        footerText = findViewById(R.id.footerText);
        otpDescriptionText = findViewById(R.id.otpDescriptionText);

        backBtn.setOnClickListener(v -> finish());
        footerText.setOnClickListener(v -> finish());

        // Handle prefilled email from Change Password dialog
        String prefilledEmail = getIntent().getStringExtra("prefill_email");
        if (prefilledEmail != null && !prefilledEmail.isEmpty()) {
            emailEdit.setText(prefilledEmail);
        }

        sendOtpBtn.setOnClickListener(v -> {
            identifier = emailEdit.getText().toString().trim();
            if (TextUtils.isEmpty(identifier)) {
                emailEdit.setError("Email is required");
                return;
            }
            sendRecoveryCode(identifier);
        });

        resetBtn.setOnClickListener(v -> {
            String otp = otpCodeEdit.getText().toString().trim();
            String password = newPasswordEdit.getText().toString().trim();
            
            if (otp.length() != 6) {
                otpCodeEdit.setError("Enter the 6-digit code");
                return;
            }
            if (password.length() < 6) {
                newPasswordEdit.setError("Min 6 characters");
                return;
            }
            verifyAndReset(otp, password);
        });
    }

    private void sendRecoveryCode(String email) {
        progressBar.setVisibility(View.VISIBLE);
        sendOtpBtn.setEnabled(false);

        SupabaseApi api = SupabaseConfig.getApi();

        Map<String, String> body = new HashMap<>();
        body.put("email", email);
        String authHeader = "Bearer " + SupabaseConfig.API_KEY;
        api.sendResetOtp(SupabaseConfig.API_KEY, authHeader, body).enqueue(new Callback<Void>() {
            @Override
            public void onResponse(Call<Void> call, Response<Void> response) {
                handleOtpResponse(response.isSuccessful());
            }
            @Override
            public void onFailure(Call<Void> call, Throwable t) {
                handleOtpFailure();
            }
        });
    }

    private void handleOtpResponse(boolean success) {
        progressBar.setVisibility(View.GONE);
        sendOtpBtn.setEnabled(true);
        if (success) {
            Toast.makeText(this, "6-digit code sent to your email", Toast.LENGTH_SHORT).show();
            inputSection.setVisibility(View.GONE);
            otpSection.setVisibility(View.VISIBLE);
            otpDescriptionText.setText("Enter the 6-digit recovery code sent to your email");
        } else {
            Toast.makeText(this, "Error: User not found or limit reached", Toast.LENGTH_SHORT).show();
        }
    }

    private void handleOtpFailure() {
        progressBar.setVisibility(View.GONE);
        sendOtpBtn.setEnabled(true);
        Toast.makeText(this, "Network error", Toast.LENGTH_SHORT).show();
    }

    private void verifyAndReset(String otp, String password) {
        progressBar.setVisibility(View.VISIBLE);
        resetBtn.setEnabled(false);

        SupabaseApi api = SupabaseConfig.getApi();

        Map<String, String> verifyBody = new HashMap<>();
        verifyBody.put("email", identifier);
        verifyBody.put("token", otp);
        verifyBody.put("type", "recovery");

        String authHeader = "Bearer " + SupabaseConfig.API_KEY;
        api.verifyOtp(SupabaseConfig.API_KEY, authHeader, verifyBody).enqueue(new Callback<ResponseBody>() {
            @Override
            public void onResponse(Call<ResponseBody> call, Response<ResponseBody> response) {
                if (response.isSuccessful() && response.body() != null) {
                    try {
                        String responseStr = response.body().string();
                        JSONObject json = new JSONObject(responseStr);
                        String accessToken = json.getString("access_token");
                        updatePassword(api, accessToken, password);
                    } catch (Exception e) {
                        progressBar.setVisibility(View.GONE);
                        resetBtn.setEnabled(false);
                        Toast.makeText(ForgotPasswordActivity.this, "Verification error", Toast.LENGTH_SHORT).show();
                    }
                } else {
                    progressBar.setVisibility(View.GONE);
                    resetBtn.setEnabled(false);
                    Toast.makeText(ForgotPasswordActivity.this, "Invalid code or expired", Toast.LENGTH_SHORT).show();
                }
            }

            @Override
            public void onFailure(Call<ResponseBody> call, Throwable t) {
                progressBar.setVisibility(View.GONE);
                resetBtn.setEnabled(false);
                Toast.makeText(ForgotPasswordActivity.this, "Network error", Toast.LENGTH_SHORT).show();
            }
        });
    }

    private void updatePassword(SupabaseApi api, String token, String newPass) {
        Map<String, String> body = new HashMap<>();
        body.put("password", newPass);

        api.updatePassword(SupabaseConfig.API_KEY, "Bearer " + token, body).enqueue(new Callback<Void>() {
            @Override
            public void onResponse(Call<Void> call, Response<Void> response) {
                progressBar.setVisibility(View.GONE);
                if (response.isSuccessful()) {
                    Toast.makeText(ForgotPasswordActivity.this, "Password reset successful!", Toast.LENGTH_LONG).show();
                    finish();
                } else {
                    Toast.makeText(ForgotPasswordActivity.this, "Failed to update password", Toast.LENGTH_SHORT).show();
                    resetBtn.setEnabled(false);
                }
            }

            @Override
            public void onFailure(Call<Void> call, Throwable t) {
                progressBar.setVisibility(View.GONE);
                resetBtn.setEnabled(false);
                Toast.makeText(ForgotPasswordActivity.this, "Error updating password", Toast.LENGTH_SHORT).show();
            }
        });
    }
}
