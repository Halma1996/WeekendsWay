package org.weekendsway;

import android.content.Context;
import android.content.Intent;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.content.pm.ResolveInfo;
import android.net.Uri;

public final class MapsBridge {
    private MapsBridge() {}

    private static Intent intent(String packageName, String url) {
        Uri uri = Uri.parse(url);
        boolean allowed = ("ru.yandex.yandexmaps".equals(packageName)
                && "yandexmaps".equals(uri.getScheme()) && "maps.yandex.ru".equals(uri.getHost()))
            || ("com.google.android.apps.maps".equals(packageName)
                && "https".equals(uri.getScheme()) && "www.google.com".equals(uri.getHost()))
            || ("ru.dublgis.dgismobile".equals(packageName)
                && "dgis".equals(uri.getScheme()) && "2gis.ru".equals(uri.getHost()));
        if (!allowed) return null;
        // setPackage bypasses the device's browser/default-map resolver.
        return new Intent(Intent.ACTION_VIEW, uri).setPackage(packageName)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
    }

    public static boolean isAvailable(Context context, String packageName, String url) {
        if (context == null) return false;
        try {
            Intent target = intent(packageName, url);
            if (target == null) return false;
            PackageManager manager = context.getPackageManager();
            ApplicationInfo app = manager.getApplicationInfo(packageName, 0);
            if (!app.enabled || (app.flags & ApplicationInfo.FLAG_SUSPENDED) != 0) return false;
            ResolveInfo resolved = manager.resolveActivity(target, PackageManager.MATCH_DEFAULT_ONLY);
            return resolved != null && resolved.activityInfo != null && resolved.activityInfo.enabled
                && resolved.activityInfo.exported && packageName.equals(resolved.activityInfo.packageName);
        } catch (Exception unavailable) {
            return false;
        }
    }

    public static boolean open(Context context, String packageName, String url) {
        if (!isAvailable(context, packageName, url)) return false;
        try {
            context.startActivity(intent(packageName, url));
            return true;
        } catch (Exception unavailable) {
            // An app may have been removed/disabled after the chooser was shown.
            // Do not fall back to a different app or log the destination address.
            return false;
        }
    }
}
