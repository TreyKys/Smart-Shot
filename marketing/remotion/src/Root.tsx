import {Composition} from 'remotion';
import {FPS, SEC} from './theme';
import {SearchFrustration} from './ads/SearchFrustration';
import {DuplicateTrap} from './ads/DuplicateTrap';
import {JunkPile} from './ads/JunkPile';
import {MemoryLane} from './ads/MemoryLane';
import {AskInPlainEnglish} from './ads/AskInPlainEnglish';
import {ChaosStory} from './ads/ChaosStory';
import {TheReliableOne} from './ads/TheReliableOne';
import {TimeRecovery} from './ads/TimeRecovery';

// 16:9 landscape (1920x1080) — matches the reference film. The editorial
// split layouts (bold headline beside a card) are inherently landscape.
const L = {width: 1920, height: 1080};
const short = SEC(20);
const long = SEC(60);

export const RemotionRoot: React.FC = () => {
  return (
    <>
      <Composition id="SearchFrustration" component={SearchFrustration} durationInFrames={short} fps={FPS} width={L.width} height={L.height} />
      <Composition id="DuplicateTrap" component={DuplicateTrap} durationInFrames={short} fps={FPS} width={L.width} height={L.height} />
      <Composition id="JunkPile" component={JunkPile} durationInFrames={short} fps={FPS} width={L.width} height={L.height} />
      <Composition id="MemoryLane" component={MemoryLane} durationInFrames={short} fps={FPS} width={L.width} height={L.height} />
      <Composition id="AskInPlainEnglish" component={AskInPlainEnglish} durationInFrames={short} fps={FPS} width={L.width} height={L.height} />
      <Composition id="ChaosStory" component={ChaosStory} durationInFrames={long} fps={FPS} width={L.width} height={L.height} />
      <Composition id="TheReliableOne" component={TheReliableOne} durationInFrames={long} fps={FPS} width={L.width} height={L.height} />
      <Composition id="TimeRecovery" component={TimeRecovery} durationInFrames={long} fps={FPS} width={L.width} height={L.height} />
    </>
  );
};
