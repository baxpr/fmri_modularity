% Generate the final ROI list for a specific sample

% List of ROIs to retain for 3study
retain = readtable('roi_retain_3study_787.csv');
retain.Properties.VariableNames{'Label'} = 'ROI_Image_Label';

% Generic ROI table
rois = readtable('eight_networks_tcorr05_2level_43_0840rois.csv');

% Merge
rois = outerjoin(rois,retain(:,{'ROI_Image_Label','Retain'}), ...
	'Keys','ROI_Image_Label','MergeKeys',true);

% Mark dropped ROIs with NaN and save
rois(rois.Retain==0,2:end-1) = {nan};
rois = rois(:,1:end-1);
writetable(rois,'eight_networks_tcorr05_2level_43_0840rois_3study.csv');
