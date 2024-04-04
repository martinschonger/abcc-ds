% Copyright © 2024 Martin Schonger
% This software is licensed under the GPLv3.


function ax = plot_cframe(position, euler_angles, args)

arguments
    position
    euler_angles
    args.ax_in
    args.labels = false
end

rot_mat = eul2rotm(euler_angles', 'ZXY');

transform_matrix = [[rot_mat; 0,0,0], [position; 1]];
triad('matrix', transform_matrix, 'linewidth', 3, 'scale', 0.18);

end