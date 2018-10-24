function [ ...
	Qspec_mst,Nspec_mst,Mspec_mst, ...
	Qopt_mst,Nopt_mst,Mopt_mst, ...
	Qspec_asym,Nspec_asym,Mspec_asym, ...
	Qopt_asym,Nopt_asym,Mopt_asym, ...
	Qoptdefault_mst,Noptdefault_mst,Moptdefault_mst, ...
	Qoptdefault_asym,Noptdefault_asym,Moptdefault_asym, ...
	nTotalROIs,nRetainedROIs,RetainedROIs ...
	] =  ...
	modularity_all(W,M0)

% Compute several types of modularity for a given community structure.


%% Verify and adjust the input correlation matrix
%
% From the BCT documentation:
%
%     "The network matrices may be binary or weighted, directed or
%     undirected. Each function specifies the network type for which it is
%     suitable."
%
%     "The network matrices should not contain self-self
%     connections. In other words, all values on the main diagonal of these
%     matrices should be set to 0."
%
% Additionally, we are working with correlation matrices only, i.e. [-1,1]

% Symmetrize and check how much we changed it
dW = W - W.';
if any(dW(:)~=0)
	fprintf('Symmetrizing correlation matrix. Max asym = %0.2e\n', ...
		max(abs(dW(:))));
	if max(abs(dW(:))) > 1e-6
		warning('Check correlation matrix. Asymmetry unexpectedly high')
	end
end
W = (W + W.') / 2;

% Check for wrong values
if any( abs(W(:)) > 1.0 )
	error('Not a correlation matrix: found value out of range [-1,1]')
end

% Set diagonal to zero in accord with BCT expectations
W = W - diag(diag(W));


%% Verify the community vector
if any( size(M0) ~= [size(W,1) 1] )
	error('M0 must be a column vector the length of W')
end

% Report on number of nodes, number of communities, number of left-out
% (nan or 0) nodes.
RetainedROIs = ~(isnan(M0) | M0==0);
Mset = M0(RetainedROIs);
Mset = unique(Mset);
nTotalROIs = length(M0);
nRetainedROIs = sum(RetainedROIs);

fprintf('\nA priori community structure:\n');
fprintf('   Nodes     total: %d\n',nTotalROIs);
fprintf('         discarded: %d\n',sum(~RetainedROIs));
fprintf('          retained: %d\n',nRetainedROIs);
fprintf('   Communities (%d):\n',length(Mset))
fprintf('      ');
for u = 1:length(Mset)-1
	fprintf('%d,',Mset(u));
end
fprintf('%d\n',Mset(u+1));


%% Drop unwanted nodes
W = W(RetainedROIs,RetainedROIs);
M0 = M0(RetainedROIs);


%% Minimum spanning tree
[ ...
	Qspec_mst,Nspec_mst,Mspec_mst, ...
	Qopt_mst,Nopt_mst,Mopt_mst,...
	Qoptdefault_mst,Noptdefault_mst,Moptdefault_mst ...
	] = ...
	modularity_minspantree(W,M0);


%% Asymmetric no-threshold method
[ ...
	Qspec_asym,Nspec_asym,Mspec_asym, ...
	Qopt_asym,Nopt_asym,Mopt_asym,...
	Qoptdefault_asym,Noptdefault_asym,Moptdefault_asym ...
	] = ...
	modularity_asym(W,M0);

