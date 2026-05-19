package com.example.demoapp;

import android.content.Context;
import android.content.Intent;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TextView;
import androidx.annotation.NonNull;
import androidx.constraintlayout.widget.ConstraintLayout;
import androidx.recyclerview.widget.RecyclerView;
import com.bumptech.glide.Glide;
import com.google.gson.Gson;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.List;
import java.util.Locale;
import java.util.TimeZone;
import java.util.concurrent.TimeUnit;

public class RecentHistoryAdapter extends RecyclerView.Adapter<RecentHistoryAdapter.ViewHolder> {

    private List<Issue> issues;
    private Context context;

    public RecentHistoryAdapter(Context context, List<Issue> issues) {
        this.context = context;
        this.issues = issues;
    }

    @NonNull
    @Override
    public ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(context).inflate(R.layout.item_recent_history, parent, false);
        return new ViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull ViewHolder holder, int position) {
        Issue issue = issues.get(position);

        holder.title.setText(issue.getProblemType());
        holder.location.setText("Location: " + issue.getLocation());
        holder.time.setText(getRelativeTime(issue.getCreatedAt()));

        if (issue.getPhotoUrl() != null && !issue.getPhotoUrl().isEmpty()) {
            Glide.with(context).load(issue.getPhotoUrl()).into(holder.image);
        } else {
            holder.image.setImageResource(android.R.drawable.ic_menu_gallery);
        }

        float progress = 0.1f;
        if (issue.getStatus().equalsIgnoreCase("Processing")) progress = 0.5f;
        else if (issue.getStatus().equalsIgnoreCase("Resolved")) progress = 1.0f;

        ConstraintLayout.LayoutParams params = (ConstraintLayout.LayoutParams) holder.progressFill.getLayoutParams();
        params.matchConstraintPercentWidth = progress;
        holder.progressFill.setLayoutParams(params);

        holder.itemView.setOnClickListener(v -> {
            Intent intent = new Intent(context, IssueDetailActivity.class);
            intent.putExtra("issue_data", new Gson().toJson(issue));
            context.startActivity(intent);
        });
    }

    @Override
    public int getItemCount() {
        return issues.size();
    }

    public void updateData(List<Issue> newIssues) {
        this.issues = newIssues;
        notifyDataSetChanged();
    }

    private String getRelativeTime(String isoString) {
        if (isoString == null || isoString.isEmpty()) return "just now";
        try {
            String cleanIso = isoString;
            if (cleanIso.endsWith("Z")) cleanIso = cleanIso.substring(0, cleanIso.length() - 1);
            String pattern = cleanIso.contains(".") ? "yyyy-MM-dd'T'HH:mm:ss.SSS" : "yyyy-MM-dd'T'HH:mm:ss";
            
            SimpleDateFormat inputFormat = new SimpleDateFormat(pattern, Locale.getDefault());
            inputFormat.setTimeZone(TimeZone.getTimeZone("UTC"));
            Date date = inputFormat.parse(cleanIso);
            
            long diff = System.currentTimeMillis() - date.getTime();
            long hours = TimeUnit.MILLISECONDS.toHours(diff);
            if (hours < 1) return "just now";
            if (hours < 24) return hours + " hrs ago";
            return TimeUnit.MILLISECONDS.toDays(diff) + " days ago";
        } catch (Exception e) {
            return "recently";
        }
    }

    public static class ViewHolder extends RecyclerView.ViewHolder {
        ImageView image;
        TextView title, location, time;
        View progressFill;

        public ViewHolder(@NonNull View itemView) {
            super(itemView);
            image = itemView.findViewById(R.id.historyImage);
            title = itemView.findViewById(R.id.historyTitle);
            location = itemView.findViewById(R.id.historyLocation);
            time = itemView.findViewById(R.id.historyTime);
            progressFill = itemView.findViewById(R.id.progressLineFill);
        }
    }
}
