import {Composition} from 'remotion';
import {FPS, SEC} from './theme';
import {MeetingPanic} from './ads/MeetingPanic';
import {CitedNotFabricated} from './ads/CitedNotFabricated';
import {StopReading} from './ads/StopReading';
import {TheSixHours} from './ads/TheSixHours';
import {TheNightBefore} from './ads/TheNightBefore';

// Vertical 9:16, 60s each (1800 frames at 30 fps).
const V = {width: 1080, height: 1920};
const LONG = SEC(60);

export const RemotionRoot: React.FC = () => {
  return (
    <>
      <Composition
        id="MeetingPanic"
        component={MeetingPanic}
        durationInFrames={LONG}
        fps={FPS}
        width={V.width}
        height={V.height}
      />
      <Composition
        id="CitedNotFabricated"
        component={CitedNotFabricated}
        durationInFrames={LONG}
        fps={FPS}
        width={V.width}
        height={V.height}
      />
      <Composition
        id="StopReading"
        component={StopReading}
        durationInFrames={LONG}
        fps={FPS}
        width={V.width}
        height={V.height}
      />
      <Composition
        id="TheSixHours"
        component={TheSixHours}
        durationInFrames={LONG}
        fps={FPS}
        width={V.width}
        height={V.height}
      />
      <Composition
        id="TheNightBefore"
        component={TheNightBefore}
        durationInFrames={LONG}
        fps={FPS}
        width={V.width}
        height={V.height}
      />
    </>
  );
};
