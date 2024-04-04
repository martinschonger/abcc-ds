% Copyright © 2024 Martin Schonger
% This software is licensed under the GPLv3.


function figure_to_file2(fig, filepath, args)

arguments
    fig
    filepath
    args.format = '-dpdf'
    args.res = 600 % dpi
end

% save figure
switch args.format
    case '-dpdf'
        print(fig, filepath, '-vector', '-dpdf');
    case '-dpng'
        print(fig, filepath, '-dpng', sprintf('-r%d', args.res));
end

end