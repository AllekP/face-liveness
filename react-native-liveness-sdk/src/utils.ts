import { type LivenessAction } from './LivenessSdkViewNativeComponent';

export function getRandomActions(count: number = 3): LivenessAction[] {
  const allActions: LivenessAction[] = ['smile', 'blink', 'turnLeft', 'turnRight', 'nodUp', 'nodDown'];
  const shuffled = [...allActions].sort(() => 0.5 - Math.random());
  return shuffled.slice(0, count);
}
