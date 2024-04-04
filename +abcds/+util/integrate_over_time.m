% Copyright © 2024 Martin Schonger
% This software is licensed under the GPLv3.


function [pos, vel, tvec] = integrate_over_time(f, x0, target, norm_limit)

arguments
    f;
    x0 double;
    target double = zeros(size(x0));
    norm_limit double = 1e3;
end

max_time = 120;
rel_tol = 1e-12;
abs_tol = 1e-12;

integration_opts = odeset('events', @(T, Y) abcds.util.is_at_point_or_diverged(target, norm_limit, T, Y), 'reltol', rel_tol, 'abstol', abs_tol); % stop integrating at some boundary

dim = size(x0, 1);

[t, y] = ode45(@(t, x) f(x), [0, max_time], x0, integration_opts);
tvec = t';
pos = y';

xdiff = pos(:, 2:end) - pos(:, 1:(end -1));
tdiff = tvec(:, 2:end) - tvec(:, 1:(end -1));
tdiff_extended = repmat(tdiff, dim, 1);
vel = xdiff ./ tdiff_extended;
vel = [vel, zeros(dim, 1)];

end