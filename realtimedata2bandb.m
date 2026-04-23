clear; clc;

% --- Configuration ---
port = "COM10";          % <--- DOUBLE CHECK YOUR COM PORT
baudrate = 115200;
maxPoints = 200;        % Increased buffer for better settling time calculation
setPoint = 11;          % Must match the 'setP' in your ESP32 code
distData = zeros(1, maxPoints);
timeData = 1:maxPoints;

% Initialize Serial
s = serialport(port, baudrate);
configureTerminator(s, "LF");
flush(s);

% Prepare Figure
hFig = figure('Name', 'Ball and Beam Real-Time Analysis', 'Color', 'w', 'Position', [100, 100, 1000, 600]);
hAx = axes('Parent', hFig);
hold(hAx, 'on');
hLine = plot(hAx, distData, 'LineWidth', 1.5, 'Color', [0 0.447 0.741], 'DisplayName', 'Actual Position');
yline(setPoint, 'r--', 'LineWidth', 1.5, 'DisplayName', 'Target (Set Point)');
grid on;
ylim([0 40]); 
ylabel('Distance (cm)');
xlabel('Samples');
legend('Location', 'northeastoutside');

% Create text box for metrics
annotationBox = annotation('textbox', [0.75, 0.1, 0.2, 0.3], 'String', 'Calculating...', 'FitBoxToText', 'on', 'BackgroundColor', 'w');

disp('Streaming... Move the ball to see response changes.');

while ishandle(hLine)
    data = readline(s);
    numericData = str2double(data);
    
    if ~isnan(numericData)
        % Update Data
        distData = [distData(2:end), numericData];
        set(hLine, 'YData', distData);
        
        % --- PID Metrics Calculation (on current buffer) ---
        peakVal = max(distData);
        overshoot = max(0, ((peakVal - setPoint) / setPoint) * 100);
        
        % Rise Time (Time to go from 10% to 90% of setPoint)
        t10 = find(distData >= 0.1 * setPoint, 1);
        t90 = find(distData >= 0.9 * setPoint, 1);
        if ~isempty(t10) && ~isempty(t90)
            riseTime = t90 - t10;
        else
            riseTime = NaN;
        end
        
        % Settling Time (Time after which data stays within 5% of setPoint)
        tolerance = 0.05 * setPoint;
        stableIndices = find(abs(distData - setPoint) > tolerance);
        if ~isempty(stableIndices)
            settlingTime = maxPoints - stableIndices(end);
        else
            settlingTime = 0; % Already settled
        end

        % Update Display
        statsStr = { ...
            sprintf('Target: %d cm', setPoint), ...
            sprintf('Current: %.1f cm', numericData), ...
            sprintf('Overshoot: %.1f%%', overshoot), ...
            sprintf('Rise Time: %d samples', riseTime), ...
            sprintf('Settling: %d samples', settlingTime)};
        set(annotationBox, 'String', statsStr);
        
        drawnow limitrate;
    end
end

clear s;