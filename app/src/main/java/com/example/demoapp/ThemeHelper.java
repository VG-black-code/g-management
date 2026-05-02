package com.example.demoapp;

import android.app.Activity;
import android.content.Context;
import android.content.SharedPreferences;

public class ThemeHelper {
    public static void applyTheme(Activity activity) {
        SharedPreferences prefs = activity.getSharedPreferences("ThemePrefs", Context.MODE_PRIVATE);
        String theme = prefs.getString("selectedTheme", "Lavender"); // Default to Lavender since Normal is removed
        
        switch (theme) {
            case "Dark":
                activity.setTheme(R.style.Theme_Demoapp_Dark);
                break;
            case "Lavender":
                activity.setTheme(R.style.Theme_Demoapp_Lavender);
                break;
            case "Light Blue":
                activity.setTheme(R.style.Theme_Demoapp_LightBlue);
                break;
            case "Orange":
                activity.setTheme(R.style.Theme_Demoapp_Orange);
                break;
            default:
                activity.setTheme(R.style.Theme_Demoapp_Lavender);
                break;
        }
    }
}
