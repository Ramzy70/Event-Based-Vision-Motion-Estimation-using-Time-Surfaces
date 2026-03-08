% M2 Computer Vision - Event-based Visual Flow (Benosman Method)
% Implements "Event-based Visual Flow" by Ryad Benosman et al.
% Works for: shapes_translation, shapes_rotation, outdoors_walking

clear; clc; close all;

%% 1. Load Data
disp('Loading events...');
if ~isfile('events.txt')
    error('events.txt not found! Run this script INSIDE a dataset folder.'); 
end

% Read matrix (automatically handles headers)
events = readmatrix('events.txt');

% Sensor Parameters (DAVIS 240C)
sensor_width = 240;  
sensor_height = 180;

%% 2. Initialize "Time Surface"
% The Time Surface T(x,y) stores the timestamp of the last event at each pixel.
% We initialize it with zeros (or a very small time).
sae = zeros(sensor_height, sensor_width); 

% Prepare Visualization Figure
figure('Name', 'Event-Based Optical Flow', 'Color', 'w');
axis([0 sensor_width 0 sensor_height]);
set(gca, 'YDir', 'reverse'); % Image coordinates (0,0 at top-left)
hold on;
xlabel('X (px)'); ylabel('Y (px)');
grid on;

%% 3. Processing Loop (Batch by Batch)
% We process events in small batches to visualize the flow evolution.
block_size = 5000; 
start_idx = 1;
total_events = size(events, 1);

disp('Starting Flow Visualization... (Press Ctrl+C to stop)');

while start_idx < total_events
    
    % Define the current batch
    end_idx = min(start_idx + block_size, total_events);
    batch = events(start_idx:end_idx, :);
    current_time = batch(end, 1);
    
    % --- A. Update the Time Surface (SAE) ---
    % For every event, update T(x,y) = t
    for k = 1:size(batch, 1)
        ev_t = batch(k, 1);
        ev_x = batch(k, 2) + 1; % Convert 0-based to 1-based indexing
        ev_y = batch(k, 3) + 1;
        
        % Boundary check
        if ev_x > 0 && ev_x <= sensor_width && ev_y > 0 && ev_y <= sensor_height
            sae(ev_y, ev_x) = ev_t;
        end
    end
    
    % --- B. Calculate Optical Flow Vectors ---
    % Theory: Velocity v = inverse of the gradient of the Time Surface.
    % v = 1 / ||grad(T)||
    
    x_quiver = []; y_quiver = [];
    u_quiver = []; v_quiver = [];
    
    % We only compute flow for a random subset of RECENT events to keep plot clean
    % (Computing for every single pixel is too slow for Matlab visualization)
    sample_indices = randperm(size(batch,1), 400); 
    
    for k = sample_indices
        t_ev = batch(k, 1);
        px = batch(k, 2) + 1;
        py = batch(k, 3) + 1;
        
        % Check boundaries for 3x3 neighborhood
        if px > 2 && px < sensor_width-1 && py > 2 && py < sensor_height-1
            
            % 1. Compute Spatial Gradients (dT/dx, dT/dy)
            % We use the Time Surface 'sae' we just updated.
            % Central difference: (T(x+1) - T(x-1)) / 2
            
            dT_dx = (sae(py, px+1) - sae(py, px-1)) / 2;
            dT_dy = (sae(py+1, px) - sae(py-1, px)) / 2;
            
            % 2. Check Validity
            % If gradient is tiny, it means the surface is flat (simultaneous events?)
            % or we are looking at old data.
            mag_sq = dT_dx^2 + dT_dy^2;
            
            if mag_sq > 1e-12 
                % 3. Calculate Velocity Vector
                % Formula: v = grad(T) / ||grad(T)||^2
                % Note: This points perpendicular to the timestamp contours.
                vx = dT_dx / mag_sq;
                vy = dT_dy / mag_sq;
                
                % Filter insane speeds (noise)
                if norm([vx, vy]) < 5000 
                    x_quiver(end+1) = px;
                    y_quiver(end+1) = py;
                    u_quiver(end+1) = vx;
                    v_quiver(end+1) = vy;
                end
            end
        end
    end
    
    % --- C. Display Frame ---
    cla; % Clear previous frame
    
    % 1. Draw Events (Black dots background)
    plot(batch(:,2)+1, batch(:,3)+1, '.', 'Color', [0.8 0.8 0.8], 'MarkerSize', 1);
    
    % 2. Draw Flow Vectors (Red Arrows)
    % Scaling factor 0.1 makes the arrows visible but not huge
    quiver(x_quiver, y_quiver, u_quiver, v_quiver, 0.5, 'r', 'LineWidth', 1.5, 'MaxHeadSize', 0.5);
    
    title(sprintf('Frame: %d | Time: %.3f s', start_idx, current_time));
    drawnow limitrate; % Update plot efficiently
    
    % Advance to next batch
    start_idx = start_idx + block_size;
end