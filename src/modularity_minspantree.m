function [ ...
	Qspec,Nspec,Mspec, ...
	Qopt,Nopt,Mopt, ...
	Qopt_default,Nopt_default,Mopt_default ...
	] = ...
	modularity_minspantree(W,M0)

% Find minimum spanning tree of a connectivity matrix and compute
% its modularity with a specific community structure.
%
% Method overview:
% https://dx.doi.org/10.1016/j.neuroimage.2014.10.015
%    Tewarie P, van Dellen E, Hillebrand A, Stam CJ. The minimum spanning
%    tree: an unbiased method for brain network analysis. Neuroimage. 2015
%    Jan 1;104:177-88. doi: 10.1016/j.neuroimage.2014.10.015. Epub 2014 Oct
%    16. PubMed PMID: 25451472.
%
% Earlier example:
% https://dx.doi.org/10.3389/fnsys.2010.00147
%    Alexander-Bloch AF, Gogtay N, Meunier D, Birn R, Clasen L, Lalonde F,
%    Lenroot R, Giedd J, Bullmore ET. Disrupted modularity and local
%    connectivity of brain functional networks in childhood-onset
%    schizophrenia. Front Syst Neurosci. 2010 Oct 8;4:147. doi:
%    10.3389/fnsys.2010.00147. eCollection 2010. PubMed PMID: 21031030;
%    PubMed Central PMCID: PMC2965020.
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


%% Minimum spanning tree

% We actually want the min span tree of the distance matrix. Diagonal of
% the distance matrix should be zero so we have to set that also.
D = 1 - W;
D = D - diag(diag(D));

% Make graph object
G = graph(D,'OmitSelfLoops');

% Minimum spanning tree
mstG = minspantree(G);

% Reconstruct correlation matrix of MST by setting the retained edge
% weights to the correlation value. Leave diagonal at zero in accord with
% BCT convention.
nn = numnodes(mstG);
[s,t] = findedge(mstG);
mstW = sparse(s,t,1-mstG.Edges.Weight,nn,nn);
mstW = full( mstW + mstW.' - diag(diag(mstW)) );

% Compute modularity for specified structure using the asym method
if any(mstW(:)<0)
	warning('Negative values in min span tree. Using asym method');
end

[Qspec,Nspec,Mspec, ...
	Qopt,Nopt,Mopt, ...
	Qopt_default,Nopt_default,Mopt_default ...
	] = modularity_asym(W,M0);


