package com.example.photoslideshow;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;

/** Launches the slideshow when the TV finishes booting. */
public class BootReceiver extends BroadcastReceiver {
    @Override
    public void onReceive(Context context, Intent intent) {
        Intent launch = new Intent(context, MainActivity.class);
        launch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        context.startActivity(launch);
    }
}
