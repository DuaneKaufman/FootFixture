function [skinCurveCoeffs, skinBoundaryPoints, boneCurveCoeffs, boneBoundaryPoints]= findSkinAndBoneBoundary(frame, offset)
    % Ensure the frame is grayscale
    if size(frame, 3) == 3
        frame = rgb2gray(frame);
    end

    % Define the region of interest (ROI) 
    ROI = frame;
    % Zero out imager bright-line region
    ROI(1:offset,:) = 0;

    % Threshold for identifying skin intensity
    intensityThreshold = 0.85 * max(ROI(:));  % Adjust as necessary

    % Find points above the intensity threshold
    [rows, cols] = find(ROI > intensityThreshold);    
    
    % Fit a quadratic curve (y = ax^2 + bx + c) to these points
    if length(rows) >= 3 % Need at least 3 points to fit a quadratic curve
        %curveCoeffs = polyfit(rows, cols, 2);
        curveCoeffs = polyfit(cols, rows, 2);
    else
        curveCoeffs = []; % Return empty if not enough points
    end

    % Try to mask out artifacts _behind_ entry to skin
    %   Method: 
    %    Now that we have an estimate of the high-contrast skin line, mask
    %    out everything but a band along this estimate. Do vertical sweeps
    %    along columns, setting pixels away from curve to zero
    skinLineBandHalfWidth = 60;  % pixels

    numIterations = 3;
    skinCurveCoeffs = curveCoeffs;
    for i=1:numIterations
        ROIn = ROI;
        for swCol=1:size(ROIn,2)
            curvePathCenterPt = polyval(skinCurveCoeffs, swCol);
            curvePathEdge0 = curvePathCenterPt - skinLineBandHalfWidth;
            curvePathEdge1 = curvePathCenterPt + skinLineBandHalfWidth;
            ROIn(1:curvePathEdge0, swCol) = 0;
            ROIn(curvePathEdge1:end, swCol) = 0;
        end
        % Find points above the intensity threshold
        [rows, cols] = find(ROIn > intensityThreshold);    
        % fit quadratic to newly masked data
        skinCurveCoeffs = polyfit(cols, rows, 2);
        % Tighten curve band
        skinLineBandHalfWidth = skinLineBandHalfWidth - 10;
    end
    skinBoundaryPoints = [rows, cols];

    % Try to find _bone_ boundary
    %   Method: 
    %    Now that we have an estimate of the high-contrast skin line, mask
    %    out everything up to this estimate. Do vertical sweeps
    %    along columns, getting column intensity plots vs row
    %
    % Threshold for identifying bone intensity
    boneThreshold = 0.35 * max(ROI(:));  % Adjust as necessary

    rawBoneEdge_idx = zeros(size(ROI, 2), 1);
    for boneSwCol=1:size(ROI,2)
        % Find indices of points above the intensity threshold, coming from
        % the _inside_ the bone direction
        try
            rawBoneEdge_idx(boneSwCol) = find(movmean(ROI(:,boneSwCol), 11) > boneThreshold, 1, 'last'); 
        catch ME
            disp("WARNING: Searching for bone boundary missed on column: " + string(boneSwCol));
            rawBoneEdge_idx(boneSwCol) = NaN;
        end
    end
    boneBoundaryPoints = [rawBoneEdge_idx, (1:size(ROI,2))'];

    % Fit a quadratic curve (y = ax^2 + bx + c) to these points
    boneCurveCoeffs = polyfit(1:size(ROI,2), movmean(fillmissing(rawBoneEdge_idx, 'spline'), 150), 2);

end
