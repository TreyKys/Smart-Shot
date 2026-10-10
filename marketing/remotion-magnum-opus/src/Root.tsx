import {Composition} from 'remotion';
import {FPS, SEC} from './theme';
import {MeetingPanic} from './ads/MeetingPanic';
import {CitedNotFabricated} from './ads/CitedNotFabricated';
import {StopReading} from './ads/StopReading';
import {TheSixHours} from './ads/TheSixHours';
import {TheNightBefore} from './ads/TheNightBefore';
import {WhichOneIsIt} from './ads/WhichOneIsIt';
import {TheThread} from './ads/TheThread';
import {TheClause} from './ads/TheClause';
import {TheCharge} from './ads/TheCharge';
import {TheClauseRemix} from './ads/TheClauseRemix';
import {TheChargeRemix} from './ads/TheChargeRemix';
import {TheClauseThriller} from './ads/TheClauseThriller';
import {TheChargeEvidence} from './ads/TheChargeEvidence';

// Vertical 9:16, 60s each (1800 frames at 30 fps) — the editorial house-
// style ads live here.
const V = {width: 1080, height: 1920};
// Landscape 16:9 — the off-brand, desktop-UI-parody ads (WhichOneIsIt =
// Finder window, TheThread = Gmail thread) are shot in landscape because
// that's how people actually use the apps they're mimicking.
const L = {width: 1920, height: 1080};
const LONG = SEC(60);
const SHORT = SEC(20);
const MID = SEC(25);

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
      <Composition
        id="WhichOneIsIt"
        component={WhichOneIsIt}
        durationInFrames={SHORT}
        fps={FPS}
        width={L.width}
        height={L.height}
      />
      <Composition
        id="TheThread"
        component={TheThread}
        durationInFrames={MID}
        fps={FPS}
        width={L.width}
        height={L.height}
      />
      <Composition
        id="TheClause"
        component={TheClause}
        durationInFrames={MID}
        fps={FPS}
        width={V.width}
        height={V.height}
      />
      <Composition
        id="TheCharge"
        component={TheCharge}
        durationInFrames={MID}
        fps={FPS}
        width={V.width}
        height={V.height}
      />
      <Composition
        id="TheClauseRemix"
        component={TheClauseRemix}
        durationInFrames={SEC(24)}
        fps={FPS}
        width={V.width}
        height={V.height}
      />
      <Composition
        id="TheChargeRemix"
        component={TheChargeRemix}
        durationInFrames={SEC(24)}
        fps={FPS}
        width={V.width}
        height={V.height}
      />
      <Composition
        id="TheClauseThriller"
        component={TheClauseThriller}
        durationInFrames={SEC(24)}
        fps={FPS}
        width={V.width}
        height={V.height}
      />
      <Composition
        id="TheChargeEvidence"
        component={TheChargeEvidence}
        durationInFrames={SEC(24)}
        fps={FPS}
        width={V.width}
        height={V.height}
      />
    </>
  );
};
