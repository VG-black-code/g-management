package com.example.demoapp;

import okhttp3.OkHttpClient;
import okhttp3.logging.HttpLoggingInterceptor;
import retrofit2.Retrofit;
import retrofit2.converter.gson.GsonConverterFactory;
import java.util.concurrent.TimeUnit;

public class SupabaseConfig {
    // Project URL with trailing slash
    public static final String URL = "https://gsvfndubfgymmnuvusiw.supabase.co/";
    
    // The Anon Public Key
    public static final String API_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdzdmZuZHViZmd5bW1udXZ1c2l3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ5NTkxMjEsImV4cCI6MjA5MDUzNTEyMX0.5Ecx8NAfMSCtFhvJTpAEiZq97jVRVO10LSW0Lhjp6Qw";

    private static SupabaseApi apiInstance = null;

    public static synchronized SupabaseApi getApi() {
        if (apiInstance == null) {
            HttpLoggingInterceptor logging = new HttpLoggingInterceptor();
            logging.setLevel(HttpLoggingInterceptor.Level.BODY);

            OkHttpClient client = new OkHttpClient.Builder()
                    .addInterceptor(logging)
                    .connectTimeout(30, TimeUnit.SECONDS)
                    .readTimeout(30, TimeUnit.SECONDS)
                    .writeTimeout(30, TimeUnit.SECONDS)
                    .build();

            Retrofit retrofit = new Retrofit.Builder()
                    .baseUrl(URL)
                    .addConverterFactory(GsonConverterFactory.create())
                    .client(client)
                    .build();

            apiInstance = retrofit.create(SupabaseApi.class);
        }
        return apiInstance;
    }
}
