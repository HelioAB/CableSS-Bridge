function output_str = OutputToAnsys(obj,sec_num)
    output_str = sprintf(['\n' ...
                         'sectype,%d,Beam,I \n' ...
                         'secoffset,cent \n' ...
                         'secdata,%E,%E,%E,%E,%E,%E \n'],sec_num, ...
                         obj.Width_TopFlange,obj.Width_BottomFlangem,obj.Depth,obj.Thickness_TopFlange,bj.Thickness_BottomFlange,obj.Thickness_Web);
end