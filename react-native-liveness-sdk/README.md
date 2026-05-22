# react-native-liveness-sdk

A robust React Native SDK for **Active Liveness Detection** using Google ML Kit and TensorFlow Lite. This SDK provides on-device processing for privacy, speed, and cost-efficiency (completely free).

## Features

- ✅ **On-Device Processing**: No data leaves the device.
- ✅ **Active Liveness**: Detects smiling, blinking, head turns (left/right), and nodding (up/down).
- ✅ **Face Embeddings**: Generates mathematical representations of faces for future identity matching.
- ✅ **Customizable UI**: Includes a ready-to-use scanner with customizable overlays and instructions.
- ✅ **Randomized Sequences**: Prevents spoofing by requiring a random set of actions.
- ✅ **Photo Capture**: Returns a URI to the best face capture upon success.

## Installation

```sh
npm install react-native-liveness-sdk
```

## Setup

### 1. Model Setup (Required)
You must provide a `mobile_facenet.tflite` model for the embedding generation to work.

- **Android**: Place `mobile_facenet.tflite` in `android/src/main/assets/`.
- **iOS**: Place `mobile_facenet.tflite` in a `Resources` folder and ensure it's added to your Xcode project and bundled.

### 2. Permissions

#### Android
Add the following to your `AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.CAMERA" />
```

#### iOS
Add the following to your `Info.plist`:
```xml
<key>NSCameraUsageDescription</key>
<string>We need camera access for the liveness test.</string>
```

## Usage

```tsx
import React, { useState, useEffect } from 'react';
import { StyleSheet, View, Text } from 'react-native';
import {
  LivenessScanner,
  requestCameraPermission,
  type LivenessResult
} from 'react-native-liveness-sdk';

export default function App() {
  const [hasPermission, setHasPermission] = useState(false);

  useEffect(() => {
    requestCameraPermission().then(setHasPermission);
  }, []);

  const handleComplete = (result: LivenessResult) => {
    if (result.success) {
      console.log('Success! Photo URI:', result.imageUri);
      console.log('Face Embedding:', result.embedding);
    }
  };

  if (!hasPermission) {
    return <Text>Waiting for camera permission...</Text>;
  }

  return (
    <View style={styles.container}>
      <LivenessScanner
        onComplete={handleComplete}
        actions={['smile', 'blink', 'turnLeft', 'turnRight']}
        ovalColor="#00FF00"
        style={StyleSheet.absoluteFill}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
});
```

## API

### `LivenessScanner` Props

| Prop | Type | Default | Description |
| --- | --- | --- | --- |
| `actions` | `LivenessAction[]` | `Random 3` | Sequence of actions to perform. |
| `onComplete` | `(result: LivenessResult) => void` | - | Called when the test finishes. |
| `onEvent` | `(event: LivenessEvent) => void` | - | Called for every state change. |
| `ovalColor` | `string` | `#00FF00` | Color of the face oval overlay. |
| `instructionTextColor` | `string` | `#FFFFFF` | Color of the instruction text. |

### `LivenessAction`
`'smile' | 'blink' | 'turnLeft' | 'turnRight' | 'nodUp' | 'nodDown'`

### `LivenessResult`
```ts
{
  success: boolean;
  imageUri?: string;     // Local path to the captured photo
  embedding?: number[];  // 192-dimensional face vector
  error?: string;
}
```

## License

MIT
