package com.example.demoapp;

import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.text.Editable;
import android.text.TextWatcher;
import android.util.Log;
import android.view.View;
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.ProgressBar;
import android.widget.TextView;
import android.widget.Toast;
import androidx.appcompat.app.AppCompatActivity;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;
import androidx.swiperefreshlayout.widget.SwipeRefreshLayout;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;
import retrofit2.Retrofit;
import retrofit2.converter.gson.GsonConverterFactory;

public class UsersListActivity extends AppCompatActivity {

    private static final String TAG = "UsersListActivity";
    private RecyclerView rvUsers;
    private UsersAdapter adapter;
    private SwipeRefreshLayout swipeRefresh;
    private ProgressBar loader;
    private TextView noUsersText;
    private EditText searchInput;
    private ImageView sortBtn;
    private List<Map<String, Object>> allUsers = new ArrayList<>();
    private boolean isSortNewest = true;
    private SharedPreferences userPrefs;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        ThemeHelper.applyTheme(this);
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_users_list);

        userPrefs = getSharedPreferences("UserPrefs", MODE_PRIVATE);
        rvUsers = findViewById(R.id.rvUsers);
        swipeRefresh = findViewById(R.id.swipeRefreshUsers);
        loader = findViewById(R.id.loader);
        noUsersText = findViewById(R.id.noUsersText);
        searchInput = findViewById(R.id.searchUsers);
        sortBtn = findViewById(R.id.sortBtn);

        findViewById(R.id.backBtn).setOnClickListener(v -> finish());

        rvUsers.setLayoutManager(new LinearLayoutManager(this));
        adapter = new UsersAdapter(new ArrayList<>(), this::showUserDetails);
        rvUsers.setAdapter(adapter);

        swipeRefresh.setOnRefreshListener(this::fetchUsers);
        
        if (sortBtn != null) {
            sortBtn.setOnClickListener(v -> toggleSort());
        }

        setupSearch();
        fetchUsers();
    }

    private void setupSearch() {
        searchInput.addTextChangedListener(new TextWatcher() {
            @Override
            public void beforeTextChanged(CharSequence s, int start, int count, int after) {}

            @Override
            public void onTextChanged(CharSequence s, int start, int before, int count) {
                filterUsers(s.toString());
            }

            @Override
            public void afterTextChanged(Editable s) {}
        });
    }

    private void toggleSort() {
        isSortNewest = !isSortNewest;
        Toast.makeText(this, isSortNewest ? "Sorting by Latest" : "Sorting by Oldest", Toast.LENGTH_SHORT).show();
        fetchUsers();
    }

    private void filterUsers(String query) {
        if (query.isEmpty()) {
            adapter.updateList(allUsers);
            noUsersText.setVisibility(allUsers.isEmpty() ? View.VISIBLE : View.GONE);
            return;
        }

        List<Map<String, Object>> filtered = new ArrayList<>();
        for (Map<String, Object> user : allUsers) {
            String name = String.valueOf(user.getOrDefault("full_name", user.getOrDefault("name", ""))).toLowerCase();
            String studentId = String.valueOf(user.getOrDefault("student_id", "")).toLowerCase();
            String adminId = String.valueOf(user.getOrDefault("admin_id", "")).toLowerCase();
            
            if (name.contains(query.toLowerCase()) || studentId.contains(query.toLowerCase()) || adminId.contains(query.toLowerCase())) {
                filtered.add(user);
            }
        }
        adapter.updateList(filtered);
        noUsersText.setVisibility(filtered.isEmpty() ? View.VISIBLE : View.GONE);
    }

    private void fetchUsers() {
        if (!swipeRefresh.isRefreshing()) loader.setVisibility(View.VISIBLE);
        noUsersText.setVisibility(View.GONE);

        Retrofit retrofit = new Retrofit.Builder()
                .baseUrl(SupabaseConfig.URL)
                .addConverterFactory(GsonConverterFactory.create())
                .build();

        SupabaseApi api = retrofit.create(SupabaseApi.class);
        
        String token = userPrefs.getString("access_token", SupabaseConfig.API_KEY);
        String authHeader = token.startsWith("Bearer ") ? token : "Bearer " + token;

        Map<String, String> filters = new HashMap<>();
        // Fetch all profiles to allow main admin to see both students and pending admins
        String order = isSortNewest ? "created_at.desc" : "created_at.asc";
        filters.put("order", order);

        api.getProfiles(SupabaseConfig.API_KEY, authHeader, filters)
                .enqueue(new Callback<List<Map<String, Object>>>() {
                    @Override
                    public void onResponse(Call<List<Map<String, Object>>> call, Response<List<Map<String, Object>>> response) {
                        loader.setVisibility(View.GONE);
                        swipeRefresh.setRefreshing(false);
                        if (response.isSuccessful() && response.body() != null) {
                            allUsers = response.body();
                            adapter.updateList(allUsers);
                            noUsersText.setVisibility(allUsers.isEmpty() ? View.VISIBLE : View.GONE);
                            
                            String currentQuery = searchInput.getText().toString();
                            if (!currentQuery.isEmpty()) filterUsers(currentQuery);
                        } else {
                            Toast.makeText(UsersListActivity.this, "Access Denied or Server Error", Toast.LENGTH_SHORT).show();
                        }
                    }

                    @Override
                    public void onFailure(Call<List<Map<String, Object>>> call, Throwable t) {
                        loader.setVisibility(View.GONE);
                        swipeRefresh.setRefreshing(false);
                        Toast.makeText(UsersListActivity.this, "Network Error", Toast.LENGTH_SHORT).show();
                    }
                });
    }

    private void showUserDetails(Map<String, Object> user) {
        Intent intent = new Intent(this, UserDetailsActivity.class);
        for (Map.Entry<String, Object> entry : user.entrySet()) {
            if (entry.getValue() != null) {
                intent.putExtra(entry.getKey(), String.valueOf(entry.getValue()));
            }
        }
        intent.putExtra("is_view_only", true);
        startActivity(intent);
    }
}
