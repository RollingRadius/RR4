# iOS Configuration for GPS Tracking

Since the iOS folder structure is not present in this project, follow these steps when setting up iOS:

## Info.plist Configuration

Add the following entries to your `ios/Runner/Info.plist` file:

```xml
<!-- Location Permissions -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to track deliveries and optimize routes while you use the app.</string>

<key>NSLocationAlwaysUsageDescription</key>
<string>We need your location to track deliveries even when the app is in the background.</string>

<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>We need continuous location access to track your deliveries and provide accurate fleet management.</string>

<!-- Background Modes -->
<key>UIBackgroundModes</key>
<array>
    <string>location</string>
    <string>fetch</string>
    <string>processing</string>
</array>

<!-- Location Accuracy (iOS 14+) -->
<key>NSLocationTemporaryUsageDescriptionDictionary</key>
<dict>
    <key>delivery-tracking</key>
    <string>We need precise location to track delivery progress and optimize routes.</string>
</dict>
```

## Full Info.plist Example

Here's a complete example of what your Info.plist should look like:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- App Configuration -->
    <key>CFBundleDevelopmentRegion</key>
    <string>$(DEVELOPMENT_LANGUAGE)</string>
    <key>CFBundleDisplayName</key>
    <string>Fleet Management</string>
    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>
    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>fleet_management</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$(FLUTTER_BUILD_NAME)</string>
    <key>CFBundleSignature</key>
    <string>????</string>
    <key>CFBundleVersion</key>
    <string>$(FLUTTER_BUILD_NUMBER)</string>
    <key>LSRequiresIPhoneOS</key>
    <true/>
    <key>UILaunchStoryboardName</key>
    <string>LaunchScreen</string>
    <key>UIMainStoryboardFile</key>
    <string>Main</string>
    <key>UISupportedInterfaceOrientations</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
        <string>UIInterfaceOrientationLandscapeLeft</string>
        <string>UIInterfaceOrientationLandscapeRight</string>
    </array>
    <key>UISupportedInterfaceOrientations~ipad</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
        <string>UIInterfaceOrientationPortraitUpsideDown</string>
        <string>UIInterfaceOrientationLandscapeLeft</string>
        <string>UIInterfaceOrientationLandscapeRight</string>
    </array>
    <key>UIViewControllerBasedStatusBarAppearance</key>
    <false/>
    <key>CADisableMinimumFrameDurationOnPhone</key>
    <true/>
    <key>UIApplicationSupportsIndirectInputEvents</key>
    <true/>

    <!-- Location Permissions -->
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>We need your location to track deliveries and optimize routes while you use the app.</string>

    <key>NSLocationAlwaysUsageDescription</key>
    <string>We need your location to track deliveries even when the app is in the background.</string>

    <key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
    <string>We need continuous location access to track your deliveries and provide accurate fleet management.</string>

    <!-- Background Modes -->
    <key>UIBackgroundModes</key>
    <array>
        <string>location</string>
        <string>fetch</string>
        <string>processing</string>
    </array>

    <!-- Location Accuracy (iOS 14+) -->
    <key>NSLocationTemporaryUsageDescriptionDictionary</key>
    <dict>
        <key>delivery-tracking</key>
        <string>We need precise location to track delivery progress and optimize routes.</string>
    </dict>
</dict>
</plist>
```

## Xcode Configuration

1. **Open Xcode Project:**
   ```bash
   cd frontend/ios
   open Runner.xcworkspace
   ```

2. **Enable Background Modes:**
   - Select the Runner target
   - Go to "Signing & Capabilities"
   - Click "+ Capability"
   - Add "Background Modes"
   - Enable:
     - Location updates
     - Background fetch
     - Background processing

3. **Configure Location Accuracy (iOS 14+):**
   - In your app's capability settings, ensure "Location" is set to "Full Accuracy"

## Testing on iOS

### Simulator Testing
```bash
# Reset location permissions
xcrun simctl privacy booted reset location com.fleet_management.app

# Simulate location
xcrun simctl location booted set 28.6139 77.2090
```

### Device Testing

1. **Enable Developer Mode:**
   - Settings → Privacy & Security → Developer Mode → On

2. **Test Background Location:**
   - Settings → Privacy → Location Services → Your App
   - Select "Always" permission
   - Enable "Precise Location"
   - Run app and send to background
   - Check that location updates continue

3. **Monitor Console:**
   ```bash
   # View device logs
   xcrun simctl spawn booted log stream --predicate 'process == "Runner"'
   ```

## Battery Optimization

iOS automatically manages background location updates. Best practices:

1. **Use `allowsBackgroundLocationUpdates`:**
   ```swift
   locationManager.allowsBackgroundLocationUpdates = true
   locationManager.pausesLocationUpdatesAutomatically = false
   ```

2. **Request Reduced Accuracy When Appropriate:**
   - Use `.reducedAccuracy` for non-critical updates
   - Request full accuracy only when needed

3. **Defer Location Updates:**
   ```swift
   locationManager.allowDeferredLocationUpdates(
       untilTraveled: 100,  // 100 meters
       timeout: 60          // 60 seconds
   )
   ```

## App Store Requirements

When submitting to App Store, you must provide clear explanations for:

1. **Location Permission:**
   - Explain why background location is needed
   - Show screenshots of location features
   - Describe user benefits

2. **Background Modes:**
   - Justify why location updates are needed in background
   - Demonstrate the feature in action

3. **Privacy Policy:**
   - Include URL to privacy policy in App Store Connect
   - Explain how location data is used and stored
   - Detail data retention policies

## Troubleshooting

### Location Not Working in Background

1. Check Info.plist has all required keys
2. Verify Background Modes capability is enabled
3. Ensure "Always" permission is granted
4. Check that `allowsBackgroundLocationUpdates` is true

### App Rejected for Background Location

1. Ensure Info.plist descriptions clearly explain usage
2. Provide App Review team with test account
3. Include demo video showing feature
4. Update privacy policy with location data usage

### High Battery Usage

1. Increase `distanceFilter` (e.g., 50 meters)
2. Use deferred location updates
3. Reduce accuracy when possible
4. Implement geofencing instead of continuous tracking

## Production Checklist

- [ ] Info.plist configured with all location keys
- [ ] Background Modes capability enabled in Xcode
- [ ] Location permission descriptions are clear and user-friendly
- [ ] Tested "Always" permission flow
- [ ] Verified background location updates work
- [ ] Battery consumption tested (< 5% per hour target)
- [ ] Privacy policy updated with location usage
- [ ] App Store description mentions location features
- [ ] Screenshots prepared showing location features
- [ ] Test account created for App Review
