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
import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;
import java.util.List;
import java.util.Map;

public class UsersAdapter extends RecyclerView.Adapter<UsersAdapter.UserViewHolder> {

    private List<Map<String, Object>> users;
    private OnUserClickListener listener;

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
        View view = LayoutInflater.from(parent.getContext()).inflate(R.layout.item_user_card, parent, false);
        return new UserViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull UserViewHolder holder, int position) {
        Map<String, Object> user = users.get(position);
        
        String name = String.valueOf(user.getOrDefault("full_name", user.getOrDefault("name", "Unknown")));
        String role = String.valueOf(user.getOrDefault("user_role", user.getOrDefault("role", "User")));
        
        String displayId = "N/A";
        if (user.containsKey("student_id") && user.get("student_id") != null) displayId = String.valueOf(user.get("student_id"));
        else if (user.containsKey("faculty_id") && user.get("faculty_id") != null) displayId = String.valueOf(user.get("faculty_id"));
        else if (user.containsKey("worker_id") && user.get("worker_id") != null) displayId = String.valueOf(user.get("worker_id"));
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

        holder.itemView.setOnClickListener(v -> listener.onUserClick(user));
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
        TextView tvName, tvId, tvRole;

        public UserViewHolder(@NonNull View itemView) {
            super(itemView);
            ivProfile = itemView.findViewById(R.id.userCardImage);
            tvName = itemView.findViewById(R.id.userCardName);
            tvId = itemView.findViewById(R.id.userCardId);
            tvRole = itemView.findViewById(R.id.userCardRole);
        }
    }
}