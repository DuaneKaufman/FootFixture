# AnalyzeMP4_FromScanner

Suite of MATLAB files that will:
1) reads in a raw scanner video files (MP4) left and right
2) slices out the ultrasound video in the middle of raw video
3) scans video for periods of low-change and high-change
4) uses timestamps to sample video during low-change periods
5) attempts to find/label both skin boundary and bone boundary
6) stiches together left and right video
7) outputs a stacked image of low-change frames, which can be zoomed/panned/measured

To analyze a foot (or phantom, which is processed just like a foot):
outLeftFoot = analyzeFootVideos(raw_DAK_LL_f_id, raw_DAK_RL_f_id);

where outLeftFoot is a structure with relevant data gleaned from scanner video

raw_DAK_LL_f_id is a string path to raw video file (MP4) from scanner on left side of foot

raw_DAK_RL_f_id is a string path to raw video file (MP4) from scanner on left side of foot

Stacked output image set can be interrogated - x-axis is in mm
