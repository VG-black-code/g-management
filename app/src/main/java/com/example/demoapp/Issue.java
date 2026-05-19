package com.example.demoapp;

import com.google.gson.annotations.SerializedName;

public class Issue {
    @SerializedName("id")
    private Long id;

    @SerializedName("user_id")
    private String userId;

    @SerializedName("user_name")
    private String userName;

    @SerializedName("title")
    private String title;

    @SerializedName("category")
    private String category;

    @SerializedName("problem_type")
    private String problemType;

    @SerializedName("description")
    private String description;

    @SerializedName("location")
    private String location;

    @SerializedName("photo_url")
    private String photoUrl;

    @SerializedName("status")
    private String status;

    @SerializedName("created_at")
    private String createdAt;

    @SerializedName("processing_at")
    private String processingAt;

    @SerializedName("resolved_at")
    private String resolvedAt;

    public Issue() {}

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getUserId() { return userId; }
    public void setUserId(String userId) { this.userId = userId; }

    public String getUserName() { return userName; }
    public void setUserName(String userName) { this.userName = userName; }

    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }

    public String getCategory() { return category; }
    public void setCategory(String category) { this.category = category; }

    public String getProblemType() { return problemType; }
    public void setProblemType(String problemType) { this.problemType = problemType; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    public String getLocation() { return location; }
    public void setLocation(String location) { this.location = location; }

    public String getPhotoUrl() { return photoUrl; }
    public void setPhotoUrl(String photoUrl) { this.photoUrl = photoUrl; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public String getCreatedAt() { return createdAt; }
    public void setCreatedAt(String createdAt) { this.createdAt = createdAt; }

    public String getProcessingAt() { return processingAt; }
    public void setProcessingAt(String processingAt) { this.processingAt = processingAt; }

    public String getResolvedAt() { return resolvedAt; }
    public void setResolvedAt(String resolvedAt) { this.resolvedAt = resolvedAt; }
}
