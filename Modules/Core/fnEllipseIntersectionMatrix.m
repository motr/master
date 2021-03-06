function [a2bIntersect, a2iIntersectingPairs,a2fIntersectArea] = ...
    fnEllipseIntersectionMatrix(astrctTrackers, iFrame)
%
%Copyright (c) 2008 Shay Ohayon, California Institute of Technology.
% This file is a part of a free software. you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation (see GPL.txt)
iNumMice = length(astrctTrackers);

a2bIntersect = false(iNumMice,iNumMice);
a2fIntersectArea = zeros(iNumMice,iNumMice) ;
a2iIntersectingPairs = [];
for i=1:iNumMice
    for j=i+1:iNumMice
        [a2bIntersect(i,j), apt2fIntersecingPoints, a2fIntersectArea(i,j)] = fnEllipseEllipseIntersection(...
            astrctTrackers(i).m_afX(iFrame),...
            astrctTrackers(i).m_afY(iFrame),...
            astrctTrackers(i).m_afA(iFrame),...
            astrctTrackers(i).m_afB(iFrame),...
            astrctTrackers(i).m_afTheta(iFrame),...
            astrctTrackers(j).m_afX(iFrame),...
            astrctTrackers(j).m_afY(iFrame),...
            astrctTrackers(j).m_afA(iFrame),...
            astrctTrackers(j).m_afB(iFrame),...
            astrctTrackers(j).m_afTheta(iFrame));
        a2bIntersect(j,i) = a2bIntersect(i,j);
        a2fIntersectArea(j,i) = a2fIntersectArea(i,j);
        if (a2bIntersect(i,j))
            a2iIntersectingPairs(end+1,:) = [i,j];
        end;
    end;
end;

return;

