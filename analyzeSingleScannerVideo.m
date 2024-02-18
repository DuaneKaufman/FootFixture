function resultStruct = analyzeSingleScannerVideo(videoFileName, roi)
    % function to find boundaries in one video
    arguments
        videoFileName char
        % roi is defined as X (horizontal), Y (vertical), width, height
        % Height was chosen to get correct face-to-face distance on the
        % phantom
        roi (1, 4) double = [565, 1, 685, 950]
    end

    % for debugging
    debug = false;

    % Number of frames to process at each time of low change
    NumFramesToProcess = 6;

    % Height of frame to ensure phantom scan ends up correct width
    computeFrameHeight = 950;

    % run through video to get regions to analyze
    [timeSlices, hiConfValley_idx] = analyzeScannerVideo(videoFileName, roi);

    % Load the video
    videoObj = VideoReader(videoFileName);

    % Initialize the result structure
    resultStruct = struct();

    % Extract the base filename (without path and extension)
    [dirName, baseFileName, ~] = fileparts(videoFileName);

    % Process the video at specified time intervals. Do some frame averaging
    % around the specified time
    for i = 1:length(hiConfValley_idx)
        currentTime = timeSlices(i);

        % Check to see if we have enough frames on either side of valley to
        % process - concerned about valleys at beginning and end
        minHalfWidth_idx = floor(NumFramesToProcess/2);

        if (hiConfValley_idx(i) > minHalfWidth_idx) && (hiConfValley_idx(i) < (videoObj.NumFrames - minHalfWidth_idx))
            % enough frames to process
            processSlice_idx = (hiConfValley_idx(i) - minHalfWidth_idx + 1):(hiConfValley_idx(i) + minHalfWidth_idx); 
        else
            % crowding either start or end - find out which and accomodate
            if (hiConfValley_idx(i) < minHalfWidth_idx)
                disp("INFO: adjusting for hiConfValley_idx: " + hiConfValley_idx(i) + ...
                    " with minHalfWidth_idx: " + string(minHalfWidth_idx) + " too close to start");
                processSlice_idx = 1:minHalfWidth_idx;
            else
                disp("INFO: adjusting for hiConfValley_idx: " + hiConfValley_idx(i) + ...
                    " with minHalfWidth_idx: " + string(minHalfWidth_idx) + " too close to end");
                processSlice_idx = (videoObj.NumFrames - minHalfWidth_idx + 1):videoObj.NumFrames;
            end
        end

        % pluck out slice of frames from video
        lowChangeFrames = read(videoObj,[processSlice_idx(1) processSlice_idx(end)]);

        % collapse lowChangeFrames to a single frame - lowChangeFrames is a
        % row x col x depth x num matrix
        lowChangeFrame = uint8(mean(lowChangeFrames, 4));

        croppedFrame = cropFrame(lowChangeFrame, roi);

        % enhance contrast to try to bring out bone boundary
        lowHighPercent = 10; % percentage of pixels allowed to be saturated on the low and high end
        enhancedCroppedFrame = enhanceContrast(croppedFrame, lowHighPercent);

        padFrame = zeros(computeFrameHeight-size(enhancedCroppedFrame, 1), size(enhancedCroppedFrame, 2), 'like', enhancedCroppedFrame);
        paddedFrame  = vertcat(croppedFrame, padFrame);
        midFrame = round(size(croppedFrame, 2) / 2);

        % Detect boundaries and get curve coefficients
        [linearBoundary, skinBoundary, skinCurveCoeffs, skinBoundaryPoints, boneBoundary, boneCurveCoeffs, boneBoundaryPoints] = extractBoundaries(paddedFrame, midFrame);
        
        % Calculate the length of the blue line (distance between boundaries)
        blueLineLength = abs(skinBoundary - linearBoundary);

        % Store results in the structure
        resultStruct(i).time = currentTime;
        resultStruct(i).numFramesToAvg = NumFramesToProcess;
        resultStruct(i).dirName = dirName;
        resultStruct(i).baseFileName = baseFileName;
        resultStruct(i).originalFrame = lowChangeFrame;
        resultStruct(i).croppedFrame = paddedFrame;
        resultStruct(i).processedFrame = displayResults(paddedFrame, linearBoundary, skinBoundary, midFrame, skinCurveCoeffs, skinBoundaryPoints, boneBoundary, boneCurveCoeffs, boneBoundaryPoints);
        resultStruct(i).skinBoundary = skinBoundary;
        resultStruct(i).skinCurveCoeffs = skinCurveCoeffs;
        resultStruct(i).skinBoundaryPoints = skinBoundaryPoints;
        resultStruct(i).boneBoundary = boneBoundary;
        resultStruct(i).boneCurveCoeffs = boneCurveCoeffs;
        resultStruct(i).boneBoundaryPoints = boneBoundaryPoints;

        if debug
            % Display the processed frame with the title
            figure;
            imshow(resultStruct(i).processedFrame);
            axis on;
            titleStr = sprintf('%s - Time: %.2f s ', baseFileName, currentTime);
            title(titleStr, 'Interpreter', 'none');
        end
    end
end
