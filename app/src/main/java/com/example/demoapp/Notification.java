package com.example.demoapp;

import com.google.gson.annotations.SerializedName;

public class Notification {
    @SerializedName("id")
    private Integer id;

    @SerializedName("user_name")
    private String userName;

    @SerializedName("title")
    private String title;

    @SerializedName("message")
    private String message;

    @SerializedName("is_read")
    private boolean isRead;

    @SerializedName("created_at")
    private String createdAt;

    @SerializedName("issue_id")
    private Long issueId;

    public Notification() {}

    public Notification(String userName, String title, String message) {
        this.userName = userName;
        this.title = title;
        this.message = message;
        this.isRead = false;
    }

    public Notification(String userName, String title, String message, Long issueId) {
        this.userName = userName;
        this.title = title;
        this.message = message;
        this.issueId = issueId;
        this.isRead = false;
    }

    public Integer getId() { return id; }
    public void setId(Integer id) { this.id = id; }

    public String getUserName() { return userName; }
    public void setUserName(String userName) { this.userName = userName; }

    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }

    public String getMessage() { return message; }
    public void setMessage(String message) { this.message = message; }

    public boolean isRead() { return isRead; }
    public void setRead(boolean read) { isRead = read; }

    public String getCreatedAt() { return createdAt; }
    public void setCreatedAt(String createdAt) { this.createdAt = createdAt; }

    public Long getIssueId() { return issueId; }
    public void setIssueId(Long issueId) { this.issueId = issueId; }
}
