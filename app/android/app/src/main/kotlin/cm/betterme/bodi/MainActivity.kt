package cm.betterme.bodi

import io.flutter.embedding.android.FlutterFragmentActivity

// Health Connect's permission sheet is launched with registerForActivityResult,
// which the health plugin reaches by casting the host activity to
// ComponentActivity. FlutterActivity extends android.app.Activity and fails
// that cast, leaving the plugin with a null launcher: every request then
// returns false and logs "Permission launcher not found", with no sheet shown.
// FlutterFragmentActivity is a ComponentActivity, so the launcher registers.
class MainActivity : FlutterFragmentActivity()
