import React, { useState, useEffect, useCallback } from 'react';
import { StyleSheet, View, Text, ActivityIndicator } from 'react-native';
import LivenessSdkViewNativeComponent, { type LivenessAction, type LivenessEvent } from './LivenessSdkViewNativeComponent';
import { getRandomActions } from './utils';

export type { LivenessAction, LivenessEvent };

export interface LivenessScannerProps {
  actions?: LivenessAction[];
  ovalColor?: string;
  instructionTextColor?: string;
  instructionTextSize?: number;
  onEvent?: (event: LivenessEvent) => void;
  onComplete?: (result: any) => void;
  style?: any;
}

export const LivenessScanner: React.FC<LivenessScannerProps> = ({
  actions: initialActions,
  ovalColor = '#00FF00',
  instructionTextColor = '#FFFFFF',
  instructionTextSize = 20,
  onEvent,
  onComplete,
  style,
}) => {
  const [actions] = useState<LivenessAction[]>(() => initialActions || getRandomActions(3));
  const [currentStep, setCurrentStep] = useState<string>(actions[0] || '');
  const [isCompleted, setIsCompleted] = useState(false);

  const handleEvent = useCallback((event: any) => {
    const nativeEvent: LivenessEvent = event.nativeEvent;

    if (nativeEvent.status === 'step_completed') {
      setCurrentStep(nativeEvent.currentStep || '');
    } else if (nativeEvent.status === 'completed') {
      setIsCompleted(true);
      setCurrentStep('Success!');
      if (onComplete) {
        onComplete(nativeEvent.result);
      }
    }

    if (onEvent) {
      onEvent(nativeEvent);
    }
  }, [onEvent, onComplete]);

  const getInstructionText = (step: string) => {
    switch (step) {
      case 'smile': return 'Please Smile';
      case 'blink': return 'Please Blink your eyes';
      case 'turnLeft': return 'Turn your head Left';
      case 'turnRight': return 'Turn your head Right';
      case 'nodUp': return 'Nod your head Up';
      case 'nodDown': return 'Nod your head Down';
      case 'Success!': return 'Liveness Check Complete!';
      default: return 'Position your face in the oval';
    }
  };

  return (
    <View style={[styles.container, style]}>
      <LivenessSdkViewNativeComponent
        actions={actions}
        ovalColor={ovalColor}
        instructionTextColor={instructionTextColor}
        instructionTextSize={instructionTextSize}
        onLivenessEvent={handleEvent}
        style={StyleSheet.absoluteFill}
      />
      <View style={styles.overlay}>
        <Text style={[
          styles.instructionText,
          { color: instructionTextColor, fontSize: instructionTextSize }
        ]}>
          {getInstructionText(currentStep)}
        </Text>
        {isCompleted && (
          <View style={styles.successBadge}>
             <Text style={styles.successText}>✓</Text>
          </View>
        )}
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#000',
    overflow: 'hidden',
  },
  overlay: {
    ...StyleSheet.absoluteFillObject,
    justifyContent: 'flex-start',
    alignItems: 'center',
    paddingTop: 60,
    pointerEvents: 'none',
  },
  instructionText: {
    fontWeight: 'bold',
    textAlign: 'center',
    textShadowColor: 'rgba(0, 0, 0, 0.75)',
    textShadowOffset: { width: -1, height: 1 },
    textShadowRadius: 10,
  },
  successBadge: {
    marginTop: 20,
    width: 60,
    height: 60,
    borderRadius: 30,
    backgroundColor: '#00FF00',
    justifyContent: 'center',
    alignItems: 'center',
  },
  successText: {
    color: '#FFF',
    fontSize: 32,
    fontWeight: 'bold',
  }
});
