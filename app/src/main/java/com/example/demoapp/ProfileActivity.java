package com.example.demoapp;

import android.app.DatePickerDialog;
import android.content.Intent;
import android.content.SharedPreferences;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Canvas;
import android.graphics.Paint;
import android.graphics.PorterDuff;
import android.graphics.PorterDuffXfermode;
import android.graphics.Rect;
import android.net.Uri;
import android.os.Bundle;
import android.provider.MediaStore;
import android.util.Base64;
import android.util.Log;
import android.view.View;
import android.widget.ArrayAdapter;
import android.widget.AutoCompleteTextView;
import android.widget.Button;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.ProgressBar;
import android.widget.Toast;
import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;
import com.google.android.material.textfield.TextInputEditText;
import com.google.android.material.textfield.TextInputLayout;
import com.google.mlkit.vision.common.InputImage;
import com.google.mlkit.vision.face.FaceDetection;
import com.google.mlkit.vision.face.FaceDetector;
import com.google.mlkit.vision.face.FaceDetectorOptions;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.Date;
import java.util.HashMap;
import java.util.Locale;
import java.util.Map;
import okhttp3.ResponseBody;
import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;
import retrofit2.Retrofit;
import retrofit2.converter.gson.GsonConverterFactory;

public class ProfileActivity extends AppCompatActivity {

    private static final int PICK_IMAGE_REQUEST = 1;
    private static final String TAG = "ProfileActivity";

    // Common Views
    private TextInputEditText profileName, profileEmail, profilePhone, profileDob, profileRole;
    private AutoCompleteTextView profileGender;
    private TextInputLayout profilePhoneLayout, profileDobLayout, profileGenderLayout;
    private View dobGenderContainer;
    private ImageView profileImage;
    private View editImage;
    private Button updateProfileBtn;
    private ProgressBar progressBar;

    // Role Specific Sections
    private LinearLayout studentSection, facultySection, adminSection, workerSection;

    // Role Specific Fields
    private TextInputEditText studentId, studentDept, studentYearSem, studentCollege;
    private TextInputEditText facultyId, facultyDept, facultyDesignation, facultySubjects, facultyOffice;
    private TextInputEditText adminId, adminDept, adminPosition;
    private TextInputEditText workerId, workerDept, workerSkills, workerExperience, workerCategory;

