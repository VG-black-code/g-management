package com.example.demoapp;

import android.animation.ObjectAnimator;
import android.animation.ValueAnimator;
import android.content.Intent;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.view.View;
import android.view.animation.LinearInterpolator;
import android.widget.ImageView;
import androidx.appcompat.app.AppCompatActivity;

public class SplashActivity extends AppCompatActivity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        
        // Fullscreen immersive mode
        getWindow().getDecorView().setSystemUiVisibility(
                View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                | View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                | View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                | View.SYSTEM_UI_FLAG_FULLSCREEN
                | View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY);
                
        setContentView(R.layout.activity_splash);

        ImageView logoOuter = findViewById(R.id.logo_outer);
        
        // 1. Spinning Animation for Outer Sections using ObjectAnimator
        // Rotates 360 degrees infinitely
        ObjectAnimator rotateAnim = ObjectAnimator.ofFloat(logoOuter, "rotation", 0f, 360f);
        rotateAnim.setDuration(4000); // Speed of rotation
        rotateAnim.setInterpolator(new LinearInterpolator());
        rotateAnim.setRepeatCount(ValueAnimator.INFINITE);
        rotateAnim.start();

        // 2. Fast transition to MainActivity (After 3 seconds as requested)
        new Handler(Looper.getMainLooper()).postDelayed(this::navigateToMain, 3000);
    }

    private void navigateToMain() {
        Intent intent = new Intent(SplashActivity.this, MainActivity.class);
        startActivity(intent);
        finish();
        // Modern smooth fade transition
        overridePendingTransition(android.R.anim.fade_in, android.R.anim.fade_out);
    }
}
