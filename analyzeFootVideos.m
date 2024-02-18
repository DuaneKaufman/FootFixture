function resultStruct = analyzeFootVideos(leftVideo, rightVideo)
    % function to analyze the two videos (left and right) which are taken
    % for one foot
    %
    % Returns:
    %    structure containing all data for each video
    %    combined data - images

    % for debugging
    debug = true;

    % Initialize the result structure
    resultStruct = struct();

    % analyze left video
    out_left = analyzeSingleScannerVideo(leftVideo);

    % analyze right video
    out_right = analyzeSingleScannerVideo(rightVideo);

    if ~(size(out_left, 2) == size(out_right, 2))
        % different numbers of images found 
        disp("WARNING: different numbers of left-right images found - check timestamps!")
    end
    resultStruct.left_data = out_left;
    resultStruct.right_data = out_right;
    % Now create composite images
    compositeImages = cell(1, min(size(out_left, 2), size(out_right, 2)));
    for measNum = 1:min(size(out_left, 2), size(out_right, 2))
        % for each set of measurements (left and right at ~same time)
        % create a composite image
        newImage = horzcat((rot90(out_left(measNum).processedFrame, 1)), ...
                             flipud(rot90(out_right(measNum).processedFrame, 3)));
        compositeImages{measNum} = newImage;
    end
    resultStruct.compositeImages = compositeImages;

    if debug
        showCompositeImages(resultStruct);
    end
end