    private SharedPreferences userPrefs;
    private String encodedImage = "";
    private String currentRole = "Student";
    private String originalEmail = "";
    private boolean isAdminEditing = false;
    private String targetUserId = "";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        ThemeHelper.applyTheme(this);
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_profile);

        userPrefs = getSharedPreferences("UserPrefs", MODE_PRIVATE);
        isAdminEditing = getIntent().getBooleanExtra("is_admin_editing", false);
        
        String loggedInRole = userPrefs.getString("role", "");
        boolean isLoggedAsAdmin = loggedInRole.equalsIgnoreCase("Admin") || loggedInRole.equalsIgnoreCase("Administrator");

        if (isAdminEditing) {
            currentRole = getIntent().getStringExtra("user_role");
            if (currentRole == null) currentRole = getIntent().getStringExtra("role");
            if (currentRole == null) currentRole = "Student";
            
            originalEmail = getIntent().getStringExtra("email_id");
            if (originalEmail == null) originalEmail = getIntent().getStringExtra("email");
            
            targetUserId = getIntent().getStringExtra("id");
        } else {
            currentRole = userPrefs.getString("role", "Student");
            originalEmail = userPrefs.getString("email", "");
            targetUserId = userPrefs.getString("user_id", "");
        }

        initializeViews();
        setupGenderSpinner();
        setupDatePicker();
        
        loadUserData();
        updateRoleVisibility();

        // Admin can edit name, DOB, and Gender. Students/Users cannot.
        if (!isLoggedAsAdmin && !isAdminEditing) {
            profileName.setEnabled(false);
            profileDob.setEnabled(false);
            profileGender.setEnabled(false);
        } else {
            // Explicitly enable for Admins
            profileName.setEnabled(true);
            profileDob.setEnabled(true);
            profileGender.setEnabled(true);
        }

        editImage.setOnClickListener(v -> openImagePicker());
        profileImage.setOnClickListener(v -> openImagePicker());

        updateProfileBtn.setOnClickListener(v -> saveUserData());

        View backBtn = findViewById(R.id.backBtn);
        if (backBtn != null) {
            backBtn.setOnClickListener(v -> finish());
        }
    }

    private void initializeViews() {
        profileName = findViewById(R.id.profileName);
        profileEmail = findViewById(R.id.profileEmail);
        profilePhone = findViewById(R.id.profilePhone);
        profileDob = findViewById(R.id.profileDob);
        profileGender = findViewById(R.id.profileGender);
        profileRole = findViewById(R.id.profileRole);
        
        profilePhoneLayout = findViewById(R.id.profilePhoneLayout);
        profileDobLayout = findViewById(R.id.profileDobLayout);
        profileGenderLayout = findViewById(R.id.profileGenderLayout);
        dobGenderContainer = findViewById(R.id.dobGenderContainer);

        profileImage = findViewById(R.id.profileImage);
        editImage = findViewById(R.id.editImage);
        updateProfileBtn = findViewById(R.id.updateProfileBtn);
        progressBar = findViewById(R.id.progressBar);
        
        studentSection = findViewById(R.id.studentSection);
        facultySection = findViewById(R.id.facultySection);
        adminSection = findViewById(R.id.adminSection);
        workerSection = findViewById(R.id.workerSection);

        studentId = findViewById(R.id.studentId);
        studentDept = findViewById(R.id.studentDept);
        studentYearSem = findViewById(R.id.studentYearSem);
        studentCollege = findViewById(R.id.studentCollege);

        facultyId = findViewById(R.id.facultyId);
        facultyDept = findViewById(R.id.facultyDept);
        facultyDesignation = findViewById(R.id.facultyDesignation);
        facultySubjects = findViewById(R.id.facultySubjects);
        facultyOffice = findViewById(R.id.facultyOffice);

        adminId = findViewById(R.id.adminId);
        adminDept = findViewById(R.id.adminDept);
        adminPosition = findViewById(R.id.adminPosition);

        workerId = findViewById(R.id.workerId);
        workerDept = findViewById(R.id.workerDept);
        workerSkills = findViewById(R.id.workerSkills);
        workerExperience = findViewById(R.id.workerExperience);
        workerCategory = findViewById(R.id.workerCategory);
    }

    private void setupGenderSpinner() {
        String[] genders = {"Male", "Female", "Other"};
        ArrayAdapter<String> adapter = new ArrayAdapter<>(this, android.R.layout.simple_dropdown_item_1line, genders);
        profileGender.setAdapter(adapter);
    }

    private void setupDatePicker() {
        profileDob.setOnClickListener(v -> {
            String loggedInRole = userPrefs.getString("role", "");
            boolean isLoggedAsAdmin = loggedInRole.equalsIgnoreCase("Admin") || loggedInRole.equalsIgnoreCase("Administrator");
            
            if (!isLoggedAsAdmin && !isAdminEditing) return;

            Calendar calendar = Calendar.getInstance();
            int year = calendar.get(Calendar.YEAR);
            int month = calendar.get(Calendar.MONTH);
            int day = calendar.get(Calendar.DAY_OF_MONTH);

            DatePickerDialog datePickerDialog = new DatePickerDialog(this, (view, year1, month1, dayOfMonth) -> {
                Calendar c = Calendar.getInstance();
                c.set(year1, month1, dayOfMonth);
                SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy", Locale.getDefault());
                profileDob.setText(sdf.format(c.getTime()));
            }, year, month, day);
            datePickerDialog.show();
        });
    }

    private void updateRoleVisibility() {
        studentSection.setVisibility(View.GONE);
        facultySection.setVisibility(View.GONE);
        adminSection.setVisibility(View.GONE);
        workerSection.setVisibility(View.GONE);

        if (currentRole != null) {
            boolean isUserAdmin = currentRole.equalsIgnoreCase("Admin") || currentRole.equalsIgnoreCase("Administrator");
            
            if (isUserAdmin) {
                adminSection.setVisibility(View.VISIBLE);
                // Hide fields not present in the 'admins' table schema
                if (profilePhoneLayout != null) profilePhoneLayout.setVisibility(View.GONE);
                if (dobGenderContainer != null) dobGenderContainer.setVisibility(View.GONE);
            } else {
                if (profilePhoneLayout != null) profilePhoneLayout.setVisibility(View.VISIBLE);
                if (dobGenderContainer != null) dobGenderContainer.setVisibility(View.VISIBLE);
                
                if (currentRole.equalsIgnoreCase("Student")) studentSection.setVisibility(View.VISIBLE);
                else if (currentRole.equalsIgnoreCase("Faculty")) facultySection.setVisibility(View.VISIBLE);
                else if (currentRole.equalsIgnoreCase("Executor/Worker") || currentRole.equalsIgnoreCase("Worker")) workerSection.setVisibility(View.VISIBLE);
            }
        }
    }

    private void openImagePicker() {
        Intent intent = new Intent(Intent.ACTION_PICK, MediaStore.Images.Media.EXTERNAL_CONTENT_URI);
        startActivityForResult(intent, PICK_IMAGE_REQUEST);
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, @Nullable Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (resultCode == RESULT_OK && data != null && requestCode == PICK_IMAGE_REQUEST) {
            Uri imageUri = data.getData();
            if (imageUri != null) detectFaceAndProceed(imageUri);
        }
    }

    private void detectFaceAndProceed(Uri imageUri) {
        progressBar.setVisibility(View.VISIBLE);
        new Thread(() -> {
            try {
                InputStream inputStream = getContentResolver().openInputStream(imageUri);
                Bitmap bitmap = BitmapFactory.decodeStream(inputStream);
                if (bitmap == null) {
                    runOnUiThread(() -> progressBar.setVisibility(View.GONE));
                    return;
                }

                InputImage image = InputImage.fromBitmap(bitmap, 0);
                FaceDetectorOptions options = new FaceDetectorOptions.Builder()
                        .setPerformanceMode(FaceDetectorOptions.PERFORMANCE_MODE_FAST)
                        .build();
                FaceDetector detector = FaceDetection.getClient(options);

                detector.process(image)
                        .addOnSuccessListener(faces -> {
                            if (faces.size() > 0) {
                                runOnUiThread(() -> handleBitmap(bitmap));
                            } else {
                                runOnUiThread(() -> {
                                    progressBar.setVisibility(View.GONE);
                                    Toast.makeText(this, "No face detected. Please select a clear face image.", Toast.LENGTH_LONG).show();
                                });
                            }
                        })
                        .addOnFailureListener(e -> {
                            runOnUiThread(() -> {
                                progressBar.setVisibility(View.GONE);
                                Toast.makeText(this, "Face detection failed.", Toast.LENGTH_SHORT).show();
                            });
                        });
            } catch (IOException e) {
                runOnUiThread(() -> progressBar.setVisibility(View.GONE));
                e.printStackTrace();
            }
        }).start();
    }

    private void handleBitmap(Bitmap bitmap) {
        Bitmap circularBitmap = getCircularBitmap(bitmap);
        profileImage.setImageBitmap(circularBitmap);
        encodedImage = encodeImage(circularBitmap);
        progressBar.setVisibility(View.GONE);
    }

    private Bitmap getCircularBitmap(Bitmap bitmap) {
        int width = bitmap.getWidth();
        int height = bitmap.getHeight();
        int newSize = Math.min(width, height);
        Bitmap output = Bitmap.createBitmap(newSize, newSize, Bitmap.Config.ARGB_8888);
        Canvas canvas = new Canvas(output);
        final Paint paint = new Paint();
        paint.setAntiAlias(true);
        canvas.drawCircle(newSize / 2f, newSize / 2f, newSize / 2f, paint);
        paint.setXfermode(new PorterDuffXfermode(PorterDuff.Mode.SRC_IN));
        int left = (width - newSize) / 2;
        int top = (height - newSize) / 2;
        canvas.drawBitmap(bitmap, new Rect(left, top, left + newSize, top + newSize), new Rect(0, 0, newSize, newSize), paint);
        return output;
    }

    private String encodeImage(Bitmap bitmap) {
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        bitmap.compress(Bitmap.CompressFormat.PNG, 100, baos);
        return Base64.encodeToString(baos.toByteArray(), Base64.NO_WRAP);
    }

    private void loadUserData() {
        String name, email, phone, dob, gender, img;
        if (isAdminEditing) {
            name = getIntent().getStringExtra("full_name");
            if (name == null) name = getIntent().getStringExtra("name");
            email = originalEmail;
            phone = getIntent().getStringExtra("mobile_number");
            dob = getIntent().getStringExtra("dob");
            gender = getIntent().getStringExtra("gender");
            img = getIntent().getStringExtra("profile_image");
        } else {
            name = userPrefs.getString("name", "");
            email = userPrefs.getString("email", "");
            phone = userPrefs.getString("phone", "");
            dob = userPrefs.getString("dob", "");
            gender = userPrefs.getString("gender", "");
            img = userPrefs.getString("profileImage", "");
        }

        profileName.setText(name);
        profileEmail.setText(email);
        profilePhone.setText(phone);
        profileDob.setText(dob);
        profileGender.setText(gender, false);
        profileRole.setText(currentRole);
        encodedImage = img != null ? img : "";

        if (!encodedImage.isEmpty() && !encodedImage.equals("null")) {
            try {
                byte[] decodedString = Base64.decode(encodedImage, Base64.NO_WRAP);
                profileImage.setImageBitmap(BitmapFactory.decodeByteArray(decodedString, 0, decodedString.length));
            } catch (Exception e) { e.printStackTrace(); }
        }

        if (currentRole != null) {
            if (currentRole.equalsIgnoreCase("Student")) {
                if (isAdminEditing) {
                    studentId.setText(getIntent().getStringExtra("student_id"));
                    studentDept.setText(getIntent().getStringExtra("department"));
                    studentYearSem.setText(getIntent().getStringExtra("year"));
                    studentCollege.setText(getIntent().getStringExtra("college_name"));
                } else {
                    studentId.setText(userPrefs.getString("student_id", ""));
                    studentDept.setText(userPrefs.getString("department", ""));
                    studentYearSem.setText(userPrefs.getString("year", ""));
                    studentCollege.setText(userPrefs.getString("college_name", ""));
                }
            } else if (currentRole.equalsIgnoreCase("Faculty")) {
                if (isAdminEditing) {
                    facultyId.setText(getIntent().getStringExtra("faculty_id"));
                    facultyDept.setText(getIntent().getStringExtra("department"));
                    facultyDesignation.setText(getIntent().getStringExtra("designation"));
                    facultySubjects.setText(getIntent().getStringExtra("subjects"));
                    facultyOffice.setText(getIntent().getStringExtra("office_location"));
                } else {
                    facultyId.setText(userPrefs.getString("faculty_id", ""));
                    facultyDept.setText(userPrefs.getString("department", ""));
                    facultyDesignation.setText(userPrefs.getString("designation", ""));
                    facultySubjects.setText(userPrefs.getString("subjects", ""));
                    facultyOffice.setText(userPrefs.getString("office_location", ""));
                }
            } else if (currentRole.equalsIgnoreCase("Admin") || currentRole.equalsIgnoreCase("Administrator")) {
                if (isAdminEditing) {
                    adminId.setText(getIntent().getStringExtra("admin_id"));
                    adminDept.setText(getIntent().getStringExtra("department"));
                    adminPosition.setText(getIntent().getStringExtra("position"));
                } else {
                    adminId.setText(userPrefs.getString("admin_id", ""));
                    adminDept.setText(userPrefs.getString("department", ""));
                    adminPosition.setText(userPrefs.getString("position", ""));
                }
            } else if (currentRole.equalsIgnoreCase("Executor/Worker") || currentRole.equalsIgnoreCase("Worker")) {
                if (isAdminEditing) {
                    workerId.setText(getIntent().getStringExtra("worker_id"));
                    workerDept.setText(getIntent().getStringExtra("department"));
                    workerSkills.setText(getIntent().getStringExtra("skills"));
                    workerExperience.setText(getIntent().getStringExtra("experience"));
                    workerCategory.setText(getIntent().getStringExtra("category"));
                } else {
                    workerId.setText(userPrefs.getString("worker_id", ""));
                    workerDept.setText(userPrefs.getString("department", ""));
                    workerSkills.setText(userPrefs.getString("skills", ""));
                    workerExperience.setText(userPrefs.getString("experience", ""));
                    workerCategory.setText(userPrefs.getString("category", ""));
                }
            }
        }
    }

    private void saveUserData() {
        if (targetUserId == null || targetUserId.isEmpty()) {
            Toast.makeText(this, "Error: User identity not found. Please login again.", Toast.LENGTH_LONG).show();
            return;
        }

        String newName = profileName.getText().toString().trim();
        String newPhone = profilePhone.getText().toString().trim();
        String dobInput = profileDob.getText().toString().trim();
        String newGender = profileGender.getText().toString().trim();
        String email = profileEmail.getText().toString().trim();

        if (newName.isEmpty()) { profileName.setError("Required"); return; }

        updateProfileBtn.setEnabled(false);
        progressBar.setVisibility(View.VISIBLE);
        
        String token = userPrefs.getString("access_token", SupabaseConfig.API_KEY);
        String authHeader = token.startsWith("Bearer ") ? token : "Bearer " + token;

        Retrofit retrofit = new Retrofit.Builder()
                .baseUrl(SupabaseConfig.URL)
                .addConverterFactory(GsonConverterFactory.create())
                .build();
        SupabaseApi api = retrofit.create(SupabaseApi.class);

        // Map for database update
        Map<String, Object> updates = new HashMap<>();
        updates.put("full_name", newName);
        if (!encodedImage.isEmpty()) updates.put("profile_image", encodedImage);

        boolean isUserAdmin = currentRole.equalsIgnoreCase("Admin") || currentRole.equalsIgnoreCase("Administrator");

        if (isUserAdmin) {
            // ADMIN TABLE SCHEMA: full_name, admin_id, department, position, email, profile_image
            updates.put("email", email);
            String aId = adminId.getText().toString().trim();
            if (!aId.isEmpty()) updates.put("admin_id", aId);
            String aDept = adminDept.getText().toString().trim();
            if (!aDept.isEmpty()) updates.put("department", aDept);
            String aPos = adminPosition.getText().toString().trim();
            if (!aPos.isEmpty()) updates.put("position", aPos);
            
            // ADMIN table DOES NOT have: email_id, mobile_number, user_role, gender, dob
        } else {
            // PROFILES TABLE SCHEMA (Assuming): full_name, email_id, mobile_number, profile_image, user_role, gender, dob, etc.
            updates.put("email_id", email);
            updates.put("mobile_number", newPhone);
            updates.put("user_role", currentRole);
            updates.put("gender", newGender);
            updates.put("dob", dobInput);

            try {
                SimpleDateFormat inFmt = new SimpleDateFormat("dd/MM/yyyy", Locale.getDefault());
                SimpleDateFormat outFmt = new SimpleDateFormat("yyyy-MM-dd", Locale.getDefault());
                Date d = inFmt.parse(dobInput);
                if (d != null) updates.put("date_of_birth", outFmt.format(d));
            } catch (Exception e) { /* ignore parse error */ }

            if (currentRole.equalsIgnoreCase("Student")) {
                updates.put("student_id", studentId.getText().toString().trim());
                updates.put("department", studentDept.getText().toString().trim());
                updates.put("year", studentYearSem.getText().toString().trim());
                updates.put("college_name", studentCollege.getText().toString().trim());
            } else if (currentRole.equalsIgnoreCase("Faculty")) {
                updates.put("faculty_id", facultyId.getText().toString().trim());
                updates.put("department", facultyDept.getText().toString().trim());
                updates.put("designation", facultyDesignation.getText().toString().trim());
                updates.put("subjects", facultySubjects.getText().toString().trim());
                updates.put("office_location", facultyOffice.getText().toString().trim());
            } else if (currentRole.equalsIgnoreCase("Executor/Worker") || currentRole.equalsIgnoreCase("Worker")) {
                updates.put("worker_id", workerId.getText().toString().trim());
                updates.put("department", workerDept.getText().toString().trim());
                updates.put("skills", workerSkills.getText().toString().trim());
                updates.put("experience", workerExperience.getText().toString().trim());
                updates.put("category", workerCategory.getText().toString().trim());
            }
        }

        Map<String, String> filters = new HashMap<>();
        filters.put("id", "eq." + targetUserId);

        // 1. Sync Auth Metadata (Only for self-edit)
        if (!isAdminEditing) {
            Map<String, Object> authData = new HashMap<>();
            Map<String, Object> metadata = new HashMap<>();
            metadata.put("full_name", newName);
            metadata.put("user_type", currentRole);
            authData.put("data", metadata);
            api.updateUserAuth(SupabaseConfig.API_KEY, authHeader, authData).enqueue(new Callback<ResponseBody>() {
                @Override public void onResponse(Call<ResponseBody> call, Response<ResponseBody> response) {}
                @Override public void onFailure(Call<ResponseBody> call, Throwable t) {}
            });
        }

        // 2. Update Correct Database Table
        Call<Void> dbCall;
        if (isUserAdmin) {
            dbCall = api.updateAdminProfile(SupabaseConfig.API_KEY, authHeader, filters, updates);
        } else {
            dbCall = api.updateProfile(SupabaseConfig.API_KEY, authHeader, filters, updates);
        }

        dbCall.enqueue(new Callback<Void>() {
                @Override
                public void onResponse(Call<Void> call, Response<Void> response) {
                    if (response.isSuccessful()) {
                        updateLocalData(newName, newPhone, email, dobInput, newGender);
                        if (!isAdminEditing) {
                            sendAdminNotification(newName, "Profile Updated");
                        }
                        Toast.makeText(ProfileActivity.this, "Profile Updated Successfully!", Toast.LENGTH_SHORT).show();
                        setResult(RESULT_OK);
                        finish();
                    } else {
                        Log.e(TAG, "Update failed: " + response.code());
                        Toast.makeText(ProfileActivity.this, "Update Failed: " + response.code() + ". Check column names.", Toast.LENGTH_LONG).show();
                    }
                    updateProfileBtn.setEnabled(true);
                    progressBar.setVisibility(View.GONE);
                }

                @Override
                public void onFailure(Call<Void> call, Throwable t) {
                    updateProfileBtn.setEnabled(true);
                    progressBar.setVisibility(View.GONE);
                    Toast.makeText(ProfileActivity.this, "Network error", Toast.LENGTH_SHORT).show();
                }
            });
    }

    private void sendAdminNotification(String studentName, String action) {
        String title = "User Activity: " + action;
        String message = studentName + " has updated their profile details.";
        
        Notification notification = new Notification("Admin", title, message);
        
        Retrofit retrofit = new Retrofit.Builder()
                .baseUrl(SupabaseConfig.URL)
                .addConverterFactory(GsonConverterFactory.create())
                .build();
        SupabaseApi api = retrofit.create(SupabaseApi.class);

        api.sendNotification(SupabaseConfig.API_KEY, "Bearer " + SupabaseConfig.API_KEY, notification)
                .enqueue(new Callback<Void>() {
                    @Override
                    public void onResponse(Call<Void> call, Response<Void> response) {
                        Log.d(TAG, "Admin notification sent");
                    }
                    @Override
                    public void onFailure(Call<Void> call, Throwable t) {
                        Log.e(TAG, "Failed to notify admin");
                    }
                });
    }

    private void updateLocalData(String name, String phone, String email, String dob, String gender) {
        if (!isAdminEditing) {
            SharedPreferences.Editor editor = userPrefs.edit();
            editor.putString("name", name);
            editor.putString("phone", phone);
            editor.putString("email", email);
            editor.putString("dob", dob);
            editor.putString("gender", gender);
            if (!encodedImage.isEmpty()) editor.putString("profileImage", encodedImage);
            
            if (currentRole.equalsIgnoreCase("Student")) {
                editor.putString("student_id", studentId.getText().toString());
                editor.putString("department", studentDept.getText().toString());
                editor.putString("year", studentYearSem.getText().toString());
                editor.putString("college_name", studentCollege.getText().toString());
            } else if (currentRole.equalsIgnoreCase("Admin") || currentRole.equalsIgnoreCase("Administrator")) {
                editor.putString("admin_id", adminId.getText().toString());
                editor.putString("department", adminDept.getText().toString());
                editor.putString("position", adminPosition.getText().toString());
            } else if (currentRole.equalsIgnoreCase("Faculty")) {
                editor.putString("faculty_id", facultyId.getText().toString());
                editor.putString("department", facultyDept.getText().toString());
                editor.putString("designation", facultyDesignation.getText().toString());
                editor.putString("subjects", facultySubjects.getText().toString());
                editor.putString("office_location", facultyOffice.getText().toString());
            } else if (currentRole.equalsIgnoreCase("Executor/Worker") || currentRole.equalsIgnoreCase("Worker")) {
                editor.putString("worker_id", workerId.getText().toString());
                editor.putString("department", workerDept.getText().toString());
                editor.putString("skills", workerSkills.getText().toString());
                editor.putString("experience", workerExperience.getText().toString());
                editor.putString("category", workerCategory.getText().toString());
            }
            editor.apply();
        }
    }
}
