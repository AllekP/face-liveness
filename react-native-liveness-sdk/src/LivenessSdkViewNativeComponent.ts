import {
  codegenNativeComponent,
  type ViewProps,
  type HostComponent,
} from 'react-native';
import type { DirectEventHandler } from 'react-native/Libraries/Types/CodegenTypes';

export type LivenessAction =
  | 'smile'
  | 'blink'
  | 'turnLeft'
  | 'turnRight'
  | 'nodUp'
  | 'nodDown';

export interface LivenessResult {
  success: boolean;
  imageUri?: string;
  embedding?: number[];
  error?: string;
}

export interface LivenessEvent {
  status: 'started' | 'step_completed' | 'completed' | 'failed';
  currentStep?: LivenessAction;
  remainingSteps?: number;
  result?: LivenessResult;
}

interface NativeProps extends ViewProps {
  // Configuration
  actions: string[]; // e.g. ["smile", "blink"]
  ovalColor?: string;
  instructionTextColor?: string;
  instructionTextSize?: number;

  // Callbacks
  onLivenessEvent?: DirectEventHandler<LivenessEvent>;
}

export default codegenNativeComponent<NativeProps>('LivenessSdkView') as HostComponent<NativeProps>;
