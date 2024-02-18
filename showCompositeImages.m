function showCompositeImages(dataStructIn)
    %  Data used for scaling x-axis distance settings
    %  scanner cuts off scanner side 
    scannerOffset_mm = 1.35;
    %  when measuring double phantom, with 3mm styrene on each face
    doubleWithStyreneWidth_mm = 56;
    %  when using scanner scale on DAK double phantom scans (20231221) 
    doubleWithStyreneL = 31 + scannerOffset_mm; % US - mm
    doubleWithStyreneR = 33.2 + scannerOffset_mm; % US - mm
    %  when measuring single phantom, with 3mm styrene on each face -
    %  Zhangpeng (20240213)
    singleWithStyreneWidth_mm = 31.66;    
    %  when using scanner scale on 0071 single phantom scans (20240214) 
    singleWithStyreneL = 31.5 + scannerOffset_mm; % US - mm
    singleWithStyreneR = 31.1 + scannerOffset_mm; % US - mm

    % using single phantom with styrene to convert pixels to mm - I have no
    % explanation for why when calculated with double the inter-scanner
    % distance is different!
    % widthBetweenSanners = doubleWithStyreneL + doubleWithStyreneR + doubleWithStyreneWidth_mm;
    widthBetweenSanners = singleWithStyreneL + singleWithStyreneR + singleWithStyreneWidth_mm;

    % Hard-coded custom x-axis settings
    xAxisMin = -(widthBetweenSanners/2);  % Custom x-axis minimum - mm
    xAxisMax = widthBetweenSanners/2;   % Custom x-axis maximum - mm
    minNumTicks = 5; % Minimum number of tick marks

    % Number of images
    numImages = length(dataStructIn.compositeImages);
    fig = figure('Name', 'Composite Images', 'NumberTitle', 'off', 'Position', [100 100 1000 1200]);
    % try to use tiled layout for closer spacing
    tlo = tiledlayout(fig, 'flow', 'TileSpacing', 'tight', 'Padding', 'tight');

    % Preallocate array for axes handles and vertical lines
    axHandles = gobjects(numImages, 1);
    vertLines = gobjects(numImages, 1); % Store handles for vertical lines
    lastXLim = cell(numImages, 1); % Store last x-limits to detect changes

    % Display all images and configure axes
    for i = 1:numImages
        % axHandles(i) = subplot(numImages, 1, i);
        axHandles(i) = nexttile(tlo);
        imshow(dataStructIn.compositeImages{i}, 'InitialMagnification', 'fit'); % Display image
        axis on; % Enable axis visibility
        if i ~= numImages
            set(gca, 'XTickLabel', [], 'YTickLabel', []); % Remove axis labels except for the bottom plot
        end
        lastXLim{i} = get(gca, 'XLim'); % Initialize last x-limits
        % add title with timestamp info
        titleStr = "Time: " + string(round(dataStructIn.left_data(i).time, 1)) + " s" +...
            "                          " + ...
            "Time: " + string(round(dataStructIn.right_data(i).time, 1)) + " s";
        title(axHandles(i), titleStr);
        % make axis and titles smaller
        axHandles(i).LabelFontSizeMultiplier = 1.0;
        axHandles(i).TitleFontSizeMultiplier = 0.8;
    end

    % main title
    [~, baseFileNameL, ~] = fileparts(dataStructIn.left_data(1).baseFileName);
    [~, baseFileNameR, ~] = fileparts(dataStructIn.right_data(1).baseFileName);
    % sgt = sgtitle("L File: " + baseFileNameL + "          " + "R File: " + baseFileNameR);
    % sgt.FontSize = 14;
    title(tlo,"L File: " + baseFileNameL + "          " + "R File: " + baseFileNameR);

    % Apply custom x-axis settings for the bottom plot initially
    setCustomXTicks(axHandles(end), xAxisMin, xAxisMax, minNumTicks, size(dataStructIn.compositeImages{1}, 2));

    % Set up unified zoom and pan handlers and link all axes for zoom and pan
    linkaxes(axHandles, 'xy'); % Link all axes for zooming and panning
    hZoom = zoom(fig);
    set(hZoom, 'Enable', 'on', 'ActionPostCallback', @(obj, evd) onZoomOrPan());
    hPan = pan(fig);
    set(hPan, 'Enable', 'on', 'ActionPostCallback', @(obj, evd) onZoomOrPan());

    % Data cursor mode setup
    dcm_obj = datacursormode(fig);
    set(dcm_obj, 'UpdateFcn', @(src, event) updateCursor(event), 'Enable', 'on');

    % Initialize checking for axis limit changes
    checkAxisLimitsTimer = timer('ExecutionMode', 'fixedRate', 'Period', 0.5, 'TimerFcn', @(~,~) checkAndUpdateAxisLimits());
    start(checkAxisLimitsTimer);

    % Ensure to clean up the timer when the figure is closed
    set(fig, 'CloseRequestFcn', @(src, event)cleanupTimer(src, checkAxisLimitsTimer));

    % Function definitions:

    % Custom update function for data cursor
    function txt = updateCursor(event_obj)
        pos = get(event_obj, 'Position'); % Get cursor position
        customX = round(((pos(1) - 1) / size(dataStructIn.compositeImages{1}, 2)) * (xAxisMax - xAxisMin) + xAxisMin, 1); % Convert to custom x-axis, rounded to tenth
        txt = {['X: ', num2str(customX, '%.1f')], ['Y: ', num2str(pos(2), '%.1f')]};

        % Update or draw vertical blue line in all images
        for i = 1:numImages
            ax = axHandles(i);
            if isgraphics(vertLines(i))
                set(vertLines(i), 'XData', [pos(1), pos(1)]);
            else
                vertLines(i) = line(ax, 'XData', [pos(1), pos(1)], 'YData', ax.YLim, 'Color', 'b', 'LineWidth', 2, 'Tag', 'CursorLine');
            end
        end
    end

    % Function to set custom X ticks and labels based on current zoom level
    function setCustomXTicks(ax, minX, maxX, minNumTicks, imgWidth)
        xlims = get(ax, 'XLim'); % Get current x-limits
        newXTicks = linspace(max(1, xlims(1)), min(imgWidth, xlims(2)), max(minNumTicks, 5)); % Ensure within image bounds
        newXLabels = linspace(max(minX, ((xlims(1) - 1) / imgWidth) * (maxX - minX) + minX), min(maxX, ((xlims(2) - 1) / imgWidth) * (maxX - minX) + minX), max(minNumTicks, 5));
        set(ax, 'XTick', newXTicks, 'XTickLabel', arrayfun(@(x) sprintf('%.1f', x), newXLabels, 'UniformOutput', false));
    end

    % Function to update zoom and pan for all axes
    function onZoomOrPan()
        syncLimits(); % Synchronize limits across all plots
        updateVerticalLines(); % Update vertical lines to span the full y-axis extent
    end

    % Function to synchronize zoom and pan limits across all subplots
    function syncLimits()
        xl = get(axHandles(end), 'XLim'); % Get the x limits from the bottom subplot
        yl = get(axHandles(end), 'YLim'); % Get the y limits from the bottom subplot
        for ax = axHandles'
            set(ax, 'XLim', xl, 'YLim', yl); % Apply the same limits to all axes
            setCustomXTicks(ax, xAxisMin, xAxisMax, minNumTicks, size(dataStructIn.compositeImages{1}, 2)); % Redraw custom tick labels based on zoom
        end
    end

    % Function to update vertical lines across all images to cover full y-axis extent
    function updateVerticalLines()
        for i = 1:numImages
            ax = axHandles(i);
            if isgraphics(vertLines(i))
                set(vertLines(i), 'YData', ax.YLim); % Update line to span full y-axis extent
            end
        end
    end

    % Function to check and update axis limits if changed
    function checkAndUpdateAxisLimits()
        for i = 1:numImages
            currentXLim = get(axHandles(i), 'XLim');
            if ~isequal(currentXLim, lastXLim{i}) % Check if limits have changed
                lastXLim{i} = currentXLim; % Update last x-limits
                onZoomOrPan(); % Handle zoom or pan by updating limits and vertical lines
            end
        end
    end

    % Cleanup function to stop and delete the timer
    function cleanupTimer(fig, timer)
        stop(timer); % Stop the timer
        delete(timer); % Delete the timer object
        delete(fig); % Close the figure properly
    end
end
