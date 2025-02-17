function [ x,s,cost ] = mcsleep(y, H, HT, param)
% function [ x,s,cost ] = mcsleep(y, H, HT, param)
%
% This function separates transients and oscillations in multichannel EEG
% using the proposed McSleep algorithm. The algorithm assumes that the
% transients are sparse piecewise constant with a lowpass additive
% component. The consecutive blocks formed from the oscillatory component
% are assumed to be of low-rank. Please see the citation information below
% for details and usage rights. 
%
% 
% Input :
%        y - Multichannel sleep EEG
%        H - Forward transform. H(y) results in overlapping blocks of user
%            defined length from the signal Y.
%        HT - Adjoint (Inverse) transform. HT(c) returns the multichannel
%        signal formed from the coefficient array c. HT(H(y)) = y. 
%        param - parameters struct. Members are as below
%                lam1 - sparsity of transient component
%                lam2 - sparsity of derivative of transient component
%                lam3 - rank of coefficient array c. 
%                K - length of overlapping blocks
%                mu - scaled Lagrangian step size parameter
%                O - overlap between consecutive blocks. (default = 50%)
%                Nit - number of iterations
% 
% Output:
%        x - Estimated transient component (may contain a lowpass
%            component)
%        s - Estiamted oscillatory component
%        cost - Cost function history
%
% Contact: Ankit Parekh (ankit.parekh@nyu.edu)
% Last Edit: 1/19/2017. 
%
% Copyright (c) 2017. Ankit Parekh 
% 
% Please cite as: Multichannel Sleep Spindle Detection using Sparse Low-Rank Optimization 
% A. Parekh, I. W. Selesnick, R. S. Osorio, A. W. Varga, D. M. Rapoport and I. Ayappa 
% bioRxiv Preprint 2017, doi: https://doi.org/10.1101/104414

cost = zeros(param.Nit,1);
[m,n] = size(y);
x = zeros(m,n); 
u = x;
v = H(x,param.K, param.O);
d1 = x;
d2 = v;
Hy = 1/param.mu * H(y, param.K, param.O);

for i = 1:param.Nit
    
    % Fused Lasso Step
    for j = 1:m
        x(j,:) =soft(tvd(u(j,:) - d1(j,:), n, param.lam2/param.mu), param.lam1/param.mu);
    end
    
    % Singular Value Thresholding step
    c = SVT_Blocks(v-d2,param.lam3/param.mu);%1)
           
    
    % Least-Squares step
    g1 = 1/param.mu * y + x + d1;
    g2 = Hy + c + d2;
    HTg2 = HT(g2, param.K, param.O);
    u = g1 - 1/(param.mu + 2) * (g1 + HTg2);
    v = g2 - 1/(param.mu + 2) * H(g1 + HTg2,param.K,param.O);
    
    % Update auxillary variables                                                                                                                                                                                                          
    d1 = d1 - (u-x);                                                                                       
    d2 = d2 - (v-c);
    
    % Calculate cost
    if param.calculateCost
        cost(i) = 0.5 * norm(y - (x + HT(c,param.K, param.O)), 'fro')^2 + ...
             param.lam1 * norm(x,1) + ...
             param.lam2 * norm(diff(x,2),1) + ...
             param.lam3 * sum_of_nuc_norm(c);
    end
end

% Return oscillatory component calculated using estimated coefficients
s = HT(c,param.K, param.O);


end
