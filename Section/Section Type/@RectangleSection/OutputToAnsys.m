function output_str = OutputToAnsys(obj,sec_num)
    output_str = sprintf(['\n' ...
                         'sectype,%d,Beam,Rect \n' ...
                         'secoffset,cent \n' ...
                         'secdata,%E,%E \n'],sec_num, ...
                         obj.Width,obj.Height);
end