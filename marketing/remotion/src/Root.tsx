import {Composition} from 'remotion';
import {FPS, SEC} from './theme';
import {SearchFrustration} from './ads/SearchFrustration';
import {DuplicateTrap} from './ads/DuplicateTrap';
import {JunkPile} from './ads/JunkPile';
import {MemoryLane} from './ads/MemoryLane';
import {AskInPlainEnglish} from './ads/AskInPlainEnglish';
import {ChaosStory} from './ads/ChaosStory';
import {TimeRecovery} from './ads/TimeRecovery';

/// Vertical 9:16 for stories/reels/shorts. Every ad uses this so a single
/// export goes to every social surface without a separate re-render per
/// aspect ratio. If a landscape cut is ever needed, add a second
/// Composition per ad with the same component and a 16:9 size — a small
/// duplication rather than parameterizing every layout math on aspect.
const V = {width: 1080, height: 1920};

export const RemotionRoot: React.FC = () => {
  return (
    <>
      <Composition
        id="SearchFrustration"
        component={SearchFrustration}
        durationInFrames={SEC(20)}
        fps={FPS}
        width={V.width}
        height={V.height}
      />
      <Composition
        id="DuplicateTrap"
        component={DuplicateTrap}
        durationInFrames={SEC(20)}
        fps={FPS}
        width={V.width}
        height={V.height}
      />
      <Composition
        id="JunkPile"
        component={JunkPile}
        durationInFrames={SEC(20)}
        fps={FPS}
        width={V.width}
        height={V.height}
      />
      <Composition
        id="MemoryLane"
        component={MemoryLane}
        durationInFrames={SEC(20)}
        fps={FPS}
        width={V.width}
        height={V.height}
      />
      <Composition
        id="AskInPlainEnglish"
        component={AskInPlainEnglish}
        durationInFrames={SEC(20)}
        fps={FPS}
        width={V.width}
        height={V.height}
      />
      <Composition
        id="ChaosStory"
        component={ChaosStory}
        durationInFrames={SEC(60)}
        fps={FPS}
        width={V.width}
        height={V.height}
      />
      <Composition
        id="TimeRecovery"
        component={TimeRecovery}
        durationInFrames={SEC(60)}
        fps={FPS}
        width={V.width}
        height={V.height}
      />
    </>
  );
};
