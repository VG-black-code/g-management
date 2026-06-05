package com.example.demoapp;

import android.Manifest;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.pm.PackageManager;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.net.Uri;
import android.os.Bundle;
import android.provider.MediaStore;
import android.util.Log;
import android.view.View;
import android.widget.ArrayAdapter;
import android.widget.AutoCompleteTextView;
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.ProgressBar;
import android.widget.TextView;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

import com.google.android.material.button.MaterialButton;
import com.google.android.material.textfield.TextInputEditText;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.List;
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

    private AutoCompleteTextView categoryDropdown, problemTypeDropdown, locationDropdown;
    private TextInputEditText descriptionEdit, subLocationEdit;
    private EditText studentInfoEdit;
    private ImageView selectedImage;
    private TextView imageStatusText;
    private MaterialButton uploadImageBtn, submitBtn;
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

        studentInfoEdit = findViewById(R.id.studentInfo);
        categoryDropdown = findViewById(R.id.categoryDropdown);
        problemTypeDropdown = findViewById(R.id.problemTypeDropdown);
        locationDropdown = findViewById(R.id.locationDropdown);
        descriptionEdit = findViewById(R.id.description);
        subLocationEdit = findViewById(R.id.subLocation);
        selectedImage = findViewById(R.id.selectedImage);
        imageStatusText = findViewById(R.id.imageStatusText);
        uploadImageBtn = findViewById(R.id.uploadImageBtn);
        submitBtn = findViewById(R.id.submitBtn);
        progressBar = findViewById(R.id.progressBar);

        String studentName = userPrefs.getString("name", "Unknown");
        String studentRegId = userPrefs.getString("student_id", "N/A");
        studentInfoEdit.setText(studentName + " / " + studentRegId);

        setupDropdowns();

        uploadImageBtn.setOnClickListener(v -> showImageSourceDialog());
        submitBtn.setOnClickListener(v -> validateAndSubmit());
        findViewById(R.id.backBtn).setOnClickListener(v -> finish());

        int categoryIndex = getIntent().getIntExtra("category_index", -1);
        if (categoryIndex != -1) {
            String[] categories = getResources().getStringArray(R.array.problem_categories);
            if (categoryIndex < categories.length) {
                categoryDropdown.setText(categories[categoryIndex], false);
                updateProblemTypeDropdown(categories[categoryIndex]);
            }
        }
    }

    private void setupDropdowns() {
        String[] categories = getResources().getStringArray(R.array.problem_categories);
        ArrayAdapter<String> catAdapter = new ArrayAdapter<>(this, android.R.layout.simple_dropdown_item_1line, categories);
        categoryDropdown.setAdapter(catAdapter);

        categoryDropdown.setOnItemClickListener((parent, view, position, id) -> {
            String selectedCategory = (String) parent.getItemAtPosition(position);
            updateProblemTypeDropdown(selectedCategory);
        });

        String[] locations = getResources().getStringArray(R.array.locations);
        ArrayAdapter<String> locAdapter = new ArrayAdapter<>(this, android.R.layout.simple_dropdown_item_1line, locations);
        locationDropdown.setAdapter(locAdapter);
    }

    private void updateProblemTypeDropdown(String category) {
        int arrayResId;
        switch (category) {
            case "Classroom": arrayResId = R.array.classroom_problems; break;
            case "Campus Facilities": arrayResId = R.array.campus_facilities_problems; break;
            case "Hostel": arrayResId = R.array.hostel_problems; break;
            case "Lab / IT": arrayResId = R.array.lab_it_problems; break;
            default: arrayResId = R.array.others_problems; break;
        }
        String[] problemTypes = getResources().getStringArray(arrayResId);
        ArrayAdapter<String> probAdapter = new ArrayAdapter<>(this, android.R.layout.simple_dropdown_item_1line, problemTypes);
        problemTypeDropdown.setAdapter(probAdapter);
        problemTypeDropdown.setText("", false);
    }

    private void showImageSourceDialog() {
        String[] options = {"Gallery", "Camera"};
        new androidx.appcompat.app.AlertDialog.Builder(this)
                .setTitle("Select Image Source")
                .setItems(options, (dialog, which) -> {
                    if (which == 0) openGallery();
                    else checkCameraPermission();
                })
                .show();
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
    protected void onActivityResult(int requestCode, int resultCode, @Nullable Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (resultCode == RESULT_OK) {
            if (requestCode == PICK_IMAGE_REQUEST && data != null) {
                imageUri = data.getData();
                selectedImage.setImageURI(imageUri);
                selectedImage.setVisibility(View.VISIBLE);
                imageStatusText.setText("Image selected!");
                cameraBitmap = null;
            } else if (requestCode == CAMERA_REQUEST && data != null && data.getExtras() != null) {
                cameraBitmap = (Bitmap) data.getExtras().get("data");
                selectedImage.setImageBitmap(cameraBitmap);
                selectedImage.setVisibility(View.VISIBLE);
                imageStatusText.setText("Image selected!");
                imageUri = null;
            }
        }
    }

    private void validateAndSubmit() {
        String category = categoryDropdown.getText().toString();
        String problemType = problemTypeDropdown.getText().toString();
        String mainLocation = locationDropdown.getText().toString();
        String subLocation = subLocationEdit.getText().toString().trim();
        String desc = descriptionEdit.getText().toString().trim();

        if (category.isEmpty() || problemType.isEmpty() || mainLocation.isEmpty() || desc.isEmpty()) {
            Toast.makeText(this, "Please fill all mandatory fields", Toast.LENGTH_SHORT).show();
            return;
        }

        String combinedLocation = mainLocation + (subLocation.isEmpty() ? "" : " - " + subLocation);
        submitComplaint(category, problemType, combinedLocation, desc);
    }

    private void submitComplaint(String category, String problemType, String location, String desc) {
        progressBar.setVisibility(View.VISIBLE);
        submitBtn.setEnabled(false);

        if (imageUri != null || cameraBitmap != null) {
            uploadImageAndSubmit(category, problemType, location, desc);
        } else {
            postToDatabase(category, problemType, location, desc, null);
        }
    }

    private void uploadImageAndSubmit(String category, String problemType, String location, String desc) {
        try {
            byte[] imageData;
            if (imageUri != null) imageData = getBytesFromUri(imageUri);
            else imageData = getBytesFromBitmap(cameraBitmap);

            if (imageData == null) {
                postToDatabase(category, problemType, location, desc, null);
                return;
            }

            // Using format from your screenshot: complaint_TIMESTAMP.jpg
            String fileName = "complaint_" + System.currentTimeMillis() + ".jpg";
            String bucket = "complaints"; 
            String path = fileName;

            SupabaseApi api = SupabaseConfig.getApi();
            RequestBody requestBody = RequestBody.create(MediaType.parse("image/jpeg"), imageData);
            String authHeader = "Bearer " + userPrefs.getString("access_token", "");

            api.uploadImage(SupabaseConfig.API_KEY, authHeader, "image/jpeg", "true", bucket, path, requestBody)
                    .enqueue(new Callback<ResponseBody>() {
                        @Override
                        public void onResponse(Call<ResponseBody> call, Response<ResponseBody> response) {
                            if (response.isSuccessful()) {
                                String baseUrl = SupabaseConfig.URL;
                                if (baseUrl.endsWith("/")) baseUrl = baseUrl.substring(0, baseUrl.length() - 1);
                                String publicUrl = baseUrl + "/storage/v1/object/public/" + bucket + "/" + path;
                                Log.d(TAG, "Upload successful. Public URL: " + publicUrl);
                                postToDatabase(category, problemType, location, desc, publicUrl);
                            } else {
                                Log.e(TAG, "Upload failed. Code: " + response.code());
                                postToDatabase(category, problemType, location, desc, null);
                            }
                        }
                        @Override
                        public void onFailure(Call<ResponseBody> call, Throwable t) {
                            Log.e(TAG, "Upload failed. Error: " + t.getMessage());
                            postToDatabase(category, problemType, location, desc, null);
                        }
                    });
        } catch (Exception e) {
            Log.e(TAG, "Exception during upload setup: " + e.getMessage());
            postToDatabase(category, problemType, location, desc, null);
        }
    }

    private byte[] getBytesFromUri(Uri uri) throws IOException {
        InputStream inputStream = getContentResolver().openInputStream(uri);
        if (inputStream == null) return null;
        Bitmap bitmap = BitmapFactory.decodeStream(inputStream);
        inputStream.close();
        return getBytesFromBitmap(bitmap);
    }

    private byte[] getBytesFromBitmap(Bitmap bitmap) {
        if (bitmap == null) return null;
        ByteArrayOutputStream stream = new ByteArrayOutputStream();
        int maxWidth = 1024, maxHeight = 1024;
        float ratio = Math.min((float) maxWidth / bitmap.getWidth(), (float) maxHeight / bitmap.getHeight());
        if (ratio < 1.0f) {
            bitmap = Bitmap.createScaledBitmap(bitmap, (int) (bitmap.getWidth() * ratio), (int) (bitmap.getHeight() * ratio), true);
        }
        bitmap.compress(Bitmap.CompressFormat.JPEG, 80, stream);
        return stream.toByteArray();
    }

    private void postToDatabase(String category, String problemType, String location, String desc, String photoUrl) {
        Issue issue = new Issue();
        issue.setCategory(category);
        issue.setProblemType(problemType);
        issue.setLocation(location);
        issue.setDescription(desc);
        issue.setPhotoUrl(photoUrl);
        issue.setStatus("Pending");
        issue.setUserName(userPrefs.getString("name", "Unknown") + " / " + userPrefs.getString("student_id", ""));
        issue.setUserId(userPrefs.getString("user_id", ""));

        SupabaseApi api = SupabaseConfig.getApi();
        String authHeader = "Bearer " + userPrefs.getString("access_token", "");

        api.insertIssue(SupabaseConfig.API_KEY, authHeader, issue).enqueue(new Callback<List<Issue>>() {
            @Override
            public void onResponse(Call<List<Issue>> call, Response<List<Issue>> response) {
                progressBar.setVisibility(View.GONE);
                if (response.isSuccessful()) {
                    if (response.body() != null && !response.body().isEmpty()) {
                        sendAdminNotification(response.body().get(0));
                    }
                    Toast.makeText(ComplaintActivity.this, "Complaint Submitted Successfully", Toast.LENGTH_LONG).show();
                    finish();
                } else {
                    submitBtn.setEnabled(true);
                    Toast.makeText(ComplaintActivity.this, "Error saving data.", Toast.LENGTH_SHORT).show();
                }
            }
            @Override
            public void onFailure(Call<List<Issue>> call, Throwable t) {
                progressBar.setVisibility(View.GONE);
                submitBtn.setEnabled(true);
            }
        });
    }

    private void sendAdminNotification(Issue issue) {
        String studentName = userPrefs.getString("name", "Student");
        Notification notification = new Notification("Admin", "New Complaint Raised", 
                "A new " + issue.getCategory() + " complaint has been raised by " + studentName, 
                issue.getId());
        
        String authHeader = "Bearer " + userPrefs.getString("access_token", "");
        SupabaseConfig.getApi().sendNotification(SupabaseConfig.API_KEY, authHeader, notification)
                .enqueue(new Callback<Void>() {
                    @Override public void onResponse(Call<Void> call, Response<Void> response) {
                        Log.d(TAG, "Admin notification sent successfully");
                    }
                    @Override public void onFailure(Call<Void> call, Throwable t) {
                        Log.e(TAG, "Failed to send admin notification", t);
                    }
                });
    }
}
