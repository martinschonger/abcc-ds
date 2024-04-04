% Copyright © 2024 Martin Schonger
% This software is licensed under the GPLv3.


function res = ellipse_axis_to_eq(center_position, axes_length, orientation)
% convert ellipse in axis form to equation form

a = axes_length(1) / 2;
b = axes_length(2) / 2; % axes lengths 
theta = orientation; % rotation angle
x0 = center_position(1);
y0 = center_position(2); % center
res = @(x) 1 - ((((x(1, :)-x0).*cos(theta) + (x(2, :)-y0).*sin(theta)).^2)./(a.^2) + (((x(1, :)-x0).*sin(theta) - (x(2, :)-y0).*cos(theta)).^2)./b.^2); % ellipse equation

end