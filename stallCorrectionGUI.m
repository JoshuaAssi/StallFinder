function stallogram_new = stallCorrectionGUI(S, DDD, stallogram, scoreTrace, intTrace)

    [nz, nx, ny, T] = size(DDD);
    sizeS = length(S);
    stallogram_new = stallogram;
    colors = abs(rand(sizeS, 3) - 0.3) + 0.3;
    colors = [colors ones(sizeS, 1) * 0.6];
    allShowing = 0;
    changeIm = 1;
    cumulativeStallDurationShowing = 0; % Initialize the new toggle button state
    cv = [0 0 0 0];
    vIndex = [];
    % Calculate the log-scaled probabilities
    P = sum(stallogram_new, 2) / T;
    logP = log(P);
    % Scale the log values to the colormap range
    minLogP = log(1/T);
    maxLogP = 0;
    scaledLogP = (logP - minLogP) / (maxLogP - minLogP);
    % Map the scaled log values to the colormap
    colormapValues = jet(256);
    lineArray = gobjects(sizeS, 1);
    prevBoxHandle = [];
    
    dds = DDD;
    MIPs = permute(squeeze(max(dds)), [3 1 2]);
    j = 1;
    first = 1;
    
    
    % Create figure with sliders and toggle buttons
    fig = figure('Name', 'Manual Stall Correction GUI', 'NumberTitle', 'off', 'Position', [100, 100, 1150, 900]);
    highlightedText = text('String', '', 'Units', 'normalized','Position', [.885 1], 'FontSize', 12, 'Color', [0 0 0], 'Visible', 'off');
    set(gca, 'Visible', 'off')
    slider = uicontrol('Style', 'slider', 'Min', 1, 'Max', T, 'Value', 1, ...
        'Units', 'normalized', 'Position', [0.1, 0.01, 0.8, 0.05], 'Callback', @sliderCallback, 'Parent', fig);   
    
    % Add colorbar
    colorbarAxis = axes('Parent', fig, 'Units', 'normalized', 'Position', [0.01, 0.3, 0.8, 0.30]);
    colormap(colorbarAxis, jet); % Use the same colormap as getColorBasedOnProbability
    cb = colorbar(colorbarAxis, 'Ticks', [], 'TickLabels', []);
    set(gca, 'Visible','off')
    caxis([minLogP, maxLogP]);
    ylabel(cb, 'Cumulative Stall Duration (# of frames, log scale)')
    cb.Ticks = [minLogP, maxLogP];
    cb.TickLabels = [1, T];
    set(cb, 'Visible', 'off');
    
    imgAxis = axes('Parent', fig, 'Units', 'normalized', 'Position', [0.2, 0.3, 0.6, 0.65]);
 
    img = imagesc(squeeze(MIPs(j, :, :)), 'Parent', imgAxis);
    colormap(imgAxis, gray);
    hold on;
    axis image;
    title(imgAxis, ['Time ' num2str(j)]);
    xticklabels([])
    yticklabels([])
 
    toggleCumulativeStallDurationButton = uicontrol('Style', 'togglebutton', 'String', 'Toggle Cumulative Stall Duration', ...
        'Units', 'normalized', 'Position', [0.77, 0.8, 0.2, 0.05], 'Callback', @toggleCumulativeStallDurationButtonCallback, 'Parent', fig);
 
    removeVesselButton = uicontrol('Style', 'pushbutton', 'String', 'Clear Stalls', ...
        'Units', 'normalized', 'Position', [0.77, 0.75, 0.2, 0.05], 'Callback', @removeVesselButtonCallback, 'Parent', fig);
    
    toggleAllButton = uicontrol('Style', 'togglebutton', 'String', 'Toggle All Vessels', ...
        'Units', 'normalized', 'Position', [0.77, 0.85, 0.2, 0.05], 'Callback', @toggleAllButtonCallback, 'Parent', fig);

    controlText = annotation('textbox', [0.03, .5, .2, .03], 'String', 'Keyboard Controls', 'FontWeight','bold');
    % controlText.Parent = fig;
    controlText2 = annotation('textbox', [0.03, .32, .2, .18],'String', ['"a": toggle all vessels (random colors)' newline '"d": toggle cumulative stall duration' newline '"r": clear all vessel stalls' newline '"right arrow": next frame' newline '"left arrow": previous frame' newline '"up arrow": next vessel' newline '"down arrow": previous vessel']);
    % controlText2.Parent = fig;
    instructionText = annotation('textbox', [0.03, .9, .2, .03], 'String', 'Instructions', 'FontWeight','bold');
    % intructionText.Parent = fig;
    instructionText2 = annotation('textbox', [0.03, .57, .2, .33], 'String', 'Use the buttons or keyboard inputs to show/hide vessels, change frames, or change the selected vessel. Clicking on a plotted vessel will also select it. The grid below includes a "predicted" and "correction" stallogram for the selected vessel. You can edit the "correction" stallogram by clicking on the grid (black=flowing, white=stalled). The slider tool can also be used to move between frames and the red double arrow indicates the current frame. MATLAB built-in tools are also functional including zoom in/out and pan. ');
    % intructionText2.Parent = fig;

    leftArrowButton = uicontrol('Style', 'pushbutton', 'String', '<', ...
        'Units', 'normalized', 'Position', [0.77, 0.9, 0.03, 0.05], 'Callback', @leftArrowButtonCallback, 'Parent', fig);

    rightArrowButton = uicontrol('Style', 'pushbutton', 'String', '>', ...
        'Units', 'normalized', 'Position', [0.94, 0.9, 0.03, 0.05], 'Callback', @rightArrowButtonCallback, 'Parent', fig);
    % Initialize current vessel index
    currentVesselIndex = 1;
    
    
    intTraceAxis = axes('Parent', fig, 'Units', 'normalized', 'Position', [0.1, 0.18, 0.8, 0.1]);
    yyaxis left
    plot(intTraceAxis, 1:T, zeros(size(scoreTrace(1,:))), 'Color', 'b', 'LineWidth', 1.5);
    xlim([.5 T+.5])
    ylabel('SVM score');
    ylim([0 1])
    xticks(1:T)
    xticklabels([])
    yticklabels([])
    
    yyaxis right
    plot(intTraceAxis, 1:T, zeros(size(intTrace(1,:))), 'Color', 'b', 'LineWidth', 1.5);
    xlim([.5 T+.5])
    ylabel('intensity');
    intMin = min(intTrace, [],'all');
    intMax = max(intTrace, [],'all');
    ylim([intMin intMax])
    grid on

    % Add 2 by T grid
    gridAxis = axes('Parent', fig, 'Units', 'normalized', 'Position', [0.1, 0.1, 0.8, 0.05]);
    gridValues = zeros(2, T);
    gridImage = imagesc(gridValues, 'Parent', gridAxis);
    xticks(0:5:T)
    yticks([1 2])
    yticklabels({'predicted','correction'})
    grid on;
    gridAxis.XGrid = 'on';
    gridAxis.YGrid = 'off';
    gridAxis.XTick = (1:T)-.5;
    xTickLabels = cell(1,sizeS+1);
    for i = 1:T
        if ~mod(i-1,5)
            xTickLabels{i} = i-1;
        else
            xTickLabels{i} = '';
        end
    end
    gridAxis.XTickLabel = xTickLabels;
    gridAxis.GridColor = [0.7 0.7 0.7];
    gridAxis.GridAlpha = 0.5; % Grid transparency
    gridAxis.TickLength = [0 0];
 
    % Set the colormap for the grid
    colormap(gridAxis, [0 0 0; 1 1 1]);
    caxis(gridAxis, [0 1]);
 
    % Add click/drag functionality to the grid
    set(gridImage, 'ButtonDownFcn', {@gridClickCallback});
    
    set(fig, 'WindowKeyPressFcn', @keyPressCallback);

    comparisonGUI();
    scrollVessel();
 
    % Wait for user interaction
    uiwait;
    
    % Callback function for key press event
    function keyPressCallback(~, event)
        % Retrieve the figure handle
        fig = gcf;

        % Handle key press event
        switch event.Key
            case 'rightarrow'
                % Move forward in time if not already at the last timepoint
                if j < T
                    j = j + 1;
                    set(slider, 'Value', j);
                    comparisonGUI();
                    changeIm = 1;
                end
            case 'leftarrow'
                % Move backward in time if not already at the first timepoint
                if j > 1
                    j = j - 1;
                    set(slider, 'Value', j);
                    comparisonGUI();
                    changeIm = 1;
                end
            case 'downarrow' % Add functionality for up arrow key
                if currentVesselIndex > 1
                    currentVesselIndex = currentVesselIndex - 1;
                else
                    currentVesselIndex = sizeS; % Wrap around to the last vessel
                end
                scrollVessel(); % Call scrollVessel after updating currentVesselIndex
            case 'uparrow' % Add functionality for down arrow key
                if currentVesselIndex < sizeS
                    currentVesselIndex = currentVesselIndex + 1;
                else
                    currentVesselIndex = 1; % Wrap around to the first vessel
                end
                scrollVessel(); % Call scrollVessel after updating currentVesselIndex
            case 's'
                % toggleStallingButtonCallback
            case 'f'
                % toggleFlowingButtonCallback
            case 'd'
                toggleCumulativeStallDurationButtonCallback
            case 'r'
                removeVesselButtonCallback
            case 'a'
                toggleAllButtonCallback
        end
    end
 
    % Callback functions for slider, toggle buttons, and key press
    function sliderCallback(~, ~)
        j = round(get(slider, 'Value'));
        comparisonGUI();
        changeIm = 1;
    end
 
    function toggleCumulativeStallDurationButtonCallback(~, ~)
        cumulativeStallDurationShowing = ~cumulativeStallDurationShowing;

        % Toggle colorbar visibility based on the button state
        if cumulativeStallDurationShowing
            set(cb, 'Visible', 'on');
        else
            set(cb, 'Visible', 'off');
        end

        % Turn off other toggle buttons when cumulative stall duration button is pressed
        if cumulativeStallDurationShowing
            allShowing = 0;
            set(toggleAllButton, 'Value', 0);
            % set(toggleStallingButton, 'Value', 0);
            % set(toggleFlowingButton, 'Value', 0);
        end
        comparisonGUI();
    end

    function toggleAllButtonCallback(~, ~)
        allShowing = ~allShowing;
        if allShowing
            cumulativeStallDurationShowing = 0;
            set(cb, 'Visible', 'off')
            % set(toggleStallingButton, 'Value', 0);
            % set(toggleFlowingButton, 'Value', 0);
            set(toggleCumulativeStallDurationButton, 'Value', 0);

            %change color and add text
            for vI = 1:sizeS
                set(lineArray(vI), 'Color', colors(vI,:));
            end
        else
            %remove color and text
            for vI = 1:sizeS
                set(lineArray(vI), 'Color', cv);
            end
        end
    end
 
    function gridClickCallback(~, eventData)
        % Callback when the grid is clicked
        if strcmp(eventData.EventName, 'Hit')
            % Get the click coordinates
            clickCoords = get(gridAxis, 'CurrentPoint');
            % Convert the coordinates to grid indices
            clickedRow = round(clickCoords(3));
            clickedCol = round(clickCoords(1));
            % Toggle the color in the second row
            gridValues(2, clickedCol) = ~gridValues(2, clickedCol);
            stallogram_new(vIndex, clickedCol) = ~gridValues(2, clickedCol);
            set(gridImage, 'CData', gridValues);
            if cumulativeStallDurationShowing
                c = getColorBasedOnProbability(vIndex);
                if sum(stallogram_new(vIndex,:))==0
                    c = cv;
                end
            end
            if exist('c', 'var')
                set(lineArray(vIndex), 'color', c);
            end
        end
    end
 
    function clickCallback(~, event, vI)
        % Callback when a vector is clicked
        if strcmp(event.EventName, 'Hit')
            highlightVector(vI);
            vIndex = vI;
            currentVesselIndex = vIndex;
            updatePlot(vI);
        end
    end

    function updatePlot(vesselIndex)
        % Function to update the plot based on the clicked vessel index
        drawBoxAroundVessel(vesselIndex, imgAxis);
        
        % Extract the intensity trace of the clicked vessel
        scoreTrace0 = scoreTrace(vesselIndex, :);
        intTrace0 = intTrace(vesselIndex,:);

        % Plot the intensity trace
        yyaxis(intTraceAxis, 'left')
        plot(intTraceAxis, 1:T, scoreTrace0, 'Color', 'b', 'LineWidth', 1.5);
        xlim(intTraceAxis, [.5, T+.5]);
        ylabel(intTraceAxis, 'SVM score');
        ylim(intTraceAxis, [0 1]);
        xticks(intTraceAxis, 1:T);
        xticklabels(intTraceAxis, []);
        yticklabels(intTraceAxis, []);
        yyaxis(intTraceAxis, 'right')
        plot(intTraceAxis, 1:T, intTrace0, 'Color', 'r', 'LineWidth', 1.5);
        ylabel(intTraceAxis, 'intensity');
        ylim(intTraceAxis, [intMin intMax])
        
        grid(intTraceAxis, 'on');
    end
 
    function drawBoxAroundVessel(vesselIndex, imgAxis)
        vessel = S{vesselIndex};
        x = vessel(:, 3);
        y = vessel(:, 2);
        % Calculate bounding box coordinates
        xmin = max([min(x)-6, 0]);
        xmax = min([max(x)+6, nx]);
        ymin = max([min(y)-6, 0]);
        ymax = min([max(y)+6, ny]);
        if ~isempty(prevBoxHandle) && isvalid(prevBoxHandle)
            delete(prevBoxHandle);
        end
        % Draw the box with thin red borders
        prevBoxHandle = rectangle('Position', [xmin, ymin, xmax-xmin, ymax-ymin], 'EdgeColor', 'r', 'LineWidth', 1, 'Parent', imgAxis);
    end

    % Update the highlightVector function to also draw the box
    function highlightVector(selectedIndex)
        % Function to highlight a vector
        for vI = 1:sizeS
            if ~isnan(stallogram_new(vI,j))
                if vI == selectedIndex
                    lineWidth = 5; % Highlighted vector has a thicker line
                    set(highlightedText, 'String', ['Vessel #: ' num2str(vI) '/' num2str(sizeS)], 'Visible', 'on');
                    % Update the grid based on stallogram values
                    gridValues(1, :) = ~stallogram(vI, :);
                    gridValues(2, :) = ~stallogram_new(vI, :);
                    set(gridImage, 'CData', gridValues);
                    % Draw a box around the highlighted vessel
                    drawBoxAroundVessel(vI, imgAxis);
                else
                    lineWidth = 3;
                end
                if ishandle(lineArray(vI))
                    set(lineArray(vI), 'LineWidth', lineWidth);
                end
            end
        end
    end
 
    function comparisonGUI()
    % Add or update the indicator line for the current time point
    if isempty(findobj('Type', 'line', 'Tag', 'verticalLine'))
        % Only draw the line if it doesn't exist
        hold on
        verticalLine = plot([j, j], [.25, -.45], 'Color', 'r', 'LineWidth', 3.5,'Marker', 'diamond','MarkerSize', 1, 'MarkerFaceColor', 'r','Tag', 'verticalLine');
        set(verticalLine, 'Clipping', 'off');
        uistack(verticalLine, 'top'); % Move the line to the top
    else
        % Update the position of the existing line
        set(findobj('Type', 'line', 'Tag', 'verticalLine'), 'XData', [j, j]);
    end
    
    if first
        % Plot vessels for the first time
        for vI = 1:sizeS
            if ~isnan(stallogram_new(vI,j))
                vessel1 = S{vI};
                if cumulativeStallDurationShowing && sum(stallogram_new(vI, :)) > 0
                    % Color based on plotProbability logic
                    c = getColorBasedOnProbability(vI);
                else
                    c=cv;
                end
                lineArray(vI) = plot(vessel1(:, 3), vessel1(:, 2), 'LineWidth', 3, 'Color', c, 'Parent', imgAxis, 'ButtonDownFcn', @(src, event) clickCallback(src, event, vI));
            end
        end
        first = 0;
    elseif changeIm
        % Update image and vessel colors
        set(img, 'CData', squeeze(MIPs(j, :, :)));
        title(imgAxis, ['Time ' num2str(j)]);
        for vI = 1:sizeS
            if ~isnan(stallogram_new(vI,j))
                if cumulativeStallDurationShowing && sum(stallogram_new(vI, :)) > 0
                    % Color based on plotProbability logic
                    c = getColorBasedOnProbability(vI);
                else
                    % Original coloring logic
                    c = cv; % Set color to transparent
                end
                % Verify that the handle is valid before modification
                if ishandle(lineArray(vI))
                    set(lineArray(vI), 'Color', c);
                end
            end
        end
        changeIm = 1;
    else
        changeIm = 1;
    end
    if isempty(findobj('Type', 'line', 'Tag', 'horizontalLine'))
        % Only draw the line if it doesn't exist
        hold on
        horizontalLine = plot([0, T+1], [1.5, 1.5], 'Color', gridAxis.GridColor, 'LineWidth', .5, 'Tag', 'horizontalLine');
        uistack(horizontalLine, 'top'); % Move the line to the bottom
    end
