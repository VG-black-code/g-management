package com.example.demoapp;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TextView;
import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;
import com.google.android.material.button.MaterialButton;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.List;
import java.util.Locale;
import java.util.TimeZone;
import java.util.concurrent.TimeUnit;

public class NotificationAdapter extends RecyclerView.Adapter<NotificationAdapter.NotificationViewHolder> {

    private final List<Notification> notifications;
    private final OnNotificationClickListener listener;

    public interface OnNotificationClickListener {
        void onNotificationClick(Notification notification);
    }

    public NotificationAdapter(List<Notification> notifications, OnNotificationClickListener listener) {
        this.notifications = notifications;
        this.listener = listener;
    }

    @NonNull
    @Override
    public NotificationViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(parent.getContext()).inflate(R.layout.item_notification, parent, false);
        return new NotificationViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull NotificationViewHolder holder, int position) {
        Notification notification = notifications.get(position);
        holder.tvTitle.setText(notification.getTitle());
        holder.tvMessage.setText(notification.getMessage());
        holder.tvTime.setText(getRelativeTime(notification.getCreatedAt()));

        // Show/Hide Unread Dot
        holder.unreadDot.setVisibility(notification.isRead() ? View.GONE : View.VISIBLE);
        
        // Show Detail Button if linked to a complaint
        boolean hasIssue = notification.getIssueId() != null && notification.getIssueId() != 0;
        holder.btnDetails.setVisibility(hasIssue ? View.VISIBLE : View.GONE);

        // Click listeners
        View.OnClickListener clickListener = v -> listener.onNotificationClick(notification);
        holder.itemView.setOnClickListener(clickListener);
        holder.btnDetails.setOnClickListener(clickListener);
        
        // Change alpha for read notifications
        holder.itemView.setAlpha(notification.isRead() ? 0.7f : 1.0f);
    }

    private String getRelativeTime(String isoString) {
        if (isoString == null || isoString.isEmpty()) return "Just now";
        try {
            String cleanIso = isoString;
            if (cleanIso.endsWith("Z")) cleanIso = cleanIso.substring(0, cleanIso.length() - 1);
            String pattern = cleanIso.contains(".") ? "yyyy-MM-dd'T'HH:mm:ss.SSS" : "yyyy-MM-dd'T'HH:mm:ss";
            
            SimpleDateFormat inputFormat = new SimpleDateFormat(pattern, Locale.getDefault());
            inputFormat.setTimeZone(TimeZone.getTimeZone("UTC"));
            Date date = inputFormat.parse(cleanIso);
            
            long diff = System.currentTimeMillis() - date.getTime();
            long minutes = TimeUnit.MILLISECONDS.toMinutes(diff);
            long hours = TimeUnit.MILLISECONDS.toHours(diff);
            long days = TimeUnit.MILLISECONDS.toDays(diff);

            if (minutes < 1) return "Just now";
            if (minutes < 60) return minutes + " mins ago";
            if (hours < 24) return hours + " hrs ago";
            return days + " days ago";
        } catch (Exception e) {
            return "Recently";
        }
    }

    @Override
    public int getItemCount() {
        return notifications.size();
    }

    static class NotificationViewHolder extends RecyclerView.ViewHolder {
        TextView tvTitle, tvMessage, tvTime;
        View unreadDot;
        MaterialButton btnDetails;
        ImageView icon;

        public NotificationViewHolder(@NonNull View itemView) {
            super(itemView);
            tvTitle = itemView.findViewById(R.id.notifTitle);
            tvMessage = itemView.findViewById(R.id.notifMessage);
            tvTime = itemView.findViewById(R.id.notifTime);
            unreadDot = itemView.findViewById(R.id.unreadDot);
            btnDetails = itemView.findViewById(R.id.btnViewDetails);
            icon = itemView.findViewById(R.id.notifIcon);
        }
    }
}
