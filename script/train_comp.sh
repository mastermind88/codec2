#!/bin/bash -x
# train_comp.sh
# David Rowe April 2022
#
# Training and testing Vector Quantisers (VQ) for Codec 2 newamp1, using
# audio compression

TRAIN=~/Downloads/train.spc
CODEC2_PATH=$HOME/codec2
PATH=$PATH:$CODEC2_PATH/build_linux/src:$CODEC2_PATH/build_linux/misc
K=20
Kst=2
Ken=16

# compressor with AGC
function compress() {
  fullfile=$1
  filename=$(basename -- "$fullfile")
  extension="${filename##*.}"
  filename="${filename%.*}"
  tmp=$(mktemp)
  # SSB filter -> peak after filter (removes F0)
  ch $fullfile - 2>/dev/null | ch - /dev/null 2>$tmp
  peak=$(cat $tmp | grep peak | tr -s ' ' | cut -f3 -d' ')
  gain=$(python -c "gain=32767.0/${peak}; print(\"%3.1f\" % gain)")
  ch $fullfile ${filename}_comp.s16 --gain $gain --clip 16384 2>$tmp
  papr=$(cat $tmp | grep peak | tr -s ' ' | cut -f7 -d' ')
  printf "PAPR: %5.2f\n" $papr
}

# train vanilla, M=4096 single stage
function train_vanilla() {
  fullfile=$TRAIN
  filename=$(basename -- "$fullfile")
  extension="${filename##*.}"
  filename="${filename%.*}"

  c2sim ${fullfile} --rateK --rateK_mean_min 0 --rateK_mean_max 40 --rateKout ${filename}.f32
  vqtrain ${filename}.f32 $K 4096 vq_stage1.f32 -s 1e-3 --st $Kst --en $Ken
}

# train compressed, M=4096 single stage
function train_compressed() {
  fullfile=$TRAIN
  filename=$(basename -- "$fullfile")
  extension="${filename##*.}"
  filename="${filename%.*}"

  # initial step applies SSB filter
  ch ${fullfile} - | ch - ${filename}_comp.s16 --clip 16384 --clipmin 10 --gain 2.0
  c2sim ${filename}_comp.s16 --rateK --rateK_mean_min 10 --rateK_mean_max 40 --rateKout ${filename}_comp.f32
  vqtrain ${filename}_comp.f32 $K 512 vq_stage1.f32 -s 1e-3 --st $Kst --en $Ken -r stage2_in.f32
  vqtrain stage2_in.f32 $K 512 vq_stage2.f32 -s 1e-3 --st $Kst --en $Ken -r stage3_in.f32
  vqtrain stage3_in.f32 $K 512 vq_stage3.f32 -s 1e-3 --st $Kst --en $Ken
}

# train 2 stage, M=512, mean removed
function train_2stage() {
  fullfile=$TRAIN
  filename=$(basename -- "$fullfile")
  extension="${filename##*.}"
  filename="${filename%.*}"

  c2sim ${fullfile} --rateK --rateK_mean_min 0 --rateK_mean_max 40--rateKout ${filename}.f32
  vqtrain ${filename}.f32 $K 512 vq_stage1.f32 -s 1e-3 --st $Kst --en $Ken -r stage2_in.f32
  vqtrain stage2_in.f32 $K 512 vq_stage2.f32 -s 1e-3 --st $Kst --en $Ken -r stage3_in.f32
  cat ${filename}.f32 | vq_mbest --st $Kst --en $Ken -k $K -q vq_stage1.f32,vq_stage2.f32 --mbest 5 > /dev/null
}

function listen_compressed() {
  fullfile=$1
  filename=$(basename -- "$fullfile")
  extension="${filename##*.}"
  filename="${filename%.*}"

  o=agc_ssb_comp
  mkdir -p $o
  compress ${fullfile}
  c2sim ${filename}_comp.s16 --rateK --rateK_mean_min 10 --rateK_mean_max 40 --rateKout ${filename}.f32 \
        --phase0 --postfilter -o - | sox -t .s16 -r 8000 -c 1 - ${o}/${filename}_ratek.wav
  cat ${filename}.f32 | vq_mbest --st $Kst --en $Ken -k $K -q vq_stage1.f32 > ${filename}_test.f32
  c2sim ${filename}_comp.s16 --rateK --rateK_mean_min 10 --rateK_mean_max 40 --rateKin ${filename}_test.f32  \
        --phase0 --postfilter -o - | sox -t .s16 -r 8000 -c 1 - ${o}/${filename}_comp_vq.wav
  cat ${filename}.f32 | vq_mbest --st $Kst --en $Ken -k $K -q vq_stage1.f32,vq_stage2.f32 --mbest 5 \
      > ${filename}_test.f32
  c2sim ${filename}_comp.s16 --rateK --rateK_mean_min 10 --rateK_mean_max 40 --rateKin ${filename}_test.f32  \
        --phase0 --postfilter -o - | sox -t .s16 -r 8000 -c 1 - ${o}/${filename}_comp_vq2.wav
  cat ${filename}.f32 | \
      vq_mbest --st $Kst --en $Ken -k $K -q vq_stage1.f32,vq_stage2.f32,vq_stage3.f32 --mbest 5 \
      > ${filename}_test.f32
  c2sim ${filename}_comp.s16 --rateK --rateK_mean_min 10 --rateK_mean_max 40 --rateKin ${filename}_test.f32  \
        --phase0 --postfilter -o - | sox -t .s16 -r 8000 -c 1 - ${o}/${filename}_comp_vq3.wav
  c2sim $fullfile --rateK --newamp1vq \
         --postfilter_newamp1 --phase0 --postfilter -o - | sox -t .s16 -r 8000 -c 1 - ${o}/${filename}_newamp1.wav
}

