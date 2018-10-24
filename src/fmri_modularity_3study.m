function fmri_modularity_3study

% Imagemagick
magick_path = '/usr/bin';

% Specific community file
community_file = which('eight_networks_tcorr05_2level_43_0840rois_3study.csv');

% Inputs
in_path = '/INPUTS';
connmat_file = fullfile(in_path,'connmat.csv');
roiinfo_file = fullfile(in_path,'roiinfo.csv');
roi_file = fullfile(in_path,'roi.nii.gz');

fid = fopen([in_path '/project'],'rt');
project = fscanf(fid,'%s',[1 1]);
fclose(fid);

fid = fopen([in_path '/subject'],'rt');
subject = fscanf(fid,'%s',[1 1]);
fclose(fid);

fid = fopen([in_path '/session'],'rt');
session = fscanf(fid,'%s',[1 1]);
fclose(fid);

fid = fopen([in_path '/scan'],'rt');
scan = fscanf(fid,'%s',[1 1]);
fclose(fid);

% Output directory
out_path = '/OUTPUTS';


%% Copy some inputs to output location
copyfile(connmat_file,fullfile(out_path,'connectivity_matrix.csv'));
copyfile(community_file,fullfile(out_path,'communities.csv'));
copyfile(roi_file,fullfile(out_path,'rroi.nii.gz'));

% Now unzip the ROI image so we can use it for the PDF
system(['gunzip -fk ' roi_file]);
roi_file = roi_file(1:end-3);

% And we'll use an atlas for the underlay image. But we need to resample to
% the ROI file geometry
atlas_file = [spm('dir') '/canonical/avg152T1.nii'];
copyfile(atlas_file,out_path);
atlas_file = fullfile(out_path,'avg152T1.nii');
flags = struct( ...
        'mask',true, ...
        'mean',false, ...
        'interp',1, ...
        'which',1, ...
        'wrap',[0 0 0], ...
        'prefix','r' ...
        );
spm_reslice({roi_file; atlas_file},flags);
[~,n,e] = fileparts(atlas_file);
underlay_file = fullfile(out_path,['r' n e]);


%% Compute modularities

% Read community file
C = readtable(community_file);

% Read connectivity matrix
R = readtable(connmat_file,'ReadRowNames',true);
R = table2array(R);

% Make temporary files for make_pdf
pdf_community_file = community_file;
pdf_connmat_file = [out_path '/temp_connmat.csv'];
save(pdf_connmat_file,'R','-ascii');

% We are assuming the community file and the connectivity matrix are for
% the same ROIs, in the same order. We can do a bit of a check here between
% the community file (source is this spider's param file) and the ROI info
% list (source is the conncalc spider's output):
roiinfo = readtable(roiinfo_file);
if ~isequal(roiinfo.Label,C.ROI_Image_Label)
	error('Mismatch between community file and ROI list')
end

% Compute modularities for each specified community
%
% Need to make a table of community assignments. First column is ROI label,
% remaining columns named Community_specMST / Community_optMST / etc. ROI
% subset varies for each community so we need to use the full list,
% inserted NaN for leftout ROIs.
warning('off','MATLAB:table:RowsAddedExistingVars');
results = table( cell(0,1),'VariableNames',{'Community'} );
for c = 1:size(C,2)-1
	cname = C.Properties.VariableNames{c+1};
	fprintf('Computing for community %s\n',cname);
	M0 = C{:,cname};
	
	[ ...
		Qspec_mst,Nspec_mst,Mspec_mst, ...
		Qopt_mst,Nopt_mst,Mopt_mst, ...
		Qspec_asym,Nspec_asym,Mspec_asym, ...
		Qopt_asym,Nopt_asym,Mopt_asym, ...
		Qoptdefault_mst,Noptdefault_mst,Moptdefault_mst, ...
		Qoptdefault_asym,Noptdefault_asym,Moptdefault_asym, ...
		nTotalROIs,nRetainedROIs,RetainedROIs ...
		] = modularity_all(R,M0);
	
	results.Community{c,1} = cname;
	results.Qspec_mst(c,1) = Qspec_mst;
	results.Nspec_mst(c,1) = Nspec_mst;
	results.Qopt_mst(c,1) = Qopt_mst;
	results.Nopt_mst(c,1) = Nopt_mst;
	results.Qoptdefault_mst(c,1) = Qoptdefault_mst;
	results.Noptdefault_mst(c,1) = Noptdefault_mst;
	results.Qspec_asym(c,1) = Qspec_asym;
	results.Nspec_asym(c,1) = Nspec_asym;
	results.Qopt_asym(c,1) = Qopt_asym;
	results.Nopt_asym(c,1) = Nopt_asym;
	results.Qoptdefault_asym(c,1) = Qoptdefault_asym;
	results.Noptdefault_asym(c,1) = Noptdefault_asym;
	results.TotalROIs(c,1) = nTotalROIs;
	results.RetainedROIs(c,1) = nRetainedROIs;
	
	if c==1
		resultsM = table(roiinfo.Label,M0, ...
			'VariableNames',{'Label','M0'});
	end
	resultsM{:,[cname '_specMST']} = nan; 
	resultsM{RetainedROIs,[cname '_specMST']} = Mspec_mst;
	
	resultsM{:,[cname '_specAsym']} = nan;
	resultsM{RetainedROIs,[cname '_specAsym']} = Mspec_asym;

	resultsM{:,[cname '_optMST']} = nan;
	resultsM{RetainedROIs,[cname '_optMST']} = Mopt_mst; 

	resultsM{:,[cname '_optAsym']} = nan; 
	resultsM{RetainedROIs,[cname '_optAsym']} = Mopt_asym; 

	resultsM{:,[cname '_optdefaultMST']} = nan; 
	resultsM{RetainedROIs,[cname '_optdefaultMST']} = Moptdefault_mst; 

	resultsM{:,[cname '_optdefaultAsym']} = nan; 
	resultsM{RetainedROIs,[cname '_optdefaultAsym']} = Moptdefault_asym; 
		
end

writetable(results,fullfile(out_path,'modularities.csv'));
writetable(resultsM,fullfile(out_path,'community_assignments.csv'));


%% Generate PDF
make_pdf( ...
	out_path, ...
	magick_path, ...
	underlay_file, ...
	roi_file, ...
	pdf_connmat_file, ...
	pdf_community_file, ...
	results, ...
	project, ...
	subject, ...
	session, ...
	scan ...
	);


%% Clean up
delete([out_path '/*.png']);
delete([out_path '/avg152T1.nii']);
delete([out_path '/ravg152T1.nii']);
delete([out_path '/temp_connmat.csv']);


%% Exit
exit


