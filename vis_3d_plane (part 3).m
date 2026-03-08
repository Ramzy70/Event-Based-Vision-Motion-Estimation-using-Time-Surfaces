% M2 Computer Vision - 3D Space-Time Volume & RANSAC
% Sequence: shapes_translation
% Instructions: Run this inside the 'shapes_translation' folder.

clear; clc; close all;

%% 1. Load Data
disp('Loading events...');
if ~isfile('events.txt'), error('events.txt not found!'); end

events = readmatrix('events.txt'); 

%% 2. Select a Subset (Spatial Crop & SCALING)
% We select a time slice and a specific region (ROI) to isolate ONE edge.
% If we select the whole image, the plane tries to fit multiple objects and fails.

% A. Time Slice (Select a window where motion occurs)
start_idx = 200000; 
subset = events(start_idx : start_idx + 15000, :);

% B. Spatial ROI (Targeting the Rectangular Bar from your data)
% We focus on the top edge of the rectangle to get a clean plane.
% Approximate coordinates based on your screenshot:
roi_idx = subset(:,2) > 80  & subset(:,2) < 140 & ... 
          subset(:,3) > 130 & subset(:,3) < 150;
      
subset = subset(roi_idx, :); 

% Safety check
if size(subset, 1) < 50
    error('ROI is empty! The shape might have moved out of these coords. Adjust X/Y limits.');
end

% C. SCALING (Crucial for RANSAC)
% Time is in seconds (0.001s range), Space is in pixels (100s range).
% We must scale time up so RANSAC treats it as a 3D volume, not a flat sheet.
t_raw = subset(:,1);
t_raw = t_raw - min(t_raw); % Start at 0

time_scale = 1000;          % Scale factor: 1s becomes 1000 units
t = t_raw * time_scale;     % Scaled time for calculation

x = subset(:,2);
y = subset(:,3);
p = subset(:,4); 

fprintf('Subset selected: %d events. Time scaled by factor %d.\n', length(t), time_scale);

%% 3. RANSAC Plane Fitting
% Model: ax + by + ct + d = 0
points = [x, y, t]; 
numIterations = 5000;
distanceThreshold = 1.0; % Threshold in scaled units (approx 1ms)
bestInliers = [];
bestPlane = [0 0 0 0]; 

disp('Running RANSAC...');
for iter = 1:numIterations
    if size(points, 1) < 3, break; end
    
    % Sample 3 points
    idx = randperm(size(points,1), 3);
    pts = points(idx, :);
    
    % Compute Normal
    v1 = pts(2,:) - pts(1,:);
    v2 = pts(3,:) - pts(1,:);
    normal = cross(v1, v2);
    if norm(normal) < eps, continue; end 
    normal = normal / norm(normal);
    
    d = -dot(normal, pts(1,:));
    
    % Count Inliers
    dists = abs(points * normal' + d);
    currentInliers = find(dists < distanceThreshold);
    
    if length(currentInliers) > length(bestInliers)
        bestInliers = currentInliers;
        bestPlane = [normal, d];
    end
end
fprintf('RANSAC finished. Inliers: %d\n', length(bestInliers));

%% 4. Plot 3D Volume
fig = figure('Name', '3D Space-Time Volume', 'Color', 'w');

% Plot Points
scatter3(x(p==1), y(p==1), t(p==1), 12, 'r', 'filled'); hold on;
scatter3(x(p==0), y(p==0), t(p==0), 12, 'b', 'filled');

% Plot Fitted Plane
if ~isempty(bestInliers)
    [xx, yy] = meshgrid(min(x):2:max(x), min(y):2:max(y));
    nx = bestPlane(1); ny = bestPlane(2); nt = bestPlane(3); d_plane = bestPlane(4);
    
    if abs(nt) > 1e-5
        zz = (-d_plane - nx.*xx - ny.*yy) / nt;
        surf(xx, yy, zz, 'FaceAlpha', 0.5, 'EdgeColor', 'none', 'FaceColor', 'g');
    end
end

% Formatting
xlabel('X (pixels)'); 
ylabel('Y (pixels)'); 
zlabel('Scaled Time');
title('3D Event Volume & Motion Plane');
grid on; axis vis3d;
legend('Positive', 'Negative', 'Motion Plane');

% Interaction
rotate3d on; 
view(45, 30);

%% 5. Velocity Calculation (Un-scaling)
% The normal vector n = [nx, ny, nt] is in the SCALED space.
% Velocity v = -nx / nt  (pixels per SCALED time unit)

vx_scaled = -nx / nt; 
vy_scaled = -ny / nt;

% Convert to Real Velocity (pixels/second)
vx_real = vx_scaled * time_scale;
vy_real = vy_scaled * time_scale;

fprintf('\n--- Results ---\n');
fprintf('Plane Normal: [%.3f, %.3f, %.3f]\n', nx, ny, nt);
fprintf('Estimated Velocity: vx = %.2f px/s, vy = %.2f px/s\n', vx_real, vy_real);