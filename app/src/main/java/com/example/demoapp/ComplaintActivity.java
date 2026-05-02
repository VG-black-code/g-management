package com.example.demoapp;

import android.Manifest;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.pm.PackageManager;
import android.graphics.Bitmap;
import android.net.Uri;
import android.os.Bundle;
import android.provider.MediaStore;
import android.util.Log;
import android.view.View;
import android.widget.ArrayAdapter;
import android.widget.AutoCompleteTextView;
import android.widget.Button;
import android.widget.ImageView;
import android.widget.ProgressBar;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

import com.google.android.material.textfield.TextInputEditText;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.util.UUID;

import okhttp3.MediaType;
import okhttp3.RequestBody;
import okhttp3.ResponseBody;
import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class ComplaintActivity extends AppCompatActivity {

    private static final String TAG = "ComplaintActivity";
    private static final int PICK_IMAGE_REQUEST = 1;
    private static final int CAMERA_REQUEST = 2;

    private AutoCompleteTextView categoryDropdown, priorityDropdown;
    private TextInputEditText locationEdit, descriptionEdit;
    private ImageView selectedImage;
    private Button uploadImageBtn, takePhotoBtn, submitBtn;
    private ProgressBar progressBar;
    private Uri imageUri;
    private Bitmap cameraBitmap;
    private SharedPreferences userPrefs;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        ThemeHelper.applyTheme(this);
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_complaint);

        userPrefs = getSharedPreferences("UserPrefs", MODE_PRIVATE);

        // Initialize Views
        categoryDropdown = findViewById(R.id.categoryDropdown);
        priorityDropdown = findViewById(R.id.priorityDropdown);
        locationEdit = findViewById(R.id.location);
        descriptionEdit = findViewById(R.id.description);
        selectedImage = findViewById(R.id.selectedImage);
        uploadImageBtn = findViewById(R.id.uploadImageBtn);
        takePhotoBtn = findViewById(R.id.takePhotoBtn);
        submitBtn = findViewById(R.id.submitBtn);
        progressBar = findViewById(R.id.progressBar);

        setupDropdowns();

        uploadImageBtn.setOnClickListener(v -> openGallery());
        takePhotoBtn.setOnClickListener(v -> checkCameraPermission());
        submitBtn.setOnClickListener(v -> validateAndSubmit());

        findViewById(R.id.backBtn).setOnClickListener(v -> finish());

        // Handle category from intent
        int categoryIndex = getIntent().getIntExtra("category_index", -1);
        if (categoryIndex != -1) {
            String[] categories = getResources().getStringArray(R.array.problem_categories);
            if (categoryIndex < categories.length) {
                categoryDropdown.setText(categories[categoryIndex], false);
            }
        }
    }

    private void setupDropdowns() {
        String[] categories = getResources().getStringArray(R.array.problem_categories);
        ArrayAdapter<String> catAdapter = new ArrayAdapter<>(this, android.R.layout.simple_dropdown_item_1line, categories);
        categoryDropdown.setAdapter(catAdapter);

        String[] priorities = {"Low", "Medium", "High", "Urgent"};
        ArrayAdapter<String> priAdapter = new ArrayAdapter<>(this, android.R.layout.simple_dropdown_item_1line, priorities);
        priorityDropdown.setAdapter(priAdapter);
    }

    private void openGallery() {
        Intent intent = new Intent(Intent.ACTION_PICK, MediaStore.Images.Media.EXTERNAL_CONTENT_URI);
        startActivityForResult(intent, PICK_IMAGE_REQUEST);
    }

    private void checkCameraPermission() {
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA) != PackageManager.PERMISSION_GRANTED) {
            ActivityCompat.requestPermissions(this, new String[]{Manifest.permission.CAMERA}, 100);
        } else {
            openCamera();
        }
    }

    private void openCamera() {
        Intent intent = new Intent(MediaStore.ACTION_IMAGE_CAPTURE);
        startActivityForResult(intent, CAMERA_REQUEST);
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        if (requestCode == 100 && grantResults.length > 0 && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
            openCamera();
        }
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, @Nullable Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (resultCode == RESULT_OK && data != null) {
            if (requestCode == PICK_IMAGE_REQUEST) {
                imageUri = data.getData();
                selectedImage.setImageURI(imageUri);
                selectedImage.setVisibility(View.VISIBLE);
                cameraBitmap = null;
            } else if (requestCode == CAMERA_REQUEST) {
                cameraBitmap = (Bitmap) data.getExtras().get("data");
                selectedImage.setImageBitmap(cameraBitmap);
                selectedImage.setVisibility(View.VISIBLE);
                imageUri = null;
            }
        }
    }

    private void validateAndSubmit() {
        String category = categoryDropdown.getText().toString();
        String priority = priorityDropdown.getText().toString();
        String location = locationEdit.getText().toString().trim();
        String desc = descriptionEdit.getText().toString().trim();

        if (category.isEmpty() || priority.isEmpty() || location.isEmpty() || desc.isEmpty()) {
            Toast.makeText(this, "Please fill all fields", Toast.LENGTH_SHORT).show();
            return;
        }

        submitComplaint(category, priority, location, desc);
    }

    private void submitComplaint(String category, String priority, String location, String desc) {
        progressBar.setVisibility(View.VISIBLE);
        submitBtn.setEnabled(false);

        if (imageUri != null || cameraBitmap != null) {
            uploadImageAndSubmit(category, priority, location, desc);
        } else {
            postToDatabase(category, priority, location, desc, null);
        }
    }

    private void uploadImageAndSubmit(String category, String priority, String location, String desc) {
        try {
            byte[] imageData;
            if (imageUri != null) {
                Bitmap bitmap = MediaStore.Images.Media.getBitmap(getContentResolver(), imageUri);
                imageData = getBytesFromBitmap(bitmap);
            } else {
                imageData = getBytesFromBitmap(cameraBitmap);
            }

            String fileName = UUID.randomUUID().toString() + ".jpg";
            String bucket = "complaint-images";
            String path = "issues/" + fileName;

            SupabaseApi api = SupabaseConfig.getApi();
            RequestBody requestBody = RequestBody.create(MediaType.parse("image/jpeg"), imageData);

            String authHeader = "Bearer " + userPrefs.getString("access_token", "");

            api.uploadImage(SupabaseConfig.API_KEY, authHeader, "image/jpeg", "true", bucket, path, requestBody)
                    .enqueue(new Callback<ResponseBody>() {
                        @Override
                        public void onResponse(Call<ResponseBody> call, Response<ResponseBody> response) {
                            if (response.isSuccessful()) {
                                String publicUrl = SupabaseConfig.URL + "storage/v1/object/public/" + bucket + "/" + path;
                                postToDatabase(category, priority, location, desc, publicUrl);
                            } else {
                                Log.e(TAG, "Upload failed: " + response.code());
                                postToDatabase(category, priority, location, desc, null);
                            }
                        }

                        @Override
                        public void onFailure(Call<ResponseBody> call, Throwable t) {
                            Log.e(TAG, "Upload Error: " + t.getMessage());
                            postToDatabase(category, priority, location, desc, null);
                        }
                    });

        } catch (IOException e) {
            e.printStackTrace();
            postToDatabase(category, priority, location, desc, null);
        }
    }

    private byte[] getBytesFromBitmap(Bitmap bitmap) {
        ByteArrayOutputStream stream = new ByteArrayOutputStream();
        bitmap.compress(Bitmap.CompressFormat.JPEG, 80, stream);
        return stream.toByteArray();
    }

    private void postToDatabase(String category, String priority, String location, String desc, String photoUrl) {
        Issue issue = new Issue();
        issue.setProblemType(category);
        issue.setPriority(priority);
        issue.setLocation(location);
        issue.setDescription(desc);
        issue.setPhotoUrl(photoUrl);
        issue.setStatus("Pending");
        issue.setUserName(userPrefs.getString("name", "Unknown"));
        issue.setUserId(userPrefs.getString("user_id", ""));

        SupabaseApi api = SupabaseConfig.getApi();
        String authHeader = "Bearer " + userPrefs.getString("access_token", "");

        api.insertIssue(SupabaseConfig.API_KEY, authHeader, issue).enqueue(new Callback<Void>() {
            @Override
            public void onResponse(Call<Void> call, Response<Void> response) {
                progressBar.setVisibility(View.GONE);
                if (response.isSuccessful()) {
                    Toast.makeText(ComplaintActivity.this, "Complaint Submitted Successfully", Toast.LENGTH_LONG).show();
                    sendNotificationToAdmin(category, location);
                    finish();
                } else {
                    submitBtn.setEnabled(true);
                    Toast.makeText(ComplaintActivity.this, "Failed to submit: " + response.code(), Toast.LENGTH_SHORT).show();
                }
            }

            @Override
            public void onFailure(Call<Void> call, Throwable t) {
                progressBar.setVisibility(View.GONE);
                submitBtn.setEnabled(true);
                Toast.makeText(ComplaintActivity.this, "Network Error: " + t.getMessage(), Toast.LENGTH_SHORT).show();
            }
        });
    }

    private void sendNotificationToAdmin(String category, String location) {
        Notification notification = new Notification();
        notification.setTitle("New Complaint Filed");
        notification.setMessage("A new " + category + " issue has been reported at " + location);
        notification.setUserName("Admin"); // Target admin
        notification.setRead(false);

        SupabaseApi api = SupabaseConfig.getApi();
        String authHeader = "Bearer " + userPrefs.getString("access_token", "");

        api.sendNotification(SupabaseConfig.API_KEY, authHeader, notification).enqueue(new Callback<Void>() {
            @Override
            public void onResponse(Call<Void> call, Response<Void> response) {
                Log.d(TAG, "Admin notified");
            }

            @Override
            public void onFailure(Call<Void> call, Throwable t) {
                Log.e(TAG, "Failed to notify admin");
            }
        });
    }
}
