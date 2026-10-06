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
import {AllYouNeed} from './ads/AllYouNeed';
import {TheFaceYouRemember} from './ads/TheFaceYouRemember';
import {TheGroupChat} from './ads/TheGroupChat';
import {TheList} from './ads/TheList';

// 16:9 landscape (1920x1080) — the editorial house-style ads live here.
const L = {width: 1920, height: 1080};
// 9:16 vertical — social-feed ads (TheGroupChat, TheList) that parody
// phone surfaces (iMessage, Notes) are shot in portrait for TikTok /
// Reels / Shorts, not in landscape with letterboxing.
const V = {width: 1080, height: 1920};
const short = SEC(20);
const long = SEC(60);
const mid = SEC(45);
const face = SEC(24);
const chat = SEC(25);

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
      <Composition id="AllYouNeed" component={AllYouNeed} durationInFrames={mid} fps={FPS} width={L.width} height={L.height} />
      <Composition id="TheFaceYouRemember" component={TheFaceYouRemember} durationInFrames={face} fps={FPS} width={L.width} height={L.height} />
      <Composition id="TheGroupChat" component={TheGroupChat} durationInFrames={chat} fps={FPS} width={V.width} height={V.height} />
      <Composition id="TheList" component={TheList} durationInFrames={chat} fps={FPS} width={V.width} height={V.height} />
    </>
  );
};
