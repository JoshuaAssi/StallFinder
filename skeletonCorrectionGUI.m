function [S_new, stallogram_new, stallPrcs_new, volIntPrc_new] = skeletonCorrectionGUI(S, DD, stallogram, stallPrcs, volIntPrc)
    f = figure('Units', 'normalized', 'Position', [0.1, 0.1, 0.8, 0.8]);
    mainPanel = uipanel('Parent', f, 'Units', 'normalized', 'Position', [0.2, 0, 0.8, 1]);
    ax = axes('Parent', mainPanel);
    imagesc(ax, squeeze(max(DD)))
    axis image
    colormap gray
    set(gca, 'XTick', [], 'YTick', [])
    hold on
    title('Skeleton Correction')

    controlPanel = uipanel('Parent', f, 'Title', 'Controls', 'Units', 'normalized', 'Position', [0, 0, 0.2, 1]);
    highlighted = [];
    plotHandles = gobjects(1, length(S));

    for i = 1:length(S)
        color = rand(1, 3);
        plotHandles(i) = plot(ax, S{i}(:, 3), S{i}(:, 2), 'Color', color, 'LineWidth', 3);
    end

    vesselLabel = uicontrol('Parent', controlPanel, 'Style', 'text', 'Units', 'normalized', 'Position', [0.1, 0.8, 0.8, 0.1], 'String', '', 'FontSize', 18, 'HorizontalAlignment', 'left');

    uicontrol('Parent', controlPanel, 'Style', 'pushbutton', 'String', 'Delete Selected Vessel', 'Units', 'normalized', 'Position', [0.1, 0.6, 0.8, 0.1], 'FontSize', 10, 'Callback', @deleteHighlighted);
    uicontrol('Parent', controlPanel, 'Style', 'pushbutton', 'String', 'Add Vessel', 'Units', 'normalized', 'Position', [0.1, 0.4, 0.8, 0.1], 'FontSize', 10, 'Callback', @addVessel);
    uicontrol('Parent', controlPanel, 'Style', 'pushbutton', 'String', 'Done editing the skeleton!', 'Units', 'normalized', 'Position', [0.1, 0.2, 0.8, 0.1], 'FontSize', 10, 'Callback', @quitCallback);

    set(f, 'WindowButtonDownFcn', @highlightVector);
    S_new = S;
    stallogram_new = stallogram;
    stallPrcs_new = stallPrcs;
    volIntPrc_new = volIntPrc;

    function highlightVector(~, ~)
        clickPoint = get(ax, 'CurrentPoint');
        clickX = clickPoint(1, 1);
        clickY = clickPoint(1, 2);

        minDist = inf;
        closestIdx = -1;

        for i = 1:length(S_new)
            dist = min(sum((S_new{i}(:, [3, 2]) - [clickX, clickY]).^2, 2));
            if dist < minDist
                minDist = dist;
                closestIdx = i;
            end
        end

        if ~isempty(highlighted)
            set(plotHandles(highlighted), 'LineWidth', 3);
        end

        if closestIdx > 0
            highlighted = closestIdx;
            set(plotHandles(highlighted), 'LineWidth', 6);
            set(vesselLabel, 'String', sprintf('Vessel #: %d', highlighted));
        else
            set(vesselLabel, 'String', '');
        end
    end

    function deleteHighlighted(~, ~)
        if ~isempty(highlighted)
            delete(plotHandles(highlighted));
            S_new(highlighted) = [];
            stallogram_new(highlighted, :) = [];
            stallPrcs_new(highlighted, :) = [];
            volIntPrc_new(highlighted, :, :) = [];
            plotHandles(highlighted) = [];
            plotHandles = plotHandles(~arrayfun(@isempty, plotHandles));
            highlighted = [];
            set(vesselLabel, 'String', '');
        end
    end

    function addVessel(~, ~)
        set(f, 'Pointer', 'crosshair');
        vesselLabel.String = 'Draw the vessel!';
        h = drawfreehand(ax, 'Color', rand(1, 3), 'LineWidth', 3);
        if isempty(h.Position)
            set(f, 'Pointer', 'arrow');
            vesselLabel.String = '';
            return;
        end
        lineCoords = h.Position;
        y = lineCoords(:, 1);
        x = lineCoords(:, 2);
        interpPoints = 500;
        t = linspace(0, 1, length(x));
        tInterp = linspace(0, 1, interpPoints);
        xInterp = interp1(t, x, tInterp, 'linear');
        yInterp = interp1(t, y, tInterp, 'linear');
        s = zeros(length(xInterp), 3);
        s(:, 1) = round(size(DD, 1) / 2);
        s(:, 2) = xInterp;
        s(:, 3) = yInterp;
        S_new{end+1} = s;
        stallogram_new(end+1, :) = 0;
        stallPrcs_new(end+1, :) = 0;
        volIntPrc_new(end+1, :, :) = repmat(median(volIntPrc, [1 3]), 1, 1, size(volIntPrc, 3));
        plotHandles(end+1) = plot(ax, yInterp, xInterp, 'LineWidth', 3, 'Color', rand(1, 3));
        delete(h);
        set(f, 'Pointer', 'arrow');
        vesselLabel.String = '';
    end

    function quitCallback(~, ~)
        close(f);
    end

    waitfor(f);
end