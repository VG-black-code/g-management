package com.example.demoapp;

import android.content.SharedPreferences;
import android.graphics.Color;
import android.os.Bundle;
import android.widget.ImageView;
import android.widget.TextView;
import android.widget.Toast;

import androidx.appcompat.app.AppCompatActivity;

import com.github.mikephil.charting.charts.BarChart;
import com.github.mikephil.charting.charts.PieChart;
import com.github.mikephil.charting.components.Legend;
import com.github.mikephil.charting.components.XAxis;
import com.github.mikephil.charting.data.BarData;
import com.github.mikephil.charting.data.BarDataSet;
import com.github.mikephil.charting.data.BarEntry;
import com.github.mikephil.charting.data.Entry;
import com.github.mikephil.charting.data.PieData;
import com.github.mikephil.charting.data.PieDataSet;
import com.github.mikephil.charting.data.PieEntry;
import com.github.mikephil.charting.formatter.IndexAxisValueFormatter;
import com.github.mikephil.charting.highlight.Highlight;
import com.github.mikephil.charting.listener.OnChartValueSelectedListener;

import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Date;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.TreeMap;

import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;
import retrofit2.Retrofit;
import retrofit2.converter.gson.GsonConverterFactory;

public class ComplaintAnalyticsActivity extends AppCompatActivity {

    private PieChart statusPieChart;
    private BarChart categoryBarChart, trendBarChart;
    private TextView btnDay, btnWeek, btnMonth;
    private TextView statusTitle, categoryTitle;
    private String currentTrendType = "Day";
    private String selectedPeriodLabel = null;
    private List<String> trendLabels = new ArrayList<>();
    
