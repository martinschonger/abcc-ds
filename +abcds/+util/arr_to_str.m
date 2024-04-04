% Copyright © 2024 Martin Schonger
% This software is licensed under the GPLv3.


function res = arr_to_str(arr)

res = sprintf('%s,', string(arr));
res = res(1:end-1); % strip final comma

end