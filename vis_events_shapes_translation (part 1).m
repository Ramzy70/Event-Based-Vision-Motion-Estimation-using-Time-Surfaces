% Sequence: shapes_translation

% 1. Parameters
% Time window around the frame timestamp (in seconds)
% Try changing this to 5ms or 50ms to answer Q3
delta_t = 0.02; 

% Display options
step_size = 1; % Process every Nth frame to increase to speed up visualization

% 2. Load Data
disp('Loading data... (this may take a moment for large event files)');

% Load Events: Format is [timestamp x y polarity] 
% events.txt is 380MB, so using 'load' will be efficient enough.
events = load('events.txt'); 

% Load Image References: Format is [timestamp filename] 
% We use readtable because the second column is text.
opts = detectImportOptions('images.txt', 'FileType', 'text');
opts.VariableNamesLine = 0; % No header in file
opts.DataLines = 1;         % Data starts at line 1
imagesTable = readtable('images.txt', opts);

% Rename columns for clarity (Var1 is timestamp and Var2 is path)
imagesTable.Properties.VariableNames = {'timestamp', 'rel_path'};

disp(['Data loaded. Total events: ', num2str(size(events,1))]);
disp(['Total frames: ', num2str(height(imagesTable))]);

% 3. Visualization Loop 
figure('Name', 'Event Overlay', 'NumberTitle', 'off');
set(gcf, 'Position', [100, 100, 800, 600]);

% Prepare axes
ax = gca;

for i = 1:step_size:height(imagesTable)
    
    % A. Get current frame info
    t_frame = imagesTable.timestamp(i);
    
    % The file path in images.txt is "images/frame_...png"
    img_filename = fullfile(pwd, imagesTable.rel_path{i});
    
    % B. Find events within the temporal window [t - dt/2, t + dt/2]
    % We search for indices where timestamp matches criteria
    t_min = t_frame - (delta_t / 2);
    t_max = t_frame + (delta_t / 2);
    
    % Logical indexing (fastest method for this size)
    idx_window = events(:,1) >= t_min & events(:,1) <= t_max;
    current_events = events(idx_window, :);
    
    % C. Separate by Polarity 
    % Polarity is usually 1 (positive) or 0 (negative)
    idx_pos = current_events(:,4) == 1;
    idx_neg = current_events(:,4) == 0; 
    
    % D. Display
    try
        img = imread(img_filename);
        imshow(img, 'Parent', ax); 
        hold(ax, 'on');
        
        % Plot events: x is col 2, y is col 3
        % Positive in Red and Negative in Blue 
        if ~isempty(current_events)
            plot(ax, current_events(idx_pos, 2), current_events(idx_pos, 3), '.r', 'MarkerSize', 2);
            plot(ax, current_events(idx_neg, 2), current_events(idx_neg, 3), '.b', 'MarkerSize', 2);
        end
        
        hold(ax, 'off');
        title(ax, sprintf('Frame %d | Time: %.3fs | Events: %d', ...
            i, t_frame, sum(idx_window)));
        
        drawnow; % Force update of the figure
        
    catch ME
        warning('Could not read image: %s', img_filename);
    end
end