end

 
    function c = getColorBasedOnProbability(vI)
        % Function to get color based on refined log-scaled cumulative stall duration

        % Calculate the log-scaled probabilities
        P = sum(stallogram_new, 2) / size(stallogram_new, 2);
        logP = log(P);
        % Scale the log values to the colormap range
        scaledLogP = (logP - minLogP) / (maxLogP - minLogP);
        % Map the scaled log values to the colormap
        colormapValues = jet(256);
        C = round(scaledLogP(vI) * (256 - 1)) + 1;  % Adjusted to use (256 - 1) as the maximum index
        % Ensure the index is within bounds
        C = max(1, min(C, 256));
        c = colormapValues(C, :);
    end

    % Callback function for "Remove Vessel" button
    function removeVesselButtonCallback(~, ~)
        % Check if a vessel is highlighted
        if ~isempty(vIndex)
            % Convert all values in stallogram_new(vI, :) to 0
            stallogram_new(vIndex, :) = 0;
            % Update the grid image
            gridValues(2, :) = ~stallogram_new(vIndex, :);
            set(gridImage, 'CData', gridValues);
            set(lineArray(vIndex), 'Color', cv);
            % Update the visualization
            comparisonGUI();
        end
    end

    function leftArrowButtonCallback(~, ~)
        if currentVesselIndex > 1
            currentVesselIndex = currentVesselIndex - 1;
        else
            currentVesselIndex = sizeS; % Wrap around to the last vessel
        end
        scrollVessel(); % Call scrollVessel after updating currentVesselIndex
    end

    function rightArrowButtonCallback(~, ~)
        if currentVesselIndex < sizeS
            currentVesselIndex = currentVesselIndex + 1;
        else
            currentVesselIndex = 1; % Wrap around to the first vessel
        end
        scrollVessel(); % Call scrollVessel after updating currentVesselIndex
    end

    % Function to scroll to the selected vessel
    function scrollVessel()
        vIndex = currentVesselIndex; % Update the vIndex variable
        % Highlight the selected vessel
        highlightVector(vIndex);
        % Update the plot
        updatePlot(vIndex);
        % Update the "Vessel #/#" text
        set(highlightedText, 'String', ['Vessel #: ' num2str(vIndex) '/' num2str(sizeS)], 'Visible', 'on');
    end

end
