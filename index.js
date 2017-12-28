import 'react-native/Libraries/Core/InitializeCore';
import React from 'react';
import { AppRegistry, StyleSheet, View, NativeModules } from 'react-native';
import { startup, components } from 'browser-core';
import 'babel-polyfill';

// set app global for debugging
const appStart = startup.then((app) => {
  global.app = app;
});

const styles = function () {
  return StyleSheet.create({
    container: {
      flex: 1,
      flexDirection: 'column',
      backgroundColor: '#FFFFFF'
    },
  });
};

// wrapper for a component to add top padding on iOS
function AppContainer(App, appStart) {
  return () => (
    <View style={styles().container}>
      <App appStart={appStart} />
    </View>
  );
}

// register components from config
Object.keys(components).forEach((component) => {
  AppRegistry.registerComponent(component, () => AppContainer(components[component], appStart));
});
