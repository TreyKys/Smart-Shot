import {Config} from '@remotion/cli/config';

Config.setVideoImageFormat('jpeg');
Config.setPixelFormat('yuv420p');
Config.setCodec('h264');
// x264 CRF: lower is higher quality. 18 is visually lossless for social; the
// default (23) shows compression on the flat gradient backgrounds these ads
// use, so it's worth the file-size trade to bump it.
Config.setCrf(18);
Config.setConcurrency(null); // auto-detect available cores
