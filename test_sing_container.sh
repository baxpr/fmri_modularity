
singularity \
run \
--bind INPUTS:/INPUTS \
--bind OUTPUTS:/OUTPUTS \
baxpr-fmri_modularity-master-v1.0.0.simg \
magick_path /usr/bin \
community_file eight_networks_tcorr05_2level_43_0840rois_3study.csv \
connmat_file ../INPUTS/connmat.csv \
roiinfo_file ../INPUTS/roiinfo.csv \
roi_file ../INPUTS/roi.nii.gz \
project UNK_PROJ \
subject UNK_SUBJ \
session UNK_SESS \
scan Proj-x-Subj-x-Sess-x-UNK_SCAN-x-Proc \
out_dir /OUTPUTS
