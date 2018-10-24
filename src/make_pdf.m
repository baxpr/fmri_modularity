function make_pdf( ...
	out_path, ...
	magick_path, ...
	wmean_file, ...
	roi_file, ...
	connmat_file, ...
	community_file, ...
	results, ...
	project, ...
	subject, ...
	session, ...
	scan ...
	)

%% PDF

% Figure out screen size so the figure will fit
ss = get(0,'screensize');
ssw = ss(3);
ssh = ss(4);
ratio = 8.5/11;
if ssw/ssh >= ratio
	dh = ssh;
	dw = ssh * ratio;
else
	dw = ssw;
	dh = ssw / ratio;
end

% Page 1, ROI list
f1 = openfig(which('output_figure_1.fig'),'new');
set(f1,'Units','pixels','Position',[0 0 dw dh]);
h1 = guihandles(f1);

% Top line info
set(h1.text_title, 'String', ...
	[project ' ' subject ' ' session ' ' scan] );

% ROIs overlaid on mean func
Yfunc = spm_read_vols(spm_vol(wmean_file));
Yroi = spm_read_vols(spm_vol(roi_file));
roi_labels = unique(Yroi(:));
Yroi(Yroi(:)==0) = nan;
roi_labels = roi_labels(roi_labels~=0);
m = length(roi_labels);

I = squeeze( Yfunc(:,:,round(size(Yfunc,3)/2)) );
R = squeeze(  Yroi(:,:,round(size( Yroi,3)/2)) );
image_overlay(h1.ax_axi,I,R,m)

I = squeeze( Yfunc(:,round(size(Yfunc,2)/2),:) );
R = squeeze(  Yroi(:,round(size( Yroi,2)/2),:) );
image_overlay(h1.ax_cor,I,R,m)

I = squeeze( Yfunc(round(size(Yfunc,1)/2),:,:) );
R = squeeze(  Yroi(round(size( Yroi,1)/2),:,:) );
image_overlay(h1.ax_sag,I,R,m)

% Info text
[~,n,e] = fileparts(roi_file);
set(h1.text_info, 'String', ...
	sprintf( ...
	['ROI file: %s\n' ...
	'# ROIs: %d\n'], ...
	[n e], m) ...
	);

% Print to file
clear pngfile
npages = 1;
pngfile{npages} = fullfile(out_path,sprintf('out%d.png',npages));
print(f1,'-dpng','-r600',pngfile{npages});
close(f1)


% Page 2+, modularity reports

% Custom colormap:
%    1       21       41        61      81
%    cyan    blue    (black)   red     yellow
%    0 1 1   0 0 1   (0 0 0)   1 0 0   1 1 0
cmap = zeros(50,3);
cmap(1:21,2) = 1:-1/20:0;
cmap(1:21,3) = 1;
cmap(21:41,3) = 1:-1/20:0;
cmap(41:61,1) = 0:1/20:1;
cmap(61:81,2) = 0:1/20:1;
cmap(61:81,1) = 1;

R = load(connmat_file);
C = readtable(community_file);

for s = 1:height(results)
	
	M = C{:,results.Community{s}};
	keeps = M>0;
	thisM = M(keeps);
	thisR = R(keeps,keeps);
	
	f = openfig(which('output_figure_2.fig'),'new');
	set(f,'Units','pixels','Position',[0 0 dw dh]);
	h = guihandles(f);
	
	[~,ind] = sort(thisM);
	imshow(thisR(ind,ind),[-1,1],'Parent',h.ax_adjacency,'Colormap',cmap)
	colorbar(h.ax_adjacency)
	axis(h.ax_adjacency,'on')
	set(h.ax_adjacency,'XTick',[],'Ytick',[])
	title(h.ax_adjacency,'Correlation matrix')
	
	set(h.text_title, 'String', ...
		sprintf( ...
		'%s %s %s %s\nCommunity structure %s', ...
		project,subject,session,scan,results.Community{s}) ...
		);
	
	outstr = sprintf( [ ...
		'Qspec_mst      %0.3f\n' ...
		'Nspec_mst      %d\n' ...
		'Qopt_mst       %0.3f\n' ...
		'Nopt_mst       %d\n' ...
		'Qspec_asym     %0.3f\n' ...
		'Nspec_asym     %d\n' ...
		'Qopt_asym      %0.3f\n' ...
		'Nopt_asym      %d\n' ...
		'TotalROIs      %d\n' ...
		'RetainedROIs   %d\n' ...
		], ...
		results.Qspec_mst(s), ...
		results.Nspec_mst(s), ...
		results.Qopt_mst(s), ...
		results.Nopt_mst(s), ...
		results.Qspec_asym(s), ...
		results.Nspec_asym(s), ...
		results.Qopt_asym(s), ...
		results.Nopt_asym(s), ...
		results.TotalROIs(s), ...
		results.RetainedROIs(s) ...
		);
	
	set(h.text_community, 'String', ...
		outstr);
	set(h.text_community, 'FontName', ...
		get(0,'FixedWidthFontName'));
	
	npages = npages + 1;
	pngfile{npages} = fullfile(out_path,sprintf('out%d.png',npages));
	print(f,'-dpng','-r600',pngfile{npages});
	close(f)
	
end


% Combine PNGs to PDF
pdffile = fullfile(out_path,'fmri_modularity.pdf');
cmdstr = [];
for p = 1:npages
	cmdstr = [cmdstr pngfile{p} ' '];
end
[status,msg] = system([magick_path '/convert ' cmdstr pdffile]);
if status~=0
	warning('Could not cleanly create PDF file from PNG.');
	disp(msg);
end
