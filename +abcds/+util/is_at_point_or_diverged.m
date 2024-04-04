% Copyright © 2024 Martin Schonger
% This software is licensed under the GPLv3.


function [value, isterminal, direction] = is_at_point_or_diverged(point, norm_limit, T, Y)
    epsilon = 1e-4;
    value      = (all((Y-point) > -epsilon) && all((Y-point) < epsilon)) || (norm(Y) > norm_limit);
    isterminal = 1;  % Stop the integration
    direction  = 0;
end