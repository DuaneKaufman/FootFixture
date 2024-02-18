function [linearBoundary, skinBoundary, skinCurveCoeffs, skinBoundaryPoints, boneBoundary, boneCurveCoeffs, boneBoundaryPoints] = extractBoundaries(frame, midFrame)
    offset = 100; % Distance from the linear boundary

    linearBoundary = findLinearBoundary(frame);
    [skinCurveCoeffs, skinBoundaryPoints, boneCurveCoeffs, boneBoundaryPoints]= findSkinAndBoneBoundary(frame, offset);
    if ~isempty(skinCurveCoeffs)
        % curved boundary found and fitted
        skinBoundary = round(polyval(skinCurveCoeffs, midFrame));
    else
        % no skin curved boundary found
        disp("ERROR: no skin curved boundary found!");
    end
    if ~isempty(boneCurveCoeffs)
        % curved boundary found and fitted
        boneBoundary = round(polyval(boneCurveCoeffs, midFrame));
    else
        % no skin curved boundary found
        disp("ERROR: no bone curved boundary found!");
    end
end
