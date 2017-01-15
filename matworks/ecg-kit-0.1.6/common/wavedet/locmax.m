function [MaxPos,MaxVal]=locmax(Y)% locmax  Local maxima.% For a vector Y, locmax(Y) finds the local maxima, excluding endpoints.%% [MaxPos,MaxVal]=locmax(Y) returns the indices of the maximum values in% vector MaxPos and maximum values in vector MaxVal% maxima are located where the following criteria are true:% 1) gradient is zero: 1st order difference is zero% 2) negative curvature: 2nd order difference is less than zeroMaxPos=find(diff(diff(Y)<=0) & diff(Y,2)<0)+1;MaxVal=Y(MaxPos);