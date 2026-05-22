import { Platform, PermissionsAndroid } from 'react-native';

export async function requestCameraPermission(): Promise<boolean> {
  if (Platform.OS === 'android') {
    try {
      const granted = await PermissionsAndroid.request(
        PermissionsAndroid.PERMISSIONS.CAMERA,
        {
          title: 'Camera Permission',
          message: 'Liveness SDK needs access to your camera to perform the test.',
          buttonNeutral: 'Ask Me Later',
          buttonNegative: 'Cancel',
          buttonPositive: 'OK',
        }
      );
      return granted === PermissionsAndroid.RESULTS.GRANTED;
    } catch (err) {
      console.warn(err);
      return false;
    }
  }
  // For iOS, permissions are typically handled via Info.plist and automatic prompts by AVFoundation
  // when the session starts, but a pre-check can be done with libraries like react-native-permissions.
  return true;
}
