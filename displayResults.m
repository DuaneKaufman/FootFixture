function outputImage = displayResults(frame, linearBoundary, skinBoundary, midFrame, skinCurveCoeffs, skinBoundaryPoints, boneBoundary, boneCurveCoeffs, boneBoundaryPoints)
    % Ensure the frame is in RGB format
    if size(frame, 3) == 1
        outputImage = repmat(frame, [1, 1, 3]); % Convert grayscale to RGB
    else
        outputImage = frame;
    end

    % Parameters for drawing
    lineWidth = 2;

    % Draw the linear boundary in green
    for row = linearBoundary:linearBoundary + lineWidth
        for col = 1:size(outputImage, 2)
            outputImage(row, col, :) = [0, 255, 0]; % Green color
        end
    end

    % Draw the points for the skin curved boundary in
    % yellow
    if ~isempty(skinCurveCoeffs)
        for row = 1:size(skinBoundaryPoints, 1)
            outputImage(skinBoundaryPoints(row, 1), skinBoundaryPoints(row, 2), :) = [255, 255, 0]; % Yellow color
        end
    end

    % Draw the mid-point distance between the linear and skin boundary in
    % yellow - offset column so we can see both skin and bone distances
    skinDistanceColOffset = lineWidth;
    for col = max(midFrame + skinDistanceColOffset - lineWidth, 1):min(midFrame + skinDistanceColOffset + lineWidth, size(outputImage, 1))
        for row = 1:polyval(skinCurveCoeffs, midFrame)
            outputImage(row, col, :) = [255, 255, 0]; % Yellow color
        end
    end

    % Draw the points for the bone curved boundary in
    % red - need to 'enlarge' the point to be able to see them in the image
    pointSize = 5; % not offset from 'truth' if odd-number
    if ~isempty(boneCurveCoeffs)
        for row = 1:size(boneBoundaryPoints, 1)
            % don't plot NaNs
            if ~isnan(boneBoundaryPoints(row, 1))
                for upperRowGrowth=1:floor(pointSize/2)
                        outputImage(boneBoundaryPoints(row, 1) - upperRowGrowth, boneBoundaryPoints(row, 2), :) = [255, 0, 0]; % red color
                end
                outputImage(boneBoundaryPoints(row, 1), boneBoundaryPoints(row, 2), :) = [255, 0, 0]; % red color
                for lowerRowGrowth=1:floor(pointSize/2)
                    outputImage(boneBoundaryPoints(row, 1) + lowerRowGrowth, boneBoundaryPoints(row, 2), :) = [255, 0, 0]; % red color
                end
            end
        end
    end

    % Draw the mid-point distance between the linear and bone boundary in
    % red 
    for col = max(midFrame - lineWidth, 1):min(midFrame + lineWidth, size(outputImage, 1))
        for row = 1:polyval(boneCurveCoeffs, midFrame)
            if row < size(frame, 2)
                % within bounds, plot it
                outputImage(row, col, :) = [255, 0, 0]; % red color
            end
        end
    end
    % make sure output frame is same size as what was passed in
    outputImage = outputImage(1:size(frame, 1), 1:size(frame, 2), :);
end
