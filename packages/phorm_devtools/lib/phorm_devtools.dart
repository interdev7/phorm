/// Phorm Studio DevTools bridge.
///
/// Exposes running PHORM databases to the Phorm Studio DevTools extension
/// in debug builds. See [enablePhormDevtools].
library;

export 'src/bridge.dart' show PhormDevtoolsBridge, enablePhormDevtools;
