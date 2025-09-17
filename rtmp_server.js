const NodeMediaServer = require('node-media-server');

const config = {
  rtmp: {
    port: 1935,
    chunk_size: 60000,
    gop_cache: true,
    ping: 30,
    ping_timeout: 60
  },
  http: {
    port: 8001,
    mediaroot: './media',
    allow_origin: '*'
  },
  trans: {
    ffmpeg: process.env.FFMPEG_PATH || 'ffmpeg',
    tasks: [
      {
        app: 'live',
        hls: true,
        hlsFlags: '[hls_time=2:hls_list_size=3:hls_flags=delete_segments]',
        mp4: true,
        mp4Flags: '[movflags=faststart]'
      }
    ]
  }
};

const nms = new NodeMediaServer(config);
nms.run();

console.log('RTMP server started on port 1935');
console.log('HLS available at http://localhost:8001/live/stream.m3u8');
