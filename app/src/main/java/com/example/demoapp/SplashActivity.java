package com.example.demoapp;

import android.animation.Animator;
import android.animation.AnimatorListenerAdapter;
import android.animation.AnimatorSet;
import android.animation.ObjectAnimator;
import android.content.Intent;
import android.graphics.Color;
import android.os.Bundle;
import android.view.View;
import android.view.animation.DecelerateInterpolator;
import android.view.animation.LinearInterpolator;
import android.view.animation.PathInterpolator;
import android.widget.FrameLayout;
import android.widget.ImageView;
import android.widget.TextView;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.splashscreen.SplashScreen;

public class SplashActivity extends AppCompatActivity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        // Handover from System Splash
        SplashScreen splashScreen = SplashScreen.installSplashScreen(this);
        super.onCreate(savedInstanceState);

        // Premium Immersive Fullscreen
        getWindow().getDecorView().setSystemUiVisibility(
                View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                        | View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                        | View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                        | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                        | View.SYSTEM_UI_FLAG_FULLSCREEN
                        | View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY);
        
        getWindow().setStatusBarColor(Color.BLACK);
        getWindow().setNavigationBarColor(Color.BLACK);

        setContentView(R.layout.activity_splash);
        
        final FrameLayout logoFrame = findViewById(R.id.logoFrame);
        final ImageView logoOuter = findViewById(R.id.logo_outer);
        final View centerWindow = findViewById(R.id.logo_center_window);
        final TextView appName = findViewById(R.id.appName);

        // Hardware Acceleration
        logoOuter.setLayerType(View.LAYER_TYPE_HARDWARE, null);
        centerWindow.setLayerType(View.LAYER_TYPE_HARDWARE, null);

        // 0ms State
        logoFrame.setAlpha(0f);
        logoFrame.setScaleX(0.9f);
        logoFrame.setScaleY(0.9f);
        appName.setAlpha(0f);
        appName.setTranslationY(20f);

        // 1. Entrance (0ms - 300ms): Logo Pop-in
        ObjectAnimator logoFadeIn = ObjectAnimator.ofFloat(logoFrame, "alpha", 0f, 1f);
        ObjectAnimator logoScaleX = ObjectAnimator.ofFloat(logoFrame, "scaleX", 0.9f, 1f);
        ObjectAnimator logoScaleY = ObjectAnimator.ofFloat(logoFrame, "scaleY", 0.9f, 1f);
        
        AnimatorSet entranceSet = new AnimatorSet();
        entranceSet.playTogether(logoFadeIn, logoScaleX, logoScaleY);
        entranceSet.setDuration(300);

        // 2. Turbine Rotation (300ms - 2200ms)
        // Aggressive start and smooth glide to perfect alignment (1080 degrees)
        ObjectAnimator rotateAnim = ObjectAnimator.ofFloat(logoOuter, "rotation", 0f, 1080f);
        rotateAnim.setDuration(1900);
        rotateAnim.setStartDelay(300);
        // Custom Ease-Out curve for the "turbine" feel
        rotateAnim.setInterpolator(new PathInterpolator(0.1f, 0.9f, 0.2f, 1f));

        // 3. SMARTIFY Entrance (Starts with spin at 300ms)
        ObjectAnimator textFadeIn = ObjectAnimator.ofFloat(appName, "alpha", 0f, 1f);
        ObjectAnimator textSlideUp = ObjectAnimator.ofFloat(appName, "translationY", 20f, 0f);
        AnimatorSet textSet = new AnimatorSet();
        textSet.playTogether(textFadeIn, textSlideUp);
        textSet.setDuration(1000);
        textSet.setStartDelay(300);

        // Elevation Pulse (Shadow/Glow)
        ObjectAnimator glowAnim = ObjectAnimator.ofFloat(logoFrame, "translationZ", 0f, 24f, 0f);
        glowAnim.setDuration(1900);
        glowAnim.setStartDelay(300);

        // Final sequence
        AnimatorSet finalSet = new AnimatorSet();
        finalSet.playTogether(entranceSet, rotateAnim, textSet, glowAnim);

        finalSet.addListener(new AnimatorListenerAdapter() {
            @Override
            public void onAnimationEnd(Animator animation) {
                // 2200ms - 2700ms: Hold
                logoFrame.postDelayed(() -> navigateToMain(), 500);
            }
        });

        finalSet.start();
    }

    private void navigateToMain() {
        Intent intent = new Intent(SplashActivity.this, MainActivity.class);
        startActivity(intent);
        finish();
        overridePendingTransition(android.R.anim.fade_in, android.R.anim.fade_out);
    }
}
