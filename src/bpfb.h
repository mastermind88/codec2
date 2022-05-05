#define BPFB_N 101
#define HPF200_N 101

float bpfb[]={
  0.003795,
  0.006827,
  0.002261,
  0.002523,
  0.005758,
  -0.000264,
  -0.000674,
  0.003113,
  -0.004144,
  -0.004923,
  0.000043,
  -0.008017,
  -0.008711,
  -0.001802,
  -0.010210,
  -0.010428,
  -0.000899,
  -0.009413,
  -0.009072,
  0.003469,
  -0.005335,
  -0.004828,
  0.010724,
  0.000941,
  0.000708,
  0.018957,
  0.007084,
  0.004825,
  0.025418,
  0.010147,
  0.004452,
  0.027434,
  0.007550,
  -0.002861,
  0.023483,
  -0.001944,
  -0.018138,
  0.014122,
  -0.017583,
  -0.040768,
  0.002598,
  -0.036604,
  -0.069541,
  -0.004273,
  -0.054876,
  -0.107289,
  0.010068,
  -0.068052,
  -0.200119,
  0.207287,
  0.597150,
  0.207287,
  -0.200119,
  -0.068052,
  0.010068,
  -0.107289,
  -0.054876,
  -0.004273,
  -0.069541,
  -0.036604,
  0.002598,
  -0.040768,
  -0.017583,
  0.014122,
  -0.018138,
  -0.001944,
  0.023483,
  -0.002861,
  0.007550,
  0.027434,
  0.004452,
  0.010147,
  0.025418,
  0.004825,
  0.007084,
  0.018957,
  0.000708,
  0.000941,
  0.010724,
  -0.004828,
  -0.005335,
  0.003469,
  -0.009072,
  -0.009413,
  -0.000899,
  -0.010428,
  -0.010210,
  -0.001802,
  -0.008711,
  -0.008017,
  0.000043,
  -0.004923,
  -0.004144,
  0.003113,
  -0.000674,
  -0.000264,
  0.005758,
  0.002523,
  0.002261,
  0.006827,
  0.003795
};

/* 
   -30dB at 100 Hz, -6dB at 200 Hz, 0dB at 300 Hz
   octave> b = fir1(100, 200/4000, "high"); h=freqz(b,1,4000); HdB=20*log10(abs(h)); figure(1); clf; plot(HdB(1:600)); grid 
*/
float hpf200[] = {
 -0.000499868,
 -0.000497679,
 -0.000493493,
 -0.000484583,
 -0.000466851,
 -0.000435008,
 -0.000382842,
 -0.000303593,
 -0.000190401,
 -0.000036813,
  0.000162659,
  0.000411977,
  0.000713017,
  0.001065054,
  0.001464319,
  0.001903637,
  0.002372201,
  0.002855470,
  0.003335225,
  0.003789793,
  0.004194432,
  0.004521877,
  0.004743044,
  0.004827864,
  0.004746231,
  0.004469029,
  0.003969209,
  0.003222877,
  0.002210351,
  0.000917149,
 -0.000665129,
 -0.002538068,
 -0.004695880,
 -0.007125056,
 -0.009804244,
 -0.012704368,
 -0.015788994,
 -0.019014941,
 -0.022333126,
 -0.025689617,
 -0.029026873,
 -0.032285137,
 -0.035403931,
 -0.038323614,
 -0.040986961,
 -0.043340698,
 -0.045336961,
 -0.046934610,
 -0.048100383,
 -0.048809826,
  0.951452731,
 -0.048809826,
 -0.048100383,
 -0.046934610,
 -0.045336961,
 -0.043340698,
 -0.040986961,
 -0.038323614,
 -0.035403931,
 -0.032285137,
 -0.029026873,
 -0.025689617,
 -0.022333126,
 -0.019014941,
 -0.015788994,
 -0.012704368,
 -0.009804244,
 -0.007125056,
 -0.004695880,
 -0.002538068,
 -0.000665129,
  0.000917149,
  0.002210351,
  0.003222877,
  0.003969209,
  0.004469029,
  0.004746231,
  0.004827864,
  0.004743044,
  0.004521877,
  0.004194432,
  0.003789793,
  0.003335225,
  0.002855470,
  0.002372201,
  0.001903637,
  0.001464319,
  0.001065054,
  0.000713017,
  0.000411977,
  0.000162659,
 -0.000036813,
 -0.000190401,
 -0.000303593,
 -0.000382842,
 -0.000435008,
 -0.000466851,
 -0.000484583,
 -0.000493493,
 -0.000497679,
 -0.000499868
};
