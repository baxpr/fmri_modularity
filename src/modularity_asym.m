function [ ...
	Qspec,Nspec,Mspec, ...
	Qopt,Nopt,Mopt, ...
	Qopt_default,Nopt_default,Mopt_default ...
	] = ...
	modularity_asym(W,M0)

% Compute modularity of a graph with a specific community structure using
% the threshold-independent 'negative_asym' method of
%
%     https://www.ncbi.nlm.nih.gov/pubmed/21459148
%     https://doi.org/10.1016/j.neuroimage.2011.03.069
%
%     Rubinov M, Sporns O. Weight-conserving characterization of complex
%     functional brain networks. Neuroimage. 2011 Jun 15;56(4):2068-79.
%     doi: 10.1016/j.neuroimage.2011.03.069. Epub 2011 Apr 1. PubMed PMID:
%     21459148.
%
% Code adapted from the community_louvain.m function in the Brain
% Connectivity Toolbox 2017-01-05 release:
%
%     https://www.nitrc.org/projects/bct/
%     http://dx.doi.org/10.1016/j.neuroimage.2009.10.003
%
%     Complex network measures of brain connectivity: Uses and
%     interpretations. Rubinov M, Sporns O (2010) NeuroImage 52:1059-69.
%
%
% Inputs, following BCT notation:
%
%     W     Correlation matrix
%     M0    Community structure


%% Fix the gamma resolution parameter to standard value
gamma = 1;


%% Verify the input correlation matrix
dW = W - W.';
if any( dW(:) ~= 0 )
	error('Weight matrix not symmetric');
end
if any( abs(W(:)) > 1.0 )
	error('Weight value out of range [-1,1]');
end
if any( diag(W) ~= 0 )
	error('Weight matrix diagonals must be zero');
end


%% Verify the community vector
if any( size(M0) ~= [size(W,1) 1] )
	error('M0 must be a column vector the length of W')
end
if any( isnan(M0) | any(M0==0) )
	error('NAN or 0 found in community vector');
end


%% Compute modularity

% Modularity matrix for positive weights
W0 = W .* (W>0);                                  % positive wts matrix
s0 = sum(sum(W0));                                % wt of positive links
B0 = W0 - gamma * (sum(W0,2)*sum(W0,1)) / s0;     % positive modularity

% Modularity matrix for negative weights
W1 = -W .* (W<0);                                  % negative wts matrix
s1 = sum(sum(W1));                                 % wt of negative links
if s1                                              % negative modularity
	B1 = W1 - gamma * (sum(W1,2)*sum(W1,1)) / s1;
else
	B1 = 0;
end

% Combine positive and negative portions into the 'asym' modularity matrix
% and symmetrize it
B = B0/s0 - B1/(s0+s1);
B = (B + B.') / 2;

% Compute modularity by summing the terms of B from node pairs that are in
% the same community. This step relies on having set the diagonal of W to
% zero as done above.
Qspec = sum( B(bsxfun(@eq,M0,M0.')) );
Nspec = length(unique(M0));
Mspec = M0;

% Compute optimal modularity 
[Mopt,Qopt] = community_louvain(W,gamma,M0,'negative_asym');
Nopt = length(unique(Mopt));

% Optimal without structure initialization
[Mopt_default,Qopt_default] = community_louvain(W,gamma,[],'negative_asym');
Nopt_default = length(unique(Mopt_default));


