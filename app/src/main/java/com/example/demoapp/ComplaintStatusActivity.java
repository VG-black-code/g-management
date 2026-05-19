package com.example.demoapp;

import android.content.Intent;
import android.content.SharedPreferences;
import android.graphics.Color;
import android.os.Bundle;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.ProgressBar;
import android.widget.TextView;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.content.ContextCompat;

import com.bumptech.glide.Glide;
import com.github.mikephil.charting.charts.BarChart;
import com.github.mikephil.charting.charts.PieChart;
import com.github.mikephil.charting.components.XAxis;
import com.github.mikephil.charting.data.BarData;
import com.github.mikephil.charting.data.BarDataSet;
import com.github.mikephil.charting.data.BarEntry;
import com.github.mikephil.charting.data.PieData;
import com.github.mikephil.charting.data.PieDataSet;
import com.github.mikephil.charting.data.PieEntry;
import com.github.mikephil.charting.formatter.IndexAxisValueFormatter;
import com.github.mikephil.charting.utils.ColorTemplate;
import com.google.gson.Gson;

import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.TimeZone;

import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;
import retrofit2.Retrofit;
import retrofit2.converter.gson.GsonConverterFactory;

public class ComplaintStatusActivity extends AppCompatActivity {

    private static final String TAG = "ComplaintStatusActivity";
    private TextView pendingCount, processingCount, resolvedCount;
    private ProgressBar progressBar;
    private SharedPreferences userPrefs;
    private PieChart statusPieChart;
    private BarChart categoryBarChart;

