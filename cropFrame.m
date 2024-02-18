function croppedFrame = cropFrame(frame, roi)
    % Crop the frame to the specified ROI
    % ROI format: [x, y, width, height]
    x = roi(1);
    y = roi(2);
    width = roi(3);
    height = roi(4);
    croppedFrame = frame(y:y+height-1, x:x+width-1, :);

    % Convert to grayscale (if not already)
    if size(croppedFrame, 3) == 3
        croppedFrame = rgb2gray(croppedFrame);
    end
end
