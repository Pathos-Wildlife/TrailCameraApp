# trail_camera_app

A new Flutter project.

## Google sign-in

The Google button uses the `google_sign_in` plugin to authenticate and display
the selected account on iOS and Android. At startup the app attempts to restore
the Google-managed sign-in; otherwise it shows the login page. Successful
sign-in opens the Camera Map. Google may show an account chooser when restoring
credentials. This is a prototype and does not create an app account or
authenticate to a backend; a backend must validate Google ID tokens itself.
The Settings page displays the signed-in user's name, email and provider. Its
Log out button signs out through Google and returns to the login page.

### iOS setup

To try the flow on the iOS simulator:

1. In [Google Cloud Console](https://console.cloud.google.com/), create or select
   a project. Set up Google Auth Platform branding, audience and contact details.
   If the app is external and in testing, add your Google account under **Test
   users**.
2. Under **Google Auth Platform > Clients**, create an OAuth client of type
   **iOS**. Use bundle ID `org.pathoswildlife.trailcameraapp`, or change it in
   Xcode and use the exact same value in Google Cloud. Copy the client ID and
   the **iOS URL scheme** shown for that client. This can be configured directly
   in Google Cloud; Firebase is not required.
3. In `ios/Runner/Info.plist`, replace
   `com.googleusercontent.apps.REPLACE_WITH_IOS_CLIENT_ID_PREFIX` with that
   iOS URL scheme. It is the reversed client ID, for example
   `com.googleusercontent.apps.123456789-abcdef`. Do not add a client secret to
   the app.
4. Open `trail_camera_app` in Rider, start an iOS simulator, and run in the
   terminal:

   ```sh
   flutter pub get
   flutter run -d <simulator-id> --dart-define=GOOGLE_IOS_CLIENT_ID=<your-ios-client-id>
   ```

   Find the simulator ID with `flutter devices`. Alternatively, add
   `--dart-define=GOOGLE_IOS_CLIENT_ID=<your-ios-client-id>` to the Flutter run
   configuration's additional run arguments in Rider. The client ID ends in
   `.apps.googleusercontent.com`; it is not the reversed URL scheme. Restart
   the app after changing a compile-time define.

The SDK handles the Google authentication flow and callback. If you add backend
authentication, configure a web/server client ID and send a Google ID token to
the backend for validation; never trust the displayed account ID or email alone.

### Android setup

1. In [Google Cloud Console](https://console.cloud.google.com/), create or select
   the same project used for iOS. Under **Google Auth Platform > Clients**, add
   an **Android** OAuth client using the application ID
   `org.pathoswildlife.trail_camera_app` and the SHA-1 signing certificate
   fingerprint for the certificate used to sign the installed app. Retrieve
   Gradle signing fingerprints from `trail_camera_app` with
   `cd android && ./gradlew signingReport`.
2. Create or select a **Web application** OAuth client in that project. Use
   that client's ID—not the Android client ID—as `GOOGLE_SERVER_CLIENT_ID`.
3. Run the app with the Web client ID:

   ```sh
   flutter run -d <android-device-id> --dart-define=GOOGLE_SERVER_CLIENT_ID=<your-web-client-id>
   ```

   Find the device ID with `flutter devices`. Add the same define to your run
   configuration in Rider if needed. Do not add a client secret to the app.

Debug, profile, and release builds use `android/PathosKeystore.jks` and the
credentials in the ignored `android/key.properties` file. On another machine,
securely obtain the keystore and create that file with `storePassword`,
`keyPassword`, and `keyAlias` properties; escape backslashes as `\\` in
property values. Never commit either file. If distributing through Google Play
App Signing, also register the Play app-signing certificate's SHA-1 in Google
Cloud.

See the [`google_sign_in` Android setup guide](https://pub.dev/packages/google_sign_in_android)
for details. Web sign-in is not enabled by this app.

## Camera map

The landing page displays OpenStreetMap tiles around Cozumel. The map center is
restricted to the island area and the zoom range is limited; surrounding sea
and coastline can still be visible. A network connection is required to fetch
uncached tiles. The public OpenStreetMap tile service is best-effort and subject
to its [usage policy](https://operations.osmfoundation.org/policies/tiles/);
use an appropriate tile provider for production traffic. The other menu
destinations have placeholder pages; their content is not implemented yet.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
