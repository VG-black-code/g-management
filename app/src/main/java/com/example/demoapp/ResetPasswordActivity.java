package com.example.demoapp;

import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.ProgressBar;
import android.widget.Toast;
import androidx.appcompat.app.AppCompatActivity;

import java.util.HashMap;
import java.util.Map;

import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;
import retrofit2.Retrofit;
import retrofit2.converter.gson.GsonConverterFactory;

public class ResetPasswordActivity extends AppCompatActivity {

    private static final String TAG = "ResetPasswordActivity";
    private EditText newPassword;
    private Button updateBtn;
    private ProgressBar progressBar;
    private String accessToken;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        ThemeHelper.applyTheme(this);
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_reset_password);

        newPassword = findViewById(R.id.newPassword);
        updateBtn = findViewById(R.id.updateBtn);
        progressBar = findViewById(R.id.progressBar);

        // Capture the token from the email link (demoapp://reset#access_token=...)
        handleIntent(getIntent());

        updateBtn.setOnClickListener(v -> {
            String password = newPassword.getText().toString().trim();
            if (password.length() < 6) {
                newPassword.setError("Minimum 6 characters");
                return;
            }
            updatePasswordOnSupabase(password);
        });
    }

    private void handleIntent(Intent intent) {
        if (intent != null && intent.getData() != null) {
            Uri data = intent.getData();
            Log.d(TAG, "Deep Link received: " + data.toString());
            
            // Supabase puts tokens in the fragment (#...) for security
            String fragment = data.getFragment();
            if (fragment != null && fragment.contains("access_token=")) {
                // Extract access_token from fragment
                String[] params = fragment.split("&");
                for (String param : params) {
                    if (param.startsWith("access_token=")) {
                        accessToken = param.substring("access_token=".length());
                        break;
                    }
                }
            }
        }

        if (accessToken == null) {
            Toast.makeText(this, "Session expired or invalid link. Please request a new one.", Toast.LENGTH_LONG).show();
            // finish(); // Uncomment if you want to close the activity on error
        }
    }

    private void updatePasswordOnSupabase(String password) {
        if (accessToken == null) {
            Toast.makeText(this, "No valid session found.", Toast.LENGTH_SHORT).show();
            return;
        }

        progressBar.setVisibility(View.VISIBLE);
        updateBtn.setEnabled(false);

        Retrofit retrofit = new Retrofit.Builder()
                .baseUrl(SupabaseConfig.URL)
                .addConverterFactory(GsonConverterFactory.create())
                .build();

        SupabaseApi api = retrofit.create(SupabaseApi.class);

        Map<String, String> body = new HashMap<>();
        body.put("password", password);

        // We use the token from the link as Authorization
        api.updatePassword(SupabaseConfig.API_KEY, "Bearer " + accessToken, body)
                .enqueue(new Callback<Void>() {
                    @Override
                    public void onResponse(Call<Void> call, Response<Void> response) {
                        progressBar.setVisibility(View.GONE);
                        if (response.isSuccessful()) {
                            Toast.makeText(ResetPasswordActivity.this, "Password updated successfully!", Toast.LENGTH_LONG).show();
                            startActivity(new Intent(ResetPasswordActivity.this, MainActivity.class));
                            finish();
                        } else {
                            Log.e(TAG, "Update failed: " + response.code());
                            Toast.makeText(ResetPasswordActivity.this, "Failed to update password.", Toast.LENGTH_SHORT).show();
                            updateBtn.setEnabled(true);
                        }
                    }

                    @Override
                    public void onFailure(Call<Void> call, Throwable t) {
                        progressBar.setVisibility(View.GONE);
                        updateBtn.setEnabled(true);
                        Toast.makeText(ResetPasswordActivity.this, "Network error.", Toast.LENGTH_SHORT).show();
                    }
                });
    }
}