# Exploring the effect of the postfilter with newamp1 and phase0
#  + listened with headphones
#  + PF improves muffled/clicky but adds tonal artefact and AM modulation
function listen_newamp1() {
  fullfile=$1
  filename=$(basename -- "$fullfile")
  extension="${filename##*.}"
  filename="${filename%.*}"

  o=newamp1_pf
  mkdir -p $o
  c2sim $fullfile --rateK -o - | sox -t .s16 -r 8000 -c 1 - ${o}/${filename}_ratek.wav
  c2sim $fullfile --rateK --phase0 --postfilter -o - \
        | sox -t .s16 -r 8000 -c 1 - ${o}/${filename}_ratek_p0.wav
  c2sim $fullfile --rateK --phase0 --postfilter --postfilter_newamp1 -o - \
        | sox -t .s16 -r 8000 -c 1 - ${o}/${filename}_ratek_p0_pf.wav
  c2sim $fullfile --rateK --newamp1vq -o - | sox -t .s16 -r 8000 -c 1 - ${o}/${filename}_newamp1.wav
  c2sim $fullfile --rateK --newamp1vq --phase0 --postfilter -o - \
        | sox -t .s16 -r 8000 -c 1 - ${o}/${filename}_newamp1_p0.wav
  c2sim $fullfile --rateK --newamp1vq --postfilter_newamp1 --phase0 --postfilter -o - \
        | sox -t .s16 -r 8000 -c 1 - ${o}/${filename}_newamp1_p0_pf.wav
}

function listen_2stage() {
  fullfile=$1
  filename=$(basename -- "$fullfile")
  extension="${filename##*.}"
  filename="${filename%.*}"

  c2sim ${fullfile} --rateK --rateK_mean_min 0 --rateK_mean_max 40 --rateKout ${filename}.f32 \
        --phase0 --postfilter -o - | sox -t .s16 -r 8000 -c 1 - ${filename}_ratek.wav
  cat ${filename}.f32 | vq_mbest --st $Kst --en $Ken -k $K -q vq_stage1.f32 > ${filename}_test.f32
  c2sim ${fullfile} --rateK --rateK_mean_min 0 --rateK_mean_max 40 --rateKin ${filename}_test.f32  \
        --phase0 --postfilter -o - | sox -t .s16 -r 8000 -c 1 - ${filename}_vq.wav
  c2sim ${fullfile} --rateK --rateK_mean_min 0 --rateK_mean_max 40 --rateKin ${filename}_test.f32  \
        --phase0 --postfilter --postfilter_newamp1 -o - | sox -t .s16 -r 8000 -c 1 - ${filename}_vq1.wav
  c2sim $fullfile --rateK --newamp1vq \
         --postfilter_newamp1 --phase0 --postfilter -o - | sox -t .s16 -r 8000 -c 1 - ${filename}_newamp1.wav
}

function run() {
    # choose which function to run here
    train
    # these two samples are inside training database
    listen ~/Downloads/fish_8k.sw
    listen ~/Downloads/cap_8k.sw
    # two samples from outside training database
    listen $CODEC2_PATH/raw/big_dog.raw
    listen $CODEC2_PATH/raw/hts2a.raw
    # these two samples are inside training database, but with LPF at 3400 Hz outside of subset
    listen ~/Downloads/fish_8k_lp.sw
    listen ~/Downloads/cap_8k_lp.sw
}


function comp_test() {
    compress $CODEC2_PATH/raw/vk5qi.raw
    compress $CODEC2_PATH/raw/kristoff.raw
    compress $CODEC2_PATH/raw/big_dog.raw
    compress $CODEC2_PATH/raw/hts2a.raw
    compress ~/Downloads/fish.s16
    compress ~/Downloads/pencil.s16
}

function listen_test() {
    listen $CODEC2_PATH/raw/vk5qi.raw
    listen $CODEC2_PATH/raw/big_dog.raw
    listen $CODEC2_PATH/raw/kristoff.raw
    listen $CODEC2_PATH/raw/hts2a.raw
    listen ~/Downloads/fish.s16
    listen ~/Downloads/pencil.s16
}

function listen_test_2stage() {
    listen_2stage $CODEC2_PATH/raw/big_dog.raw
    #listen_2stage $CODEC2_PATH/raw/hts2a.raw
    #listen_2stage ~/Downloads/fish.s16
    #listen_2stage ~/Downloads/pencil.s16
}
function listen_test_compressed() {
    listen_compressed $CODEC2_PATH/raw/big_dog.raw
    listen_compressed $CODEC2_PATH/raw/hts2a.raw
    listen_compressed ~/Downloads/fish.s16
    listen_compressed ~/Downloads/pencil.s16
    listen_compressed $CODEC2_PATH/raw/kristoff.raw
    listen_compressed $CODEC2_PATH/raw/vk5qi.raw
}
function listen_test_newamp1() {
    listen_newamp1 $CODEC2_PATH/raw/big_dog.raw
    listen_newamp1 $CODEC2_PATH/raw/hts2a.raw
    listen_newamp1 ~/Downloads/fish.s16
    listen_newamp1 ~/Downloads/pencil.s16
    listen_newamp1 $CODEC2_PATH/raw/kristoff.raw
    listen_newamp1 $CODEC2_PATH/raw/vk5qi.raw
}

#train_compressed
#listen_test_compressed
listen_test_newamp1
