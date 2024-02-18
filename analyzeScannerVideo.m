function [timestamps, hiConfValley_idx] = analyzeScannerVideo(videoFileName, roi)
    arguments
        videoFileName char
        % roi is defined as X (horizontal), Y (vertical), width, height
        roi (1, 4) double 
    end

    % for debugging
    debug = false;
    
    % Calculate frame-to-frame change using ROI
    [changeMetric, frameRate] = measureFrameChange(videoFileName, roi);

    % Do some center-preserving averaging - basically reducing to peaks and
    % valleys
    changeMetricSmoothed=movmean(abs(hilbert(changeMetric)), 15);

    highSmooth = max(changeMetricSmoothed);
    AmpThreshFractionValley = 0.09;  % For findvalley's AmpThreshold
    AmpThreshFractionPeak = 0.45;  % For findpeak's AmpThreshold

    % from: 'Pragmatic Introduction to Signal Processing 2023' Thomas
    % O'Haver
    % [round(peak) valleyX valleyY MeasuredWidth 0] = findvalleys(x,y,SlopeThreshold,AmpThreshold,smoothwidth,peakgroup,smoothtype)
    valley_info = findvalleys(1:length(changeMetricSmoothed), changeMetricSmoothed, 0.017368, highSmooth*AmpThreshFractionValley,3,8,3);

    % from: 'Pragmatic Introduction to Signal Processing 2023' Thomas
    % O'Haver
    % [round(peak) PeakX PeakY MeasuredWidth  1.0646.*PeakY*MeasuredWidth] = findvalleys(x,y,SlopeThreshold,AmpThreshold,smoothwidth,peakgroup,smoothtype)
    peak_info = findpeaksG(1:length(changeMetricSmoothed), changeMetricSmoothed,2000, highSmooth*AmpThreshFractionPeak,3,10,3);

    % Warn if fewer than four high-change regions are detected
    if size(peak_info,1) < 4
        disp("ERROR: fewer than four high-change regions detected!");
    end
    if size(peak_info,1) > 4
        disp("WARNING: more than four high-change regions detected!");
    end

    % Hopefully, combining peak and valley information can lead to
    % high-confidence detection of low-noise regions
    % In a perfect world, every peak will have low-change region before it,
    % snd the last peak will have a low-change region _after_ it
    valleyIdxOffset = 0;
    hiConfValley_idx = [];
    % Used to synthesize first (or last) valley position (if needed)
    avgIdxBetwixtPeaks = mean(diff(peak_info(:,2)));

    % Start looping to pair up valleys preceding peaks
    minMatchesPossible = min(size(valley_info,1), size(peak_info,1));
    if debug
        disp("Number of valleys: " + string(size(valley_info,1)) + " Number of peaks: " + string(size(peak_info,1)))
        outStr = "valley indices: ";
        for i=1:size(valley_info,1)
            outStr = outStr + string(valley_info(i, 2)) + ", ";
        end
        disp(outStr);
        outStr = "peak indices: ";
        for i=1:size(peak_info,1)
            outStr = outStr + string(peak_info(i, 2)) + ", ";
        end
        disp(outStr);
        figure;
        t = tiledlayout(1,1);
        ax1 = axes(t);
        plot(ax1,changeMetricSmoothed, 'r');
        hold on; 
        grid on;
        plot(ax1,changeMetric, 'g');
    end
    for i=1:minMatchesPossible
        % Is valley _before_ peak in question _and_ after previous peak
        if i > 1
            % May need to shift index more than one
            while ~((valley_info(i - valleyIdxOffset, 2) < peak_info(i, 2)) && ...
                    (valley_info(i - valleyIdxOffset, 2) > peak_info(i - 1, 2)))
                % valley _not_ between peaks push index deeper
                valleyIdxOffset = valleyIdxOffset - 1;
                if debug
                    disp("INFO: i: " + string(i) + " shifting valleyIdxOffset. Now at: " + string(valleyIdxOffset))
                end
            end
        end
        if valley_info(i - valleyIdxOffset, 2) < peak_info(i, 2)
            % may be a good pre-peak valley
            hiConfValley_idx = [hiConfValley_idx, valley_info(i - valleyIdxOffset, 2) ];
        else
            % Don't have a good pre-peak valley - need to try to synthesize
            if i == 1
                % First peak, check to make sure there is enough space for
                % a valley
                if peak_info(i, 2) > avgIdxBetwixtPeaks/2
                    % take pre-peak valley half-way between peak and start
                    hiConfValley_idx = [hiConfValley_idx, peak_info(i, 2)/2 ];
                    if debug
                        disp("INFO: synthesizing leading valley at index: " + string(peak_info(i, 2)/2))
                    end
                else
                    disp("ERROR: not enough quiet time before first high-change");
                end
                % Since we synthesized first valley, we need to offset the
                % rest
                valleyIdxOffset = valleyIdxOffset + 1;
            else
                % we are on a peak after the first, but there is no valley
                % before
                disp("ERROR: no valley before peak # " + string(i) + " index: " + string(peak_info(i, 2)));
            end
        end
        lastPeakSeen_idx = i;
        lastValleySeen_idx = i - valleyIdxOffset;
    end

    % If we are short valley information on both start _and_ end, we might
    % not have processed last valley and peak
    if lastPeakSeen_idx < size(peak_info,1)
        hiConfValley_idx = [hiConfValley_idx, valley_info(lastValleySeen_idx + 1, 2) ];
        if debug
            disp("INFO: adding valley at index: " + valley_info(lastValleySeen_idx + 1, 2))
        end
    end

    % We probably came out of the preceding processing with valleys only
    % _preceding_ peaks. If we do actually have valley data _after_ the
    % last peak, let's harvest it, otherwize synthesize it 
    lastValleyAlreadyFound = false;
    lastPeak_idx = size(peak_info,1);
    for i=1:size(valley_info,1)
        if valley_info(i, 2) > peak_info(lastPeak_idx, 2)
            % we have valley data _after_ the last peak
            hiConfValley_idx = [hiConfValley_idx, valley_info(i, 2) ];
            lastValleyAlreadyFound = true;
            % stop looking
            break;
        end
    end
    if ~lastValleyAlreadyFound
        % no calculated last valley value, need to synthesize from last
        % peak value, and inter-peak durations
        if (peak_info(lastPeak_idx, 2) + avgIdxBetwixtPeaks) > size(changeMetricSmoothed, 1)
            % Yay! we have enough points to get a valley after the last
            % peak
            hiConfValley_idx = [hiConfValley_idx, peak_info(lastPeak_idx, 2) + (avgIdxBetwixtPeaks/2)];
            if debug
                disp("INFO: synthesizing last valley at index: " + string(peak_info(lastPeak_idx, 2) + (avgIdxBetwixtPeaks/2)))
            end
        else
            % dang! don't have enough points after the last high-change
            % peak to take data
            disp("ERROR: not enough data after peak # " + string(size(hiConfValley_idx, 1)) + " index: " + string(lastPeakSeen_idx));
        end
    end

    % Convert float indices to integers
    hiConfValley_idx = round(hiConfValley_idx);

    % Convert good valley indices to time
    timestamps = hiConfValley_idx / frameRate;
    if debug
        % pick up and add more to plot
        ax2 = axes(t);
        timeTics = zeros(size(changeMetric,2), 1);
        timeTics(hiConfValley_idx) = 1;
        plot(ax2, linspace(1, size(changeMetric,2) / frameRate, size(changeMetric,2)), timeTics, 'b');
        ax2.XAxisLocation = 'top';
        ax2.YAxisLocation = 'right';
        ax2.Color = 'none';
        ax1.Box = 'off';
        ax2.Box = 'off';
        [~,name,~] = fileparts(videoFileName);
        title(name + " Frame-to-Frame change", "Interpreter","none");
        legend(ax1, ["smoothed", "raw"]);
        legend(ax2, ["window center"], 'Location', 'northwest');
        xlabel(ax1, "Video frame index");
        xlabel(ax2, "Video frame (seconds)");
    end
end
