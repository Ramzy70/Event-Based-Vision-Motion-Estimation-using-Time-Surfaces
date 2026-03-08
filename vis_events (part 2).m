% Works for the three datasets shapes_translation, shapes_rotation, shapes_6dof

% 1. Setup & Parameters
% Get current folder name for the plot title
[~, folderName, ~] = fileparts(pwd);
fprintf('Processing Dataset: %s\n', folderName);

% Temporal window (delta_t)
% Q3: Adjust this to see impact (e.g., 0.01 for 10ms)
delta_t = 0.01; 

% 2. Load Data
if ~isfile('events.txt') || ~isfile('images.txt')
    error('Error: events.txt or images.txt not found in current folder!');
end

disp('Loading events... (This might take a few seconds)');
events = load('events.txt'); % columns: [timestamp x y polarity]

disp('Loading image timestamps...');
opts = detectImportOptions('images.txt', 'FileType', 'text');
opts.VariableNamesLine = 0; 
opts.DataLines = 1;         
imagesTable = readtable('images.txt', opts);
imagesTable.Properties.VariableNames = {'timestamp', 'rel_path'};

disp(['Loaded ' num2str(size(events,1)) ' events and ' num2str(height(imagesTable)) ' frames.']);

% 3. Visualization Loop
f = figure('Name', ['Events: ' folderName], 'NumberTitle', 'off');
set(gcf, 'Position', [100, 100, 900, 700]);
ax = gca;

% Loop through images
% step_size: Skip frames to play faster (e.g., 2 or 5)
step_size = 2; 

for i = 1:step_size:height(imagesTable)
    if ~ishandle(f), break; end % Stop if window closed
    
    % Get timestamp and file
    t_frame = imagesTable.timestamp(i);
    img_path = fullfile(pwd, imagesTable.rel_path{i});
    
    % Define Window
    t_min = t_frame - (delta_t / 2);
    t_max = t_frame + (delta_t / 2);
    
    % Filter Events
    % Note: Assuming events are sorted by time (usually true), 
    % finding indices is fast.
    idx = events(:,1) >= t_min & events(:,1) <= t_max;
    sub_events = events(idx, :);
    
    % Read and Show Image
    try
        img = imread(img_path);
        imshow(img, 'Parent', ax); hold(ax, 'on');
        
        % Plot Events (Polarity: 1=Red, 0=Blue)
        if ~isempty(sub_events)
            pos = sub_events(:,4) == 1;
            neg = sub_events(:,4) == 0;
            
            plot(ax, sub_events(pos, 2), sub_events(pos, 3), '.r', 'MarkerSize', 2);
            plot(ax, sub_events(neg, 2), sub_events(neg, 3), '.b', 'MarkerSize', 2);
        end
        
        hold(ax, 'off');
        title(ax, sprintf('%s | Frame %d | Event Count: %d', folderName, i, sum(idx)));
        drawnow;
        
    catch
        warning('Image not found: %s', img_path);
    end
end