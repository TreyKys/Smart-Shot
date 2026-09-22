import {Composition} from 'remotion';
import {FPS, SEC} from './theme';
import {MeetingPanic} from './ads/MeetingPanic';
import {CitedNotFabricated} from './ads/CitedNotFabricated';
import {StopReading} from './ads/StopReading';

// Vertical 9:16 — matches Magnum Opus's existing HTML ads
// (marketing/ad_v3_*/index.html in the Magnum-Opus repo, all 1080x1920).
const V = {width: 1080, height: 1920};

export const RemotionRoot: React.FC = () => {
  return (
    <>
      <Composition
        id="MeetingPanic"
        component={MeetingPanic}
        durationInFrames={SEC(20)}
        fps={FPS}
        width={V.width}
        height={V.height}
      />
      <Composition
        id="CitedNotFabricated"
        component={CitedNotFabricated}
        durationInFrames={SEC(20)}
        fps={FPS}
        width={V.width}
        height={V.height}
      />
      <Composition
        id="StopReading"
        component={StopReading}
        durationInFrames={SEC(20)}
        fps={FPS}
        width={V.width}
        height={V.height}
      />
    </>
  );
};
