package com.example.demoapp;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.util.Base64;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TextView;
import android.widget.Toast;
import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;
import com.google.android.material.button.MaterialButton;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class UsersAdapter extends RecyclerView.Adapter<UsersAdapter.UserViewHolder> {

    private List<Map<String, Object>> users;
    private OnUserClickListener listener;
    private Context context;

    public interface OnUserClickListener {
        void onUserClick(Map<String, Object> user);
    }

    public UsersAdapter(List<Map<String, Object>> users, OnUserClickListener listener) {
        this.users = users;
        this.listener = listener;
    }

    @NonNull
    @Override
    public UserViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        this.context = parent.getContext();
        View view = LayoutInflater.from(context).inflate(R.layout.item_user_card, parent, false);
        return new UserViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull UserViewHolder holder, int position) {
        Map<String, Object> user = users.get(position);
        
        String userId = String.valueOf(user.get("id"));
        String name = String.valueOf(user.getOrDefault("full_name", user.getOrDefault("name", "Unknown")));
        // Check if role is from user_role (profiles) or it's an admin from admins table
        String role = String.valueOf(user.getOrDefault("user_role", user.getOrDefault("role", "Admin")));
        
        String displayId = "N/A";
        if (user.containsKey("student_id") && user.get("student_id") != null) displayId = String.valueOf(user.get("student_id"));
        else if (user.containsKey("admin_id") && user.get("admin_id") != null) displayId = String.valueOf(user.get("admin_id"));

        String encodedImage = String.valueOf(user.getOrDefault("profile_image", ""));

        holder.tvName.setText(name);
        holder.tvRole.setText(role);
        holder.tvId.setText("ID: " + displayId);

        if (encodedImage != null && !encodedImage.isEmpty() && !encodedImage.equals("null")) {
            try {
                byte[] decodedString = Base64.decode(encodedImage, Base64.DEFAULT);
                Bitmap decodedByte = BitmapFactory.decodeByteArray(decodedString, 0, decodedString.length);
                holder.ivProfile.setImageBitmap(decodedByte);
            } catch (Exception e) {
                holder.ivProfile.setImageResource(R.mipmap.ic_launcher_round);
            }
        } else {
            holder.ivProfile.setImageResource(R.mipmap.ic_launcher_round);
        }

        // Approval Logic: Admins in the 'admins' table or identified as Admin role
        boolean isApproved = true;
        Object approvedObj = user.get("is_approved");
        if (approvedObj != null) {
            isApproved = Boolean.parseBoolean(String.valueOf(approvedObj));
        }

        if ("Admin".equalsIgnoreCase(role) && !isApproved) {
            holder.tvStatus.setVisibility(View.VISIBLE);
            holder.tvStatus.setText("PENDING");
            holder.btnApprove.setVisibility(View.VISIBLE);
            holder.btnApprove.setOnClickListener(v -> approveAdmin(userId, position));
        } else {
            holder.tvStatus.setVisibility(View.GONE);
            holder.btnApprove.setVisibility(View.GONE);
        }

        holder.itemView.setOnClickListener(v -> listener.onUserClick(user));
    }

    private void approveAdmin(String userId, int position) {
        Map<String, Object> updates = new HashMap<>();
        updates.put("is_approved", true);

        Map<String, String> query = new HashMap<>();
        query.put("id", "eq." + userId);

        String token = context.getSharedPreferences("UserPrefs", Context.MODE_PRIVATE).getString("access_token", SupabaseConfig.API_KEY);
        String authHeader = "Bearer " + token;

        // Use updateAdminProfile for the 'admins' table
        SupabaseConfig.getApi().updateAdminProfile(SupabaseConfig.API_KEY, authHeader, query, updates)
                .enqueue(new Callback<Void>() {
                    @Override
                    public void onResponse(Call<Void> call, Response<Void> response) {
                        if (response.isSuccessful()) {
                            Toast.makeText(context, "Admin Approved!", Toast.LENGTH_SHORT).show();
                            users.get(position).put("is_approved", true);
                            notifyItemChanged(position);
                        } else {
                            // Fallback to updateProfile if it's not in the admins table (unlikely with current setup)
                            SupabaseConfig.getApi().updateProfile(SupabaseConfig.API_KEY, authHeader, query, updates)
                                    .enqueue(new Callback<Void>() {
                                        @Override
                                        public void onResponse(Call<Void> call, Response<Void> response) {
                                            if (response.isSuccessful()) {
                                                users.get(position).put("is_approved", true);
                                                notifyItemChanged(position);
                                            }
                                        }
                                        @Override public void onFailure(Call<Void> call, Throwable t) {}
                                    });
                        }
                    }
                    @Override
                    public void onFailure(Call<Void> call, Throwable t) {
                        Toast.makeText(context, "Network Error", Toast.LENGTH_SHORT).show();
                    }
                });
    }

    @Override
    public int getItemCount() {
        return users.size();
    }

    public void updateList(List<Map<String, Object>> newList) {
        this.users = newList;
        notifyDataSetChanged();
    }

    static class UserViewHolder extends RecyclerView.ViewHolder {
        ImageView ivProfile;
        TextView tvName, tvId, tvRole, tvStatus;
        MaterialButton btnApprove;

        public UserViewHolder(@NonNull View itemView) {
            super(itemView);
            ivProfile = itemView.findViewById(R.id.userCardImage);
            tvName = itemView.findViewById(R.id.userCardName);
            tvId = itemView.findViewById(R.id.userCardId);
            tvRole = itemView.findViewById(R.id.userCardRole);
            tvStatus = itemView.findViewById(R.id.userApprovalStatus);
            btnApprove = itemView.findViewById(R.id.btnApproveUser);
        }
    }
}