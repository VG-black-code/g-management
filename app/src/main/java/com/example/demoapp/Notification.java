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

    public Notification() {}

    public Notification(String userName, String title, String message) {
        this.userName = userName;
        this.title = title;
        this.message = message;
        this.isRead = false;
    }

    public Integer getId() { return id; }
    public String getUserName() { return userName; }
    public String getTitle() { return title; }
    public String getMessage() { return message; }
    public boolean isRead() { return isRead; }
    public String getCreatedAt() { return createdAt; }
}
