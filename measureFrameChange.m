function [changeMetric, frameRate] = measureFrameChange(videoFileName, roi)
    % Function to measure frame-to-frame variability 
    
    % Initialize video reader
    f = waitbar(0, ['Opening video file ', videoFileName]);
    set(gca(f).Title,'Interpreter','none');
    
    videoObj = VideoReader(videoFileName);

    % example properties:
    % General Properties:
    %          Name: 'FF_1002_20231221_DAK.mp4'
    %          Path: '/home/duane/Downloads'
    %      Duration: 68.0833
    %   CurrentTime: 0.0417
    %     NumFrames: 1634
    % 
    % Video Properties:
    %         Width: 1920
    %        Height: 1080
    %     FrameRate: 24
    %  BitsPerPixel: 24
    %   VideoFormat: 'RGB24'

    numFrames = videoObj.NumFrames;
    frameRate = videoObj.FrameRate;

    % Initialize the change metric array
    changeMetric = zeros(1, videoObj.NumFrames - 1);

    % Read the first frame and convert it to grayscale
    prevFrame = readFrame(videoObj);
    if size(prevFrame, 3) == 3
        prevFrame = rgb2gray(prevFrame);
    end

    % Extract ROI from the first frame
    prevFrame = prevFrame(roi(2):(roi(2) + roi(4) - 1), roi(1):(roi(1) + roi(3) - 1));

    % Iterate over all frames in the video
    frameIndex = 1;
    waitbar(frameIndex/numFrames, f, "Processing frame (" + string(frameIndex) + "/" + string(numFrames) + ")");
    while hasFrame(videoObj)
        currentFrame = readFrame(videoObj);

        % Convert to grayscale if necessary
        if size(currentFrame, 3) == 3
            currentFrame = rgb2gray(currentFrame);
        end

        % Extract ROI from the current frame
        currentFrameROI = currentFrame(roi(2):(roi(2) + roi(4) - 1), roi(1):(roi(1) + roi(3) - 1));

        % Calculate the sum of absolute differences between frames in the ROI
        frameDifference = abs(double(currentFrameROI) - double(prevFrame));
        changeMetric(frameIndex) = sum(frameDifference(:));

        % Update previous frame ROI
        prevFrame = currentFrameROI;
        
        % Update frame index
        frameIndex = frameIndex + 1;
        waitbar(frameIndex/numFrames, f, "Processing frame (" + string(frameIndex) + "/" + string(numFrames) + ")");
    end
    close(f);
end