    private SharedPreferences userPrefs;
    private List<Issue> allIssues = new ArrayList<>();

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        ThemeHelper.applyTheme(this);
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_complaint_analytics);

        userPrefs = getSharedPreferences("UserPrefs", MODE_PRIVATE);

        statusPieChart = findViewById(R.id.statusPieChart);
        categoryBarChart = findViewById(R.id.categoryBarChart);
        trendBarChart = findViewById(R.id.trendBarChart);
        
        btnDay = findViewById(R.id.btnDay);
        btnWeek = findViewById(R.id.btnWeek);
        btnMonth = findViewById(R.id.btnMonth);

        statusTitle = findViewById(R.id.statusDistributionTitle);
        categoryTitle = findViewById(R.id.categoryPredictionTitle);
        
        ImageView backBtn = findViewById(R.id.backBtn);
        backBtn.setOnClickListener(v -> finish());

        setupCharts();
        setupClickListeners();
        fetchAllComplaints();
    }

    private void setupCharts() {
        // Pie Chart
        statusPieChart.setUsePercentValues(true);
        statusPieChart.getDescription().setEnabled(false);
        statusPieChart.setDrawHoleEnabled(true);
        statusPieChart.setHoleColor(Color.TRANSPARENT);
        statusPieChart.setEntryLabelColor(Color.BLACK);
        statusPieChart.setEntryLabelTextSize(12f);

        // Category Bar Chart
        categoryBarChart.getDescription().setEnabled(false);
        categoryBarChart.setDrawGridBackground(false);
        categoryBarChart.getXAxis().setPosition(XAxis.XAxisPosition.BOTTOM);
        categoryBarChart.getXAxis().setDrawGridLines(false);
        categoryBarChart.getXAxis().setGranularity(1f);
        categoryBarChart.getXAxis().setLabelRotationAngle(-45);
        categoryBarChart.getAxisRight().setEnabled(false);
        categoryBarChart.getAxisLeft().setDrawGridLines(false);
        categoryBarChart.getAxisLeft().setGranularity(1f);
        categoryBarChart.getAxisLeft().setAxisMinimum(0f);
        categoryBarChart.setExtraOffsets(0, 0, 0, 20); // Extra bottom offset for labels
        
        // Trend Bar Chart
        trendBarChart.getDescription().setEnabled(false);
        trendBarChart.setDrawGridBackground(false);
        trendBarChart.getAxisRight().setEnabled(false);
        trendBarChart.getAxisLeft().setDrawGridLines(false);
        trendBarChart.getAxisLeft().setGranularity(1f);
        trendBarChart.getAxisLeft().setAxisMinimum(0f);
        
        XAxis xAxis = trendBarChart.getXAxis();
        xAxis.setPosition(XAxis.XAxisPosition.BOTTOM);
        xAxis.setDrawGridLines(false);
        xAxis.setGranularity(1f);

        trendBarChart.setOnChartValueSelectedListener(new OnChartValueSelectedListener() {
            @Override
            public void onValueSelected(Entry e, Highlight h) {
                int index = (int) e.getX();
                if (index >= 0 && index < trendLabels.size()) {
                    selectedPeriodLabel = trendLabels.get(index);
                    updateTitlesWithSelection();
                    processData();
                }
            }

            @Override
            public void onNothingSelected() {
                selectedPeriodLabel = null;
                updateTitlesWithSelection();
                processData();
            }
        });
    }

    private void updateTitlesWithSelection() {
        String baseSuffix = currentTrendType.equals("Day") ? " (Last 7 Days)" : 
                           currentTrendType.equals("Week") ? " (Last 4 Weeks)" : " (Last 6 Months)";
        
        String selectionSuffix = (selectedPeriodLabel != null) ? " - " + selectedPeriodLabel : baseSuffix;
        
        if (statusTitle != null) statusTitle.setText("Status Distribution " + selectionSuffix);
        if (categoryTitle != null) categoryTitle.setText("Category Distribution " + selectionSuffix);
    }

    private void setupClickListeners() {
        if (btnDay != null) btnDay.setOnClickListener(v -> updateTrendType("Day"));
        if (btnWeek != null) btnWeek.setOnClickListener(v -> updateTrendType("Week"));
        if (btnMonth != null) btnMonth.setOnClickListener(v -> updateTrendType("Month"));
    }

    private void updateTrendType(String type) {
        currentTrendType = type;
        selectedPeriodLabel = null; // Reset selection when period changes
        trendBarChart.highlightValues(null); // Clear highlights
        
        btnDay.setTextColor(Color.parseColor("#888888"));
        btnWeek.setTextColor(Color.parseColor("#888888"));
        btnMonth.setTextColor(Color.parseColor("#888888"));
        btnDay.setTypeface(null, android.graphics.Typeface.NORMAL);
        btnWeek.setTypeface(null, android.graphics.Typeface.NORMAL);
        btnMonth.setTypeface(null, android.graphics.Typeface.NORMAL);

        int primary = Color.parseColor("#1976D2");
        if (type.equals("Day")) { btnDay.setTextColor(primary); btnDay.setTypeface(null, android.graphics.Typeface.BOLD); }
        else if (type.equals("Week")) { btnWeek.setTextColor(primary); btnWeek.setTypeface(null, android.graphics.Typeface.BOLD); }
        else if (type.equals("Month")) { btnMonth.setTextColor(primary); btnMonth.setTypeface(null, android.graphics.Typeface.BOLD); }

        updateTitlesWithSelection();
        processTrendData();
        processData();
    }

    private void fetchAllComplaints() {
        Retrofit retrofit = new Retrofit.Builder()
                .baseUrl(SupabaseConfig.URL)
                .addConverterFactory(GsonConverterFactory.create())
                .build();

        SupabaseApi api = retrofit.create(SupabaseApi.class);
        String token = userPrefs.getString("access_token", SupabaseConfig.API_KEY);
        String authHeader = token.startsWith("Bearer ") ? token : "Bearer " + token;

        api.getIssues(SupabaseConfig.API_KEY, authHeader, new HashMap<>())
                .enqueue(new Callback<List<Issue>>() {
                    @Override
                    public void onResponse(Call<List<Issue>> call, Response<List<Issue>> response) {
                        if (response.isSuccessful() && response.body() != null) {
                            allIssues = response.body();
                            updateTrendType(currentTrendType);
                        }
                    }

                    @Override
                    public void onFailure(Call<List<Issue>> call, Throwable t) {
                        Toast.makeText(ComplaintAnalyticsActivity.this, "Failed to load analytics", Toast.LENGTH_SHORT).show();
                    }
                });
    }

    private List<Issue> getFilteredIssues() {
        List<Issue> filtered = new ArrayList<>();
        SimpleDateFormat inputFmt = new SimpleDateFormat("yyyy-MM-dd", Locale.getDefault());
        
        // Formatter for matching the selected label
        SimpleDateFormat matchFmt;
        if (currentTrendType.equals("Day")) matchFmt = new SimpleDateFormat("dd MMM", Locale.getDefault());
        else if (currentTrendType.equals("Week")) matchFmt = new SimpleDateFormat("'W'w", Locale.getDefault());
        else matchFmt = new SimpleDateFormat("MMM", Locale.getDefault());

        if (selectedPeriodLabel != null) {
            // Filter by specific day/week/month
            for (Issue issue : allIssues) {
                String createdAt = issue.getCreatedAt();
                if (createdAt != null && createdAt.length() >= 10) {
                    try {
                        Date issueDate = inputFmt.parse(createdAt.substring(0, 10));
                        if (issueDate != null && matchFmt.format(issueDate).equals(selectedPeriodLabel)) {
                            filtered.add(issue);
                        }
                    } catch (ParseException e) { e.printStackTrace(); }
                }
            }
        } else {
            // Filter by overall range (Last 7 days, etc.)
            Calendar startCal = Calendar.getInstance();
            startCal.set(Calendar.HOUR_OF_DAY, 0); startCal.set(Calendar.MINUTE, 0);
            startCal.set(Calendar.SECOND, 0); startCal.set(Calendar.MILLISECOND, 0);

            if (currentTrendType.equals("Day")) startCal.add(Calendar.DAY_OF_YEAR, -6);
            else if (currentTrendType.equals("Week")) startCal.add(Calendar.WEEK_OF_YEAR, -3);
            else startCal.add(Calendar.MONTH, -5);
            
            Date startDate = startCal.getTime();

            for (Issue issue : allIssues) {
                String createdAt = issue.getCreatedAt();
                if (createdAt != null && createdAt.length() >= 10) {
                    try {
                        Date issueDate = inputFmt.parse(createdAt.substring(0, 10));
                        if (issueDate != null && !issueDate.before(startDate)) {
                            filtered.add(issue);
                        }
                    } catch (ParseException e) { e.printStackTrace(); }
                }
            }
        }
        return filtered;
    }

    private void processData() {
        List<Issue> filteredIssues = getFilteredIssues();
        
        int pending = 0, processing = 0, resolved = 0;
        // Use a LinkedHashMap to preserve the order of specific categories
        Map<String, Integer> categoryMap = new LinkedHashMap<>();
        categoryMap.put("Hostel Complaints", 0);
        categoryMap.put("Campus Facilities", 0);
        categoryMap.put("Classroom Issues", 0);
        categoryMap.put("Academic Issues", 0);
        categoryMap.put("Lab / IT Issues", 0);

        for (Issue issue : filteredIssues) {
            String s = issue.getStatus();
            if (s != null) {
                if (s.equalsIgnoreCase("Pending")) pending++;
                else if (s.equalsIgnoreCase("Processing")) processing++;
                else if (s.equalsIgnoreCase("Resolved")) resolved++;
            }

            String cat = issue.getCategory();
            if (cat != null && !cat.isEmpty()) {
                // Normalize category name if needed
                String normalizedCat = cat;
                if (cat.contains("Hostel")) normalizedCat = "Hostel Complaints";
                else if (cat.contains("Campus") || cat.contains("Facilities")) normalizedCat = "Campus Facilities";
                else if (cat.contains("Classroom")) normalizedCat = "Classroom Issues";
                else if (cat.contains("Academic")) normalizedCat = "Academic Issues";
                else if (cat.contains("Lab") || cat.contains("IT")) normalizedCat = "Lab / IT Issues";

                if (categoryMap.containsKey(normalizedCat)) {
                    categoryMap.put(normalizedCat, categoryMap.get(normalizedCat) + 1);
                }
            }
        }

        updatePieChart(pending, processing, resolved);
        updateBarChart(categoryMap);
    }

    private void processTrendData() {
        if (allIssues == null || allIssues.isEmpty()) return;

        Map<String, Integer> counts = new TreeMap<>();
        SimpleDateFormat displayFmt;
        Calendar cal = Calendar.getInstance();
        Date today = cal.getTime();

        if (currentTrendType.equals("Day")) displayFmt = new SimpleDateFormat("dd MMM", Locale.getDefault());
        else if (currentTrendType.equals("Week")) displayFmt = new SimpleDateFormat("'W'w", Locale.getDefault());
        else displayFmt = new SimpleDateFormat("MMM", Locale.getDefault());

        // Pre-fill labels to ensure they appear in the trend
        trendLabels.clear();
        Map<String, Integer> orderedCounts = new LinkedHashMap<>();
        cal.setTime(today);
        
        int count = currentTrendType.equals("Day") ? 7 : currentTrendType.equals("Week") ? 4 : 6;
        List<String> labelsInOrder = new ArrayList<>();
        
        for (int i = count - 1; i >= 0; i--) {
            cal.setTime(today);
            if (currentTrendType.equals("Day")) cal.add(Calendar.DAY_OF_YEAR, -i);
            else if (currentTrendType.equals("Week")) cal.add(Calendar.WEEK_OF_YEAR, -i);
            else cal.add(Calendar.MONTH, -i);
            
            String label = displayFmt.format(cal.getTime());
            labelsInOrder.add(label);
            orderedCounts.put(label, 0);
        }
        trendLabels.addAll(labelsInOrder);

        SimpleDateFormat inputFmt = new SimpleDateFormat("yyyy-MM-dd", Locale.getDefault());
        for (Issue issue : allIssues) {
            String createdAt = issue.getCreatedAt();
            if (createdAt != null && createdAt.length() >= 10) {
                try {
                    Date date = inputFmt.parse(createdAt.substring(0, 10));
                    String key = displayFmt.format(date);
                    if (orderedCounts.containsKey(key)) {
                        orderedCounts.put(key, orderedCounts.get(key) + 1);
                    }
                } catch (ParseException e) { e.printStackTrace(); }
            }
        }

        List<BarEntry> entries = new ArrayList<>();
        int idx = 0;
        for (Map.Entry<String, Integer> entry : orderedCounts.entrySet()) {
            entries.add(new BarEntry(idx++, entry.getValue()));
        }

        BarDataSet dataSet = new BarDataSet(entries, "Complaints");
        dataSet.setColor(Color.parseColor("#90CAF9"));
        dataSet.setHighLightColor(Color.parseColor("#1976D2"));
        dataSet.setValueTextSize(10f);
        
        BarData data = new BarData(dataSet);
        trendBarChart.setData(data);
        trendBarChart.getXAxis().setValueFormatter(new IndexAxisValueFormatter(trendLabels));
        trendBarChart.getXAxis().setLabelCount(trendLabels.size());
        trendBarChart.animateY(800);
        trendBarChart.invalidate();
    }

    private void updatePieChart(int pending, int processing, int resolved) {
        ArrayList<PieEntry> entries = new ArrayList<>();
        ArrayList<Integer> colors = new ArrayList<>();

        if (pending > 0) { entries.add(new PieEntry(pending, "Pending")); colors.add(Color.parseColor("#E53935")); } // Vivid Red
        if (processing > 0) { entries.add(new PieEntry(processing, "Processing")); colors.add(Color.parseColor("#FB8C00")); } // Vivid Orange
        if (resolved > 0) { entries.add(new PieEntry(resolved, "Resolved")); colors.add(Color.parseColor("#43A047")); } // Vivid Green

        if (entries.isEmpty()) {
            statusPieChart.clear();
            statusPieChart.setNoDataText("No data for selection");
            statusPieChart.invalidate();
            return;
        }

        PieDataSet dataSet = new PieDataSet(entries, "");
        dataSet.setColors(colors);
        dataSet.setSliceSpace(3f);
        PieData data = new PieData(dataSet);
        data.setValueTextSize(14f);
        data.setValueTextColor(Color.WHITE);
        statusPieChart.setData(data);
        statusPieChart.invalidate();
    }

    private void updateBarChart(Map<String, Integer> categoryMap) {
        categoryBarChart.clear();
        
        ArrayList<BarEntry> entries = new ArrayList<>();
        ArrayList<String> labels = new ArrayList<>();
        ArrayList<Integer> colors = new ArrayList<>();
        
        int i = 0;
        for (Map.Entry<String, Integer> entry : categoryMap.entrySet()) {
            entries.add(new BarEntry(i++, entry.getValue()));
            labels.add(entry.getKey());
            
            // Re-assigning colors as requested: Hostel, Campus, Classroom
            if (entry.getKey().equals("Hostel Complaints")) colors.add(Color.parseColor("#F44336")); // Red
            else if (entry.getKey().equals("Campus Facilities")) colors.add(Color.parseColor("#4CAF50")); // Green
            else if (entry.getKey().equals("Classroom Issues")) colors.add(Color.parseColor("#2196F3")); // Blue
            else if (entry.getKey().equals("Academic Issues")) colors.add(Color.parseColor("#9C27B0")); // Purple
            else if (entry.getKey().equals("Lab / IT Issues")) colors.add(Color.parseColor("#FF9800")); // Orange
            else colors.add(Color.GRAY);
        }

        BarDataSet dataSet = new BarDataSet(entries, "Category Distribution");
        dataSet.setColors(colors);
        dataSet.setValueTextSize(12f);
        dataSet.setValueTextColor(Color.DKGRAY);

        BarData data = new BarData(dataSet);
        data.setBarWidth(0.7f); // Adjust bar width to prevent overlapping/overwriting appearance
        categoryBarChart.setData(data);
        
        XAxis xAxis = categoryBarChart.getXAxis();
        xAxis.setValueFormatter(new IndexAxisValueFormatter(labels));
        xAxis.setLabelCount(labels.size());
        xAxis.setGranularity(1f);
        xAxis.setCenterAxisLabels(false);
        
        categoryBarChart.setFitBars(true); // Fit bars correctly
        categoryBarChart.animateY(1000);
        categoryBarChart.invalidate();
    }
}
