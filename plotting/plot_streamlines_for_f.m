% Copyright © 2024 Martin Schonger
% This software is licensed under the GPLv3.


function [plt_handle, plt_data] = plot_streamlines_for_f(f, dim, plot_dim1, plot_dim2, limits, res, density)

arguments
    f;
    dim;
    plot_dim1;
    plot_dim2;
    limits;
    res = 200;
    density = 5;
end

[grid_x, grid_y, grid_z] = meshgrid(linspace(limits(1), limits(2), res), linspace(limits(3), limits(4), res), 0);

plt_data = feval(f, [grid_x(:), grid_y(:), repmat(grid_z(:), 1, dim-2)]');

plt_handle = streamslice(grid_x, grid_y, reshape(plt_data(plot_dim1, :), res, res), reshape(plt_data(plot_dim2, :), res, res), density, 'method', 'cubic');
set(plt_handle, 'linewidth', 0.5);
set(plt_handle, 'color', 'black');

end