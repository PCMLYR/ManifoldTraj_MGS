# MGS: Manifold-based task-fMRI activation mapping

Official implementation of MICCAI'2026 paper “Geometry-Aware Manifold Trajectory Modelingfor Task fMRI Activation Mapping”

This repository contains MATLAB code for computing **MGS** maps from Human Connectome Project (HCP) task fMRI data.

## Overview

The main analysis script is:

```matlab
Run_TemporalManifold_MGS.m
```
## Data requirements

The code assumes HCP-style preprocessed task/rest fMRI data in CIFTI format. Data are not included in this repository.

The default scripts expect the following root directory pattern:

```text
[YOUR_HCP_ROOT]/HCP_100_unrelated_2025/
├── HCP100_task/
│   └── <SUBJECT_ID>/MNINonLinear/Results/
│       ├── tfMRI_MOTOR_LR/
│       ├── tfMRI_MOTOR_RL/
│       ├── tfMRI_EMOTION_LR/
│       └── tfMRI_EMOTION_RL/
├── HCP100_rest/
│   └── <SUBJECT_ID>/MNINonLinear/Results/
│       ├── rfMRI_REST1_LR/
│       └── rfMRI_REST1_RL/
└── HCP100_structual/
    └── <SUBJECT_ID>/MNINonLinear/fsaverage_LR32k/
        ├── <SUBJECT_ID>.L.midthickness_MSMAll.32k_fs_LR.surf.gii
        └── <SUBJECT_ID>.R.midthickness_MSMAll.32k_fs_LR.surf.gii
```

Expected task files include HCP EV text files under each task run, for example:

```text
tfMRI_MOTOR_LR/EVs/lf.txt
tfMRI_MOTOR_LR/EVs/lh.txt
tfMRI_MOTOR_LR/EVs/rf.txt
tfMRI_MOTOR_LR/EVs/rh.txt
tfMRI_MOTOR_LR/EVs/t.txt
tfMRI_EMOTION_LR/EVs/fear.txt
tfMRI_EMOTION_LR/EVs/neut.txt
```

## Software requirements

The code was written in MATLAB and requires the following external packages/tools:

- MATLAB with [Statistics and Machine Learning Toolbox](https://www.mathworks.com/products/statistics.html).
- [SPM12](https://github.com/spm/spm12).
- [Connectome Workbench](https://github.com/Washington-University/workbench), with `wb_command` available from the system shell.
- CIFTI/GIFTI MATLAB I/O utilities, including [cifti-matlab](https://github.com/Washington-University/cifti-matlab) and the [GIfTI MATLAB/Octave library](https://github.com/gllmflndn/gifti).
- [FieldTrip](https://github.com/fieldtrip/fieldtrip) and a NIfTI I/O toolbox, such as [NIFTI_toolbox](https://github.com/mcnablab/NIFTI_toolbox) or an equivalent toolbox providing `load_untouch_nii` and `save_untouch_nii`.
- MATLAB UMAP implementation providing `run_umap`, such as [Uniform Manifold Approximation and Projection (UMAP) for MATLAB](https://www.mathworks.com/matlabcentral/fileexchange/71902-uniform-manifold-approximation-and-projection-umap); the original Python implementation is available at [lmcinnes/umap](https://github.com/lmcinnes/umap).
- [`slanCM`](https://github.com/slandarer/slanColor) colormap function for visualization.

Before running the pipeline, add these packages to the MATLAB path and make sure `wb_command` is available from the system shell.

## Quick start

### 1. Configure paths

Edit the `root_path` variable in the entry scripts:

```matlab
root_path = '[YOUR_HCP_ROOT]/HCP_100_unrelated_2025/';
```

This variable appears in:

```text
Read_TaskBlock.m
Run_TemporalManifold_MGS.m
Run_GLM_Motor.m
Run_GLM_Emotion.m
Run_GLM_toCifti_group.m
```

Then start MATLAB from the repository root and add local utilities:

```matlab
cd /path/to/MGS
Addpath
```

### 2. Inspect task timing blocks

Use `Read_TaskBlock.m` to read HCP EV files and generate task timing visualizations:

```matlab
Read_TaskBlock
```

This produces task color masks such as:

```text
color_MOTOR_LR.mat
color_MOTOR_LR.jpg
```

### 3. Run the MGS pipeline

Configure the task inside `Run_TemporalManifold_MGS.m`.

## Main outputs

The MGS pipeline writes intermediate and final outputs to the following folders:

```text
result_meanTC/                     # Group-averaged task/rest CIFTI time courses
result_reductions/<TASK>/          # UMAP coordinates and cluster labels
result_reductions/<TASK>/reductions.mat

data_preread/                      # Cached subject-level task/rest time courses
result_MGS_sub/<TASK>/             # Subject-level MGS CIFTI files
result_MGS/<TASK>/                 # Group-level MGS statistical maps
```

The most important group-level outputs are:

```text
result_MGS/<TASK>/MGS_group_z.dtseries.nii
result_MGS/<TASK>/MGS_group_z_sig.dtseries.nii
```

`MGS_group_z.dtseries.nii` stores the signed Wilcoxon z-statistics.  
`MGS_group_z_sig.dtseries.nii` stores the FDR-thresholded signed z-statistics.

## Optional GLM baseline

The repository also includes SPM12 GLM scripts for comparison.

Run first-level GLM:

```matlab
Run_GLM_Motor
% or
Run_GLM_Emotion
```

Then run group-level GLM and convert the resulting volume statistics back to CIFTI surface format:

```matlab
Run_GLM_toCifti_group
```

The GLM scripts create outputs under:

```text
result_GLM/<TASK>/1st_level/
result_GLM/<TASK>/2nd_level/
```

The GLM scripts use fixed HCP task timings and SPM's canonical HRF basis. MOTOR produces five movement contrasts: tongue, left hand, right hand, left foot, and right foot. EMOTION produces face and shape contrasts.

## Citation
```bib
@inproceedings{li2026geometry,
  title={Geometry-Aware Manifold Trajectory Modeling for Task fMRI Activation Mapping},
  author={Li, Yueran and Chang, Xinle and Yang, Yang and Zhao, Yu and Su, Jingyong},
  booktitle={International Conference on Medical Image Computing and Computer-Assisted Intervention},
  pages={222--231},
  year={2026},
  organization={Springer}
}
```