    private LinearLayout detailsSection, detailsContainer;
    private TextView detailsTitle;
    private List<Issue> allIssues = new ArrayList<>();

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        ThemeHelper.applyTheme(this);
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_complaint_status);

        userPrefs = getSharedPreferences("UserPrefs", MODE_PRIVATE);
        
        pendingCount = findViewById(R.id.pendingCount);
        processingCount = findViewById(R.id.processingCount);
        resolvedCount = findViewById(R.id.resolvedCount);
        progressBar = findViewById(R.id.progressBar);
        statusPieChart = findViewById(R.id.statusPieChart);
        categoryBarChart = findViewById(R.id.categoryBarChart);

        detailsSection = findViewById(R.id.detailsSection);
        detailsContainer = findViewById(R.id.detailsContainer);
        detailsTitle = findViewById(R.id.detailsTitle);

        findViewById(R.id.backBtn).setOnClickListener(v -> finish());

        setupClickListeners();
        setupCharts();
        fetchComplaintCounts();
    }

    private void setupClickListeners() {
        findViewById(R.id.pendingBox).setOnClickListener(v -> showDetailsForStatus("Pending"));
        findViewById(R.id.processingBox).setOnClickListener(v -> showDetailsForStatus("Processing"));
        findViewById(R.id.resolvedBox).setOnClickListener(v -> showDetailsForStatus("Resolved"));
    }

    private void showDetailsForStatus(String status) {
        detailsSection.setVisibility(View.VISIBLE);
        detailsTitle.setText(status + " Complaints");
        detailsContainer.removeAllViews();

        List<Issue> filteredIssues = new ArrayList<>();
        for (Issue issue : allIssues) {
            if (issue.getStatus() != null && issue.getStatus().equalsIgnoreCase(status)) {
                filteredIssues.add(issue);
            }
        }

        if (filteredIssues.isEmpty()) {
            TextView emptyText = new TextView(this);
            emptyText.setText("No " + status.toLowerCase() + " complaints found.");
            emptyText.setPadding(0, 20, 0, 20);
            detailsContainer.addView(emptyText);
        } else {
            for (Issue issue : filteredIssues) {
                addIssueCard(issue);
            }
        }
        
        // Scroll to details section
        detailsSection.getParent().requestChildFocus(detailsSection, detailsSection);
    }

    private void addIssueCard(Issue issue) {
        View complaintView = LayoutInflater.from(this).inflate(R.layout.item_complaint, detailsContainer, false);
        
        ImageView itemImage = complaintView.findViewById(R.id.itemImage);
        TextView title = complaintView.findViewById(R.id.itemTitle);
        TextView room = complaintView.findViewById(R.id.itemRoom);
        TextView statusTv = complaintView.findViewById(R.id.itemStatus);
        TextView date = complaintView.findViewById(R.id.itemDate);
        TextView processDate = complaintView.findViewById(R.id.itemProcessDate);
        TextView resolveDate = complaintView.findViewById(R.id.itemResolveDate);

        title.setText(issue.getProblemType());
        room.setText("Location: " + issue.getLocation());
        
        String status = issue.getStatus();
        statusTv.setText("Status: " + status);
        
        if (status != null) {
            if (status.equalsIgnoreCase("Pending")) {
                statusTv.setTextColor(ContextCompat.getColor(this, R.color.status_pending));
            } else if (status.equalsIgnoreCase("Processing")) {
                statusTv.setTextColor(ContextCompat.getColor(this, R.color.status_in_progress));
            } else if (status.equalsIgnoreCase("Resolved") || status.equalsIgnoreCase("Approved")) {
                statusTv.setTextColor(ContextCompat.getColor(this, R.color.status_resolved));
            }
        }
        
        date.setText("Sent: " + formatDate(issue.getCreatedAt()));

        if (issue.getProcessingAt() != null) {
            processDate.setVisibility(View.VISIBLE);
            processDate.setText("Proc: " + formatDate(issue.getProcessingAt()));
        }

        if (issue.getResolvedAt() != null) {
            resolveDate.setVisibility(View.VISIBLE);
            resolveDate.setText("Res: " + formatDate(issue.getResolvedAt()));
        }

        if (issue.getPhotoUrl() != null && !issue.getPhotoUrl().isEmpty()) {
            Glide.with(this).load(issue.getPhotoUrl()).into(itemImage);
        } else {
            itemImage.setImageResource(android.R.drawable.ic_menu_gallery);
        }

        complaintView.setOnClickListener(v -> {
            Intent intent = new Intent(this, IssueDetailActivity.class);
            intent.putExtra("issue_data", new Gson().toJson(issue));
            startActivity(intent);
        });

        detailsContainer.addView(complaintView);
    }

    private String formatDate(String isoString) {
        if (isoString == null || isoString.isEmpty()) return "";
        try {
            String cleanIso = isoString;
            if (cleanIso.contains(".")) {
                cleanIso = cleanIso.substring(0, cleanIso.indexOf("."));
            }
            if (cleanIso.endsWith("Z")) {
                cleanIso = cleanIso.substring(0, cleanIso.length() - 1);
            }
            
            SimpleDateFormat inputFormat = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", Locale.getDefault());
            inputFormat.setTimeZone(TimeZone.getTimeZone("UTC"));
            Date date = inputFormat.parse(cleanIso);
            
            SimpleDateFormat outputFormat = new SimpleDateFormat("dd MMM, hh:mm a", Locale.getDefault());
            outputFormat.setTimeZone(TimeZone.getDefault());
            return outputFormat.format(date);
        } catch (Exception e) {
            return isoString;
        }
    }

    private void setupCharts() {
        // Status Pie Chart
        statusPieChart.setUsePercentValues(true);
        statusPieChart.getDescription().setEnabled(false);
        statusPieChart.setExtraOffsets(5, 10, 5, 5);
        statusPieChart.setDragDecelerationFrictionCoef(0.95f);
        statusPieChart.setDrawHoleEnabled(true);
        statusPieChart.setHoleColor(Color.TRANSPARENT);
        statusPieChart.setTransparentCircleRadius(61f);
        statusPieChart.setEntryLabelColor(Color.BLACK);
        statusPieChart.setEntryLabelTextSize(12f);

        // Category Bar Chart
        categoryBarChart.getDescription().setEnabled(false);
        categoryBarChart.setDrawGridBackground(false);
        categoryBarChart.setDrawBarShadow(false);
        categoryBarChart.setDrawValueAboveBar(true);
        categoryBarChart.setPinchZoom(false);
        categoryBarChart.setDoubleTapToZoomEnabled(false);
        
        XAxis xAxis = categoryBarChart.getXAxis();
        xAxis.setPosition(XAxis.XAxisPosition.BOTTOM);
        xAxis.setDrawGridLines(false);
        xAxis.setGranularity(1f);
        xAxis.setLabelRotationAngle(-45);
        categoryBarChart.getAxisRight().setEnabled(false);
        categoryBarChart.getAxisLeft().setDrawGridLines(false);
    }

    private void fetchComplaintCounts() {
        String userId = userPrefs.getString("user_id", "");
        String token = userPrefs.getString("access_token", SupabaseConfig.API_KEY);
        
        if (userId.isEmpty()) {
            Log.e(TAG, "User ID is empty");
            return;
        }

        progressBar.setVisibility(View.VISIBLE);

        Retrofit retrofit = new Retrofit.Builder()
                .baseUrl(SupabaseConfig.URL)
                .addConverterFactory(GsonConverterFactory.create())
                .build();
        SupabaseApi api = retrofit.create(SupabaseApi.class);

        Map<String, String> filters = new HashMap<>();
        filters.put("user_id", "eq." + userId);

        String authHeader = token.startsWith("Bearer ") ? token : "Bearer " + token;

        api.getIssues(SupabaseConfig.API_KEY, authHeader, filters)
                .enqueue(new Callback<List<Issue>>() {
                    @Override
                    public void onResponse(Call<List<Issue>> call, Response<List<Issue>> response) {
                        progressBar.setVisibility(View.GONE);
                        if (response.isSuccessful() && response.body() != null) {
                            allIssues = response.body();
                            processIssueData(allIssues);
                        } else {
                            Log.e(TAG, "Failed to fetch issues: " + response.code());
                        }
                    }

                    @Override
                    public void onFailure(Call<List<Issue>> call, Throwable t) {
                        progressBar.setVisibility(View.GONE);
                        Log.e(TAG, "Network Error", t);
                    }
                });
    }

    private void processIssueData(List<Issue> issues) {
        int p = 0, pr = 0, r = 0;
        Map<String, Integer> categoryMap = new HashMap<>();

        for (Issue issue : issues) {
            // Status aggregation
            String status = issue.getStatus();
            if (status != null) {
                if (status.equalsIgnoreCase("Pending")) p++;
                else if (status.equalsIgnoreCase("Processing")) pr++;
                else if (status.equalsIgnoreCase("Resolved")) r++;
            }

            // Category aggregation
            String category = issue.getCategory();
            if (category == null || category.isEmpty()) category = "Other";
            categoryMap.put(category, categoryMap.getOrDefault(category, 0) + 1);
        }

        pendingCount.setText(String.valueOf(p));
        processingCount.setText(String.valueOf(pr));
        resolvedCount.setText(String.valueOf(r));

        updatePieChart(p, pr, r);
        updateBarChart(categoryMap);
    }

    private void updatePieChart(int pending, int processing, int resolved) {
        ArrayList<PieEntry> entries = new ArrayList<>();
        ArrayList<Integer> colors = new ArrayList<>();

        // Add entries and colors in a specific order to match user request
        if (pending > 0) {
            entries.add(new PieEntry(pending, "Pending"));
            colors.add(Color.parseColor("#F44336")); // Red
        }
        if (processing > 0) {
            entries.add(new PieEntry(processing, "Processing"));
            colors.add(Color.parseColor("#FF9800")); // Orange
        }
        if (resolved > 0) {
            entries.add(new PieEntry(resolved, "Resolved"));
            colors.add(Color.parseColor("#4CAF50")); // Green
        }

        PieDataSet dataSet = new PieDataSet(entries, "");
        dataSet.setSliceSpace(3f);
        dataSet.setSelectionShift(5f);
        dataSet.setColors(colors);

        PieData data = new PieData(dataSet);
        data.setValueTextSize(14f);
        data.setValueTextColor(Color.WHITE);
        
        statusPieChart.setData(data);
        statusPieChart.animateY(1000);
        statusPieChart.invalidate();
    }

    private void updateBarChart(Map<String, Integer> categoryMap) {
        ArrayList<BarEntry> entries = new ArrayList<>();
        final ArrayList<String> labels = new ArrayList<>();
        
        int index = 0;
        for (Map.Entry<String, Integer> entry : categoryMap.entrySet()) {
            entries.add(new BarEntry(index, entry.getValue()));
            labels.add(entry.getKey());
            index++;
        }

        BarDataSet dataSet = new BarDataSet(entries, "Complaints Category");
        
        // Define light colors for bar chart (excluding red, orange, and green)
        int[] otherLightColors = new int[] {
            Color.parseColor("#90CAF9"), // Light Blue
            Color.parseColor("#CE93D8"), // Light Purple
            Color.parseColor("#80CBC4"), // Light Teal
            Color.parseColor("#9FA8DA"), // Light Indigo
            Color.parseColor("#F48FB1"), // Light Pink
            Color.parseColor("#80DEEA"), // Light Cyan
            Color.parseColor("#FFF59D")  // Light Yellow
        };
        
        dataSet.setColors(otherLightColors);
        dataSet.setValueTextSize(12f);

        BarData data = new BarData(dataSet);
        categoryBarChart.setData(data);
        
        categoryBarChart.getXAxis().setValueFormatter(new IndexAxisValueFormatter(labels));
        categoryBarChart.getXAxis().setLabelCount(labels.size());
        
        categoryBarChart.animateY(1000);
        categoryBarChart.invalidate();
    }
}
