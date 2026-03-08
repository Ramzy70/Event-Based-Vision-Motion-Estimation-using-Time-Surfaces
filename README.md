# Event-Based Vision: Motion Estimation using Time Surfaces

This repository explores the fundamentals of **Event-Based Cameras** (Neuromorphic sensors). Unlike traditional cameras that capture frames at fixed intervals, event cameras only report per-pixel intensity changes (events) asynchronously. This project implements motion estimation based on the temporal distribution of these events.

## 1. Core Concepts
### Asynchronous Change Detection
Event cameras trigger an event $e(x, y, t, p)$ only when the log-intensity change at a pixel exceeds a threshold: $\Delta \ln(I) > C$. 
* **Red/Blue Dots:** Represent positive and negative polarity (intensity increase vs. decrease).
* **Sparse Data:** Events only occur at moving edges; uniform regions (backgrounds) generate no data, significantly reducing bandwidth and power consumption.

### The Impact of Temporal Windows ($\Delta t$)
We analyzed how the accumulation time window affects visual representation:
* **Small Window (e.g., 0.001s):** Leads to sparse, "broken" edges due to insufficient data.
* **Large Window (e.g., 0.1s):** Causes "motion blur" as events from past and current positions overlap, sacrificing the sensor's high temporal resolution.

## 2. Methodology: Time Surfaces & SAE
To estimate velocity, we utilize the **Surface of Active Events (SAE)**, also known as a **Time Surface**. This is a 2D map where each pixel $(x, y)$ stores the timestamp $t$ of the most recent event.



### Velocity Calculation
The motion of an edge across the sensor creates a continuous slope in the time surface. The velocity vector $\mathbf{v}$ is computed locally as the inverse of the spatial gradient of this surface:

$$\mathbf{v} = \frac{\nabla T}{\|\nabla T\|^2}$$

## 3. Experimental Results
The algorithm was tested on several sequences using MATLAB:
* **Shapes Translation:** Successfully generated flow vectors (red arrows) along the contours of geometric shapes. 
* **Aperture Problem:** While individual pixels compute "normal flow" (perpendicular to the edge), aggregating flow across different edge orientations (e.g., sides of a triangle) reveals the true global motion.
* **Rotation & 6-DOF:** Analyzed complex ego-motion where flow vectors act tangentially (vortex-like) or exhibit expansion/translation based on camera movement.

---

## Technical Analysis
* **Strengths:** High dynamic range and microsecond-level temporal resolution.
* **Limitations:** The gradient-based method is sensitive to noise in outdoor sequences and requires a sufficient density of events to provide a reliable surface for differentiation.

## Usage
Run the following scripts in MATLAB to visualize the results:
* `vis_events_shapes_translation.m`: Visualizes the basic shape motion and flow estimation.
* `main_scripts`: (Add specific script names here) for rotation and outdoor sequences.
