function contrastEnhancedImage = enhanceContrast(inputImage, lowHighPercent)
    % Check if lowHighPercent is provided, otherwise set default to 1%
    if nargin < 2
        lowHighPercent = 1;
    end
    
    % Ensure the image is in grayscale
    if size(inputImage, 3) == 3
        inputImage = rgb2gray(inputImage);
    end
    
    % Convert image to double for calculations
    inputImage = double(inputImage);
    
    % Calculate the percentage for saturation
    lowVal = prctile(inputImage(:), lowHighPercent);
    highVal = prctile(inputImage(:), 100 - lowHighPercent);
    
    % Apply contrast stretching
    contrastEnhancedImage = (inputImage - lowVal) * (255 / (highVal - lowVal));
    
    % Clip the values to be in the 0 to 255 range
    contrastEnhancedImage(contrastEnhancedImage < 0) = 0;
    contrastEnhancedImage(contrastEnhancedImage > 255) = 255;
    
    % Convert back to uint8
    contrastEnhancedImage = uint8(contrastEnhancedImage);
end
