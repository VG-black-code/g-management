package com.example.demoapp;

import android.content.Intent;
import android.media.PlaybackParams;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.view.View;
import android.widget.VideoView;
import androidx.appcompat.app.AppCompatActivity;

public class SplashActivity extends AppCompatActivity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        
        // Hide status bar and navigation bar for true full screen
        getWindow().getDecorView().setSystemUiVisibility(
                View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                | View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                | View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                | View.SYSTEM_UI_FLAG_FULLSCREEN
                | View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY);
                
        setContentView(R.layout.activity_splash);

        VideoView videoView = findViewById(R.id.videoView);
        
        String videoPath = "android.resource://" + getPackageName() + "/raw/intro_video";
        Uri uri = Uri.parse(videoPath);
        
        videoView.setVideoURI(uri);

        videoView.setOnPreparedListener(mp -> {
            // Adjust speed (little fast)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                PlaybackParams params = new PlaybackParams();
                params.setSpeed(1.2f); // 20% faster
                mp.setPlaybackParams(params);
            }
            // Set video scaling to fill screen vertically (Stretch to fill)
            mp.setVideoScalingMode(android.media.MediaPlayer.VIDEO_SCALING_MODE_SCALE_TO_FIT_WITH_CROPPING);
            videoView.start();
        });

        videoView.setOnCompletionListener(mp -> {
            navigateToMain();
        });

        videoView.setOnErrorListener((mp, what, extra) -> {
            navigateToMain();
            return true;
        });
    }

    private void navigateToMain() {
        Intent intent = new Intent(SplashActivity.this, MainActivity.class);
        startActivity(intent);
        finish();
        // Custom smooth fade transition
        overridePendingTransition(android.R.anim.fade_in, android.R.anim.fade_out);
    }
}
