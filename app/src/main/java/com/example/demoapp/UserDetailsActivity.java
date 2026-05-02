package com.example.demoapp;

import android.content.Intent;
import android.content.SharedPreferences;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.os.Bundle;
import android.util.Base64;
import android.view.View;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;
import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;
import com.google.android.material.button.MaterialButton;
import com.google.android.material.color.MaterialColors;

public class UserDetailsActivity extends AppCompatActivity {

    private boolean isViewOnly;
    private SharedPreferences userPrefs;
    private MaterialButton editBtn;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        ThemeHelper.applyTheme(this);
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_user_details);

        userPrefs = getSharedPreferences("UserPrefs", MODE_PRIVATE);
        isViewOnly = getIntent().getBooleanExtra("is_view_only", false);
        editBtn = findViewById(R.id.editBtn);
        
        loadData();

        View closeBtn = findViewById(R.id.backBtn);
        if (closeBtn != null) {
            closeBtn.setOnClickListener(v -> finish());
        }

        setupEditButton();
    }

    private void setupEditButton() {
        String loggedInUserRole = userPrefs.getString("role", "");
        boolean isAdmin = loggedInUserRole.equalsIgnoreCase("Admin") || loggedInUserRole.equalsIgnoreCase("Administrator");

        // Only show Edit button if current user is an Admin AND they are viewing another user's profile
        if (isAdmin && isViewOnly) {
            editBtn.setVisibility(View.VISIBLE);
            editBtn.setOnClickListener(v -> {
                Intent intent = new Intent(this, ProfileActivity.class);
                intent.putExtra("is_admin_editing", true);
                
                // Pass all current details to ProfileActivity
                Bundle extras = getIntent().getExtras();
                if (extras != null) {
                    intent.putExtras(extras);
                }
                startActivity(intent);
            });
        } else {
            editBtn.setVisibility(View.GONE);
        }
    }

    private void loadData() {
        ImageView profileImage = findViewById(R.id.detailProfileImage);
        TextView nameText = findViewById(R.id.detailName);
        TextView emailText = findViewById(R.id.detailEmail);
        TextView roleBadge = findViewById(R.id.detailRoleBadge);
        LinearLayout container = findViewById(R.id.detailsContainer);
        container.removeAllViews();

        String name, email, encodedImage, role;

        if (isViewOnly) {
            name = getIntent().getStringExtra("full_name");
            if (name == null) name = getIntent().getStringExtra("name");
            role = getIntent().getStringExtra("user_role");
            if (role == null) role = getIntent().getStringExtra("role");
            email = getIntent().getStringExtra("email_id");
            if (email == null) email = getIntent().getStringExtra("email");
            encodedImage = getIntent().getStringExtra("profile_image");
        } else {
            name = userPrefs.getString("name", "User");
            role = userPrefs.getString("role", "Student");
            email = userPrefs.getString("email", "");
            encodedImage = prefsEncodedImage();
        }

        nameText.setText(name != null && !name.isEmpty() ? name : "N/A");
        emailText.setText(email != null && !email.isEmpty() ? email : "N/A");
        roleBadge.setText(role != null ? role.toUpperCase() : "USER");

        if (encodedImage != null && !encodedImage.isEmpty() && !encodedImage.equals("null")) {
            try {
                byte[] decodedString = Base64.decode(encodedImage, Base64.DEFAULT);
                Bitmap decodedByte = BitmapFactory.decodeByteArray(decodedString, 0, decodedString.length);
                profileImage.setImageBitmap(decodedByte);
            } catch (Exception e) {
                profileImage.setImageResource(R.mipmap.ic_launcher_round);
            }
        }

        boolean isRoleAdmin = role != null && (role.equalsIgnoreCase("Admin") || role.equalsIgnoreCase("Administrator"));

        // Match sections and fields with ProfileActivity's update profile section for Admins
        if (isRoleAdmin) {
            // Basic Information for Admin
            addSectionTitle(container, "Basic Information");
            if (isViewOnly) {
                addDetailRow(container, "Full Name", name);
                addDetailRow(container, "Email Address", email);
            } else {
                addDetailRow(container, "Full Name", userPrefs.getString("name", "N/A"));
                addDetailRow(container, "Email Address", userPrefs.getString("email", "N/A"));
            }
            
            // Admin Specific Information
            addSectionTitle(container, "Admin Specific Information");
            if (isViewOnly) {
                addDetailRow(container, "Admin ID", getIntent().getStringExtra("admin_id"));
                addDetailRow(container, "Department / Office", getIntent().getStringExtra("department"));
                addDetailRow(container, "Position", getIntent().getStringExtra("position"));
            } else {
                addDetailRow(container, "Admin ID", userPrefs.getString("admin_id", "N/A"));
                addDetailRow(container, "Department / Office", userPrefs.getString("department", "N/A"));
                addDetailRow(container, "Position", userPrefs.getString("position", "N/A"));
            }
        } else {
            // For other roles, keep existing logic but ensure it aligns with their "Update Profile" sections
            addSectionTitle(container, "Basic Information");
            if (isViewOnly) {
                addDetailRow(container, "Full Name", name);
                addDetailRow(container, "Email Address", email);
                addDetailRow(container, "Phone Number", getIntent().getStringExtra("mobile_number"));
                addDetailRow(container, "Date of Birth", getIntent().getStringExtra("dob"));
                addDetailRow(container, "Gender", getIntent().getStringExtra("gender"));
            } else {
                addDetailRow(container, "Full Name", name);
                addDetailRow(container, "Email Address", email);
                addDetailRow(container, "Phone Number", userPrefs.getString("phone", "N/A"));
                addDetailRow(container, "Date of Birth", userPrefs.getString("dob", "N/A"));
                addDetailRow(container, "Gender", userPrefs.getString("gender", "N/A"));
            }

            addSectionTitle(container, "Role Specific Information");
            if (role != null && role.equalsIgnoreCase("Student")) {
                if (isViewOnly) {
                    addDetailRow(container, "Student ID", getIntent().getStringExtra("student_id"));
                    addDetailRow(container, "Department", getIntent().getStringExtra("department"));
                    addDetailRow(container, "Course / Program", getIntent().getStringExtra("program"));
                    addDetailRow(container, "Academic Year", getIntent().getStringExtra("year"));
                    addDetailRow(container, "College Name", getIntent().getStringExtra("college_name"));
                } else {
                    addDetailRow(container, "Student ID", userPrefs.getString("student_id", "N/A"));
                    addDetailRow(container, "Department", userPrefs.getString("department", "N/A"));
                    addDetailRow(container, "Course / Program", userPrefs.getString("program", "N/A"));
                    addDetailRow(container, "Academic Year", userPrefs.getString("year", "N/A"));
                    addDetailRow(container, "College Name", userPrefs.getString("college_name", "N/A"));
                }
            } else if (role != null && role.equalsIgnoreCase("Faculty")) {
                if (isViewOnly) {
                    addDetailRow(container, "Faculty ID", getIntent().getStringExtra("faculty_id"));
                    addDetailRow(container, "Department", getIntent().getStringExtra("department"));
                    addDetailRow(container, "Designation", getIntent().getStringExtra("designation"));
                    addDetailRow(container, "Subjects Handling", getIntent().getStringExtra("subjects"));
                    addDetailRow(container, "Office Room Number", getIntent().getStringExtra("office_location"));
                } else {
                    addDetailRow(container, "Faculty ID", userPrefs.getString("faculty_id", "N/A"));
                    addDetailRow(container, "Department", userPrefs.getString("department", "N/A"));
                    addDetailRow(container, "Designation", userPrefs.getString("designation", "N/A"));
                    addDetailRow(container, "Subjects Handling", userPrefs.getString("subjects", "N/A"));
                    addDetailRow(container, "Office Room Number", userPrefs.getString("office_location", "N/A"));
                }
            } else if (role != null && (role.equalsIgnoreCase("Executor/Worker") || role.equalsIgnoreCase("Worker"))) {
                if (isViewOnly) {
                    addDetailRow(container, "Worker ID", getIntent().getStringExtra("worker_id"));
                    addDetailRow(container, "Department", getIntent().getStringExtra("department"));
                    addDetailRow(container, "Skills / Expertise", getIntent().getStringExtra("skills"));
                    addDetailRow(container, "Experience (Years)", getIntent().getStringExtra("experience"));
                    addDetailRow(container, "Work Category", getIntent().getStringExtra("category"));
                } else {
                    addDetailRow(container, "Worker ID", userPrefs.getString("worker_id", "N/A"));
                    addDetailRow(container, "Department", userPrefs.getString("department", "N/A"));
                    addDetailRow(container, "Skills / Expertise", userPrefs.getString("skills", "N/A"));
                    addDetailRow(container, "Experience (Years)", userPrefs.getString("experience", "N/A"));
                    addDetailRow(container, "Work Category", userPrefs.getString("category", "N/A"));
                }
            }
        }
    }

    private String prefsEncodedImage() {
        return userPrefs.getString("profileImage", "");
    }

    private void addSectionTitle(LinearLayout container, String title) {
        TextView tv = new TextView(this);
        tv.setText(title);
        tv.setTextSize(14);
        // Use MaterialColors to resolve colorPrimary from the current theme
        int colorPrimary = MaterialColors.getColor(this, com.google.android.material.R.attr.colorPrimary, android.graphics.Color.BLUE);
        tv.setTextColor(colorPrimary);
        tv.setPadding(0, 32, 0, 8);
        tv.setTypeface(null, android.graphics.Typeface.BOLD);
        container.addView(tv);
    }

    private void addDetailRow(LinearLayout container, String label, String value) {
        View row = getLayoutInflater().inflate(android.R.layout.simple_list_item_2, container, false);
        TextView text1 = row.findViewById(android.R.id.text1);
        TextView text2 = row.findViewById(android.R.id.text2);
        
        text1.setText(label);
        text1.setTextSize(12);
        text1.setAlpha(0.6f);
        
        text2.setText(value != null && !value.isEmpty() && !value.equals("null") ? value : "Not provided");
        text2.setTextSize(16);
        text2.setTypeface(null, android.graphics.Typeface.BOLD);
        
        row.setPadding(0, 16, 0, 16);
        container.addView(row);
    }
}
