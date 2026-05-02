package com.example.demoapp;

import java.util.List;
import java.util.Map;
import okhttp3.RequestBody;
import okhttp3.ResponseBody;
import retrofit2.Call;
import retrofit2.http.Body;
import retrofit2.http.GET;
import retrofit2.http.Header;
import retrofit2.http.Headers;
import retrofit2.http.PATCH;
import retrofit2.http.POST;
import retrofit2.http.PUT;
import retrofit2.http.Path;
import retrofit2.http.Query;
import retrofit2.http.QueryMap;

public interface SupabaseApi {
    @Headers({"Content-Type: application/json", "Prefer: return=minimal"})
    @POST("rest/v1/issues")
    Call<Void> insertIssue(
        @Header("apikey") String apiKey,
        @Header("Authorization") String authToken,
        @Body Issue issue
    );

    @POST("storage/v1/object/{bucket}/{path}")
    Call<ResponseBody> uploadImage(
        @Header("apikey") String apiKey,
        @Header("Authorization") String authToken,
        @Header("Content-Type") String contentType,
        @Header("x-upsert") String upsert,
        @Path("bucket") String bucket,
        @Path("path") String path,
        @Body RequestBody file
    );

    @GET("rest/v1/issues")
    Call<List<Issue>> getIssues(
        @Header("apikey") String apiKey,
        @Header("Authorization") String authToken,
        @QueryMap Map<String, String> filters
    );

    @Headers({"Content-Type: application/json", "Prefer: return=minimal"})
    @PATCH("rest/v1/issues")
    Call<Void> updateIssue(
        @Header("apikey") String apiKey,
        @Header("Authorization") String authToken,
        @QueryMap Map<String, String> queryFilters,
        @Body Map<String, Object> updateData
    );

    @Headers({"Content-Type: application/json"})
    @POST("rest/v1/notifications")
    Call<Void> sendNotification(
        @Header("apikey") String apiKey,
        @Header("Authorization") String authToken,
        @Body Notification notification
    );

    @GET("rest/v1/notifications")
    Call<List<Notification>> getNotifications(
        @Header("apikey") String apiKey,
        @Header("Authorization") String authToken,
        @QueryMap Map<String, String> filters
    );

    @Headers({"Content-Type: application/json", "Prefer: return=minimal"})
    @PATCH("rest/v1/notifications")
    Call<Void> updateNotification(
        @Header("apikey") String apiKey,
        @Header("Authorization") String authToken,
        @QueryMap Map<String, String> queryFilters,
        @Body Map<String, Object> updateData
    );

    @POST("auth/v1/token?grant_type=password")
    Call<ResponseBody> login(
        @Header("apikey") String apiKey,
        @Header("Authorization") String authToken,
        @Body Map<String, String> body
    );

    @POST("auth/v1/recover")
    Call<Void> sendResetOtp(
        @Header("apikey") String apiKey,
        @Header("Authorization") String authToken,
        @Body Map<String, String> body
    );

    @POST("auth/v1/otp")
    Call<Void> sendOtp(
        @Header("apikey") String apiKey,
        @Header("Authorization") String authToken,
        @Body Map<String, Object> body
    );

    @POST("auth/v1/verify")
    Call<ResponseBody> verifyOtp(
        @Header("apikey") String apiKey,
        @Header("Authorization") String authToken,
        @Body Map<String, String> body
    );

    @PUT("auth/v1/user")
    Call<ResponseBody> updateUserAuth(
        @Header("apikey") String apiKey,
        @Header("Authorization") String authToken,
        @Body Map<String, Object> body
    );

    @GET("rest/v1/profiles")
    Call<List<Map<String, Object>>> getProfiles(
        @Header("apikey") String apiKey,
        @Header("Authorization") String authToken,
        @QueryMap Map<String, String> filters
    );

    @GET("rest/v1/admins")
    Call<List<Map<String, Object>>> getAdmins(
        @Header("apikey") String apiKey,
        @Header("Authorization") String authToken,
        @QueryMap Map<String, String> filters
    );

    @GET("rest/v1/profiles")
    Call<List<Map<String, Object>>> getProfileByMobile(
        @Header("apikey") String apiKey,
        @Header("Authorization") String authToken,
        @Query("mobile_number") String mobile
    );

    @GET("rest/v1/profiles")
    Call<List<Map<String, Object>>> getProfileByStudentId(
        @Header("apikey") String apiKey,
        @Header("Authorization") String authToken,
        @Query("student_id") String studentId
    );

    @Headers({"Content-Type: application/json", "Prefer: return=minimal"})
    @POST("rest/v1/profiles")
    Call<Void> createProfile(
        @Header("apikey") String apiKey,
        @Header("Authorization") String authToken,
        @Body Map<String, Object> profile
    );

    @Headers({"Content-Type: application/json", "Prefer: return=minimal"})
    @PATCH("rest/v1/profiles")
    Call<Void> updateProfile(
        @Header("apikey") String apiKey,
        @Header("Authorization") String authToken,
        @QueryMap Map<String, String> queryFilters,
        @Body Map<String, Object> updateData
    );

    @Headers({"Content-Type: application/json", "Prefer: return=minimal"})
    @PATCH("rest/v1/admins")
    Call<Void> updateAdminProfile(
        @Header("apikey") String apiKey,
        @Header("Authorization") String authToken,
        @QueryMap Map<String, String> queryFilters,
        @Body Map<String, Object> updateData
    );

    @PUT("auth/v1/user")
    Call<Void> updatePassword(
        @Header("apikey") String apiKey,
        @Header("Authorization") String authToken,
        @Body Map<String, String> body
    );
}
