import React, { useState, useEffect } from 'react';
import { View, StyleSheet, Text, TouchableOpacity, SafeAreaView, ScrollView, Image } from 'react-native';
import { LivenessScanner, type LivenessEvent, requestCameraPermission } from 'react-native-liveness-sdk';

export default function App() {
  const [hasPermission, setHasPermission] = useState<boolean | null>(null);

  useEffect(() => {
    requestCameraPermission().then(setHasPermission);
  }, []);
  const [isScanning, setIsScanning] = useState(false);
  const [result, setResult] = useState<any>(null);

  const handleComplete = (livenessResult: any) => {
    console.log('Liveness result:', livenessResult);
    setResult(livenessResult);
    setTimeout(() => setIsScanning(false), 2000);
  };

  const handleEvent = (event: LivenessEvent) => {
    console.log('Liveness event:', event);
  };

  if (isScanning) {
    return (
      <View style={styles.container}>
        <LivenessScanner
          onComplete={handleComplete}
          onEvent={handleEvent}
          style={StyleSheet.absoluteFill}
        />
        <TouchableOpacity
          style={styles.closeButton}
          onPress={() => setIsScanning(false)}
        >
          <Text style={styles.closeButtonText}>✕</Text>
        </TouchableOpacity>
      </View>
    );
  }

  return (
    <SafeAreaView style={styles.container}>
      <ScrollView contentContainerStyle={styles.content}>
        <Text style={styles.title}>Liveness SDK Demo</Text>

        <TouchableOpacity
          style={styles.button}
          onPress={() => {
            setResult(null);
            setIsScanning(true);
          }}
        >
          <Text style={styles.buttonText}>Start Liveness Test</Text>
        </TouchableOpacity>

        {result && (
          <View style={styles.resultContainer}>
            <Text style={styles.resultTitle}>Result:</Text>

            {result.imageUri && (
              <Image
                source={{ uri: result.imageUri }}
                style={styles.capturedImage}
                resizeMode="cover"
              />
            )}

            <Text style={styles.resultText}>
              Success: {result.success ? '✅' : '❌'}
            </Text>
            {result.embedding && (
              <Text style={styles.resultText}>
                Face Embedding generated ({result.embedding.length} dimensions)
              </Text>
            )}
            <Text style={styles.resultSubtext}>
              {JSON.stringify(result, null, 2).substring(0, 200)}...
            </Text>
          </View>
        )}
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F5F5F5',
  },
  content: {
    padding: 20,
    alignItems: 'center',
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    marginBottom: 40,
    marginTop: 20,
  },
  button: {
    backgroundColor: '#007AFF',
    paddingHorizontal: 30,
    paddingVertical: 15,
    borderRadius: 10,
  },
  buttonText: {
    color: '#FFFFFF',
    fontSize: 18,
    fontWeight: '600',
  },
  closeButton: {
    position: 'absolute',
    top: 50,
    right: 20,
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: 'rgba(0,0,0,0.5)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  closeButtonText: {
    color: '#FFF',
    fontSize: 20,
  },
  resultContainer: {
    marginTop: 40,
    padding: 20,
    backgroundColor: '#FFF',
    borderRadius: 10,
    width: '100%',
    borderWidth: 1,
    borderColor: '#DDD',
  },
  resultTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    marginBottom: 10,
  },
  capturedImage: {
    width: '100%',
    height: 200,
    borderRadius: 10,
    marginBottom: 15,
    backgroundColor: '#EEE',
  },
  resultText: {
    fontSize: 16,
    marginBottom: 5,
  },
  resultSubtext: {
    fontSize: 12,
    color: '#666',
    fontFamily: 'monospace',
    marginTop: 10,
  },
});
