# ABCC-DS: obstacle Avoidance with Barrier-Certified Compositional polynomial Dynamical Systems

Accompanying code for the paper **Learning Stable and Barrier-Certified Systems for Robotic Tasks: A Compositional Approach** by
Ali Aminzadeh<sup>1,&#42;</sup>,
Martin Schonger<sup>2,&#42;</sup>,
Hugo T. M. Kussaba<sup>2</sup>,
Ahmed Abdelrahman<sup>2</sup>,
Abdalla Swikir<sup>2</sup>, 
Abolfazl Lavaei<sup>1</sup>,
and Sami Haddadin<sup>2</sup>, currently under review.

<sup>1</sup>School of Computing, Newcastle University, UK.\
<sup>2</sup>Munich Institute of Robotics and Machine Intelligence (MIRMI), Technical University of Munich (TUM), Germany. Abdalla Swikir is also with Omar Al-Mukhtar University (OMU), Albaida, Libya.\
<sup>&#42;</sup>Shared first authorship.

### Setup
Install MATLAB (tested with R2023a).

Install the MathWorks toolboxes
[Robotics System Toolbox](https://www.mathworks.com/products/robotics.html),
[Signal Processing Toolbox](https://www.mathworks.com/products/signal.html), and
[Symbolic Math Toolbox](https://www.mathworks.com/products/symbolic.html).

Install the third party tools
[YALMIP](https://yalmip.github.io/) (version 20230622; changed sdisplay precision in PATH/TO/yalmip/extras/sdisplay.m LOCs 311, 313, 317, and 319 from 12 to 128),
[PENBMI](http://www.penopt.com/penbmi.html) (version 2.1), and
[GUROBI](https://www.gurobi.com/) (version 10.0.2 build v10.0.2rc0 (win64)).

> **Note**
> Make sure that the non-toolbox paths are before/on top of the toolbox paths.

### Usage
Open the `abcc-ds` folder in MATLAB.

Configure the desired experiments in `main.m` and run this script.

Check the `output` folder for results and logs.

(Optionally, recreate the plots from the paper with `plotting/generate_plots_iros.m`, and the animations from the video with `plotting/generate_plots_video_iros.m`.)

### Contact
martin.schonger@tum.de

This software was created as part of Martin Schonger's master's thesis in Computer Science at the Technical University of Munich's (TUM) School of Computation, Information and Technology (CIT).

Copyright © 2024 Martin Schonger  
This software is licensed under the GPLv3